import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/services/tool_handler_manager.dart';
import 'package:native_ai_bridge/models/tool.dart';
import 'package:native_ai_bridge/models/tool_call.dart';
import 'package:native_ai_bridge/exception/apple_foundation_flutter_exception.dart';

void main() {
  group('ToolHandlerManager', () {
    late ToolHandlerManager manager;

    setUp(() {
      manager = ToolHandlerManager();
    });

    group('registerSession', () {
      test('should register a session with tools', () {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'Test',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async => 'result',
          },
        );

        expect(manager.activeSessionCount, 1);
        expect(manager.isSessionActive('session_1'), true);
      });

      test('should register multiple tools for a session', () {
        final tool1 = BaseTool(
          name: 'tool1',
          description: 'Tool 1',
          arguments: [],
        );
        final tool2 = BaseTool(
          name: 'tool2',
          description: 'Tool 2',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool1: (call) async => 'result1',
            tool2: (call) async => 'result2',
          },
        );

        final toolNames = manager.getToolNames('session_1');
        expect(toolNames, contains('tool1'));
        expect(toolNames, contains('tool2'));
      });

      test('should throw error when registering duplicate session', () {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'Test',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {tool: (call) async => 'result'},
        );

        expect(
          () => manager.registerSession(
            sessionId: 'session_1',
            toolHandlers: {tool: (call) async => 'result'},
          ),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'SESSION_ALREADY_EXISTS',
          )),
        );
      });

      test('should throw error when registering tools with duplicate names',
          () {
        final tool1 = BaseTool(
          name: 'test_tool',
          description: 'Test 1',
          arguments: [],
        );
        final tool2 = BaseTool(
          name: 'test_tool',
          description: 'Test 2',
          arguments: [],
        );

        expect(
          () => manager.registerSession(
            sessionId: 'session_1',
            toolHandlers: {
              tool1: (call) async => 'result1',
              tool2: (call) async => 'result2',
            },
          ),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'DUPLICATE_TOOL_NAMES',
          )),
        );
      });
    });

    group('handleToolCall', () {
      test('should execute tool handler successfully', () async {
        final tool = BaseTool(
          name: 'get_weather',
          description: 'Get weather',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async => 'Sunny, 22°C',
          },
        );

        final call = ToolCall(
          toolName: 'get_weather',
          arguments: {'city': 'Boston'},
          sessionId: 'session_1',
        );

        final result = await manager.handleToolCall(call);
        expect(result, 'Sunny, 22°C');
      });

      test('should pass arguments to handler', () async {
        final tool = BaseTool(
          name: 'get_weather',
          description: 'Get weather',
          arguments: [],
        );

        String? receivedCity;
        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async {
              receivedCity = call.arguments['city'];
              return 'Weather data';
            },
          },
        );

        final call = ToolCall(
          toolName: 'get_weather',
          arguments: {'city': 'Boston'},
          sessionId: 'session_1',
        );

        await manager.handleToolCall(call);
        expect(receivedCity, 'Boston');
      });

      test('should throw error when session not found', () async {
        final call = ToolCall(
          toolName: 'get_weather',
          arguments: {},
          sessionId: 'non_existent',
        );

        expect(
          () => manager.handleToolCall(call),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'SESSION_NOT_FOUND',
          )),
        );
      });

      test('should throw error when tool handler not found', () async {
        final tool = BaseTool(
          name: 'tool1',
          description: 'Tool 1',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async => 'result',
          },
        );

        final call = ToolCall(
          toolName: 'non_existent_tool',
          arguments: {},
          sessionId: 'session_1',
        );

        expect(
          () => manager.handleToolCall(call),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'TOOL_HANDLER_NOT_FOUND',
          )),
        );
      });

      test('should throw error when session is inactive', () async {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'Test',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {tool: (call) async => 'result'},
        );

        manager.closeSession('session_1');

        final call = ToolCall(
          toolName: 'test_tool',
          arguments: {},
          sessionId: 'session_1',
        );

        expect(
          () => manager.handleToolCall(call),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'SESSION_NOT_FOUND',
          )),
        );
      });

      test('should handle timeout', () async {
        final tool = BaseTool(
          name: 'slow_tool',
          description: 'Slow tool',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async {
              await Future.delayed(Duration(seconds: 2));
              return 'result';
            },
          },
          timeout: Duration(milliseconds: 100),
        );

        final call = ToolCall(
          toolName: 'slow_tool',
          arguments: {},
          sessionId: 'session_1',
        );

        expect(
          () => manager.handleToolCall(call),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'TOOL_HANDLER_TIMEOUT',
          )),
        );
      });

      test('should wrap handler exceptions', () async {
        final tool = BaseTool(
          name: 'error_tool',
          description: 'Error tool',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async {
              throw Exception('Handler error');
            },
          },
        );

        final call = ToolCall(
          toolName: 'error_tool',
          arguments: {},
          sessionId: 'session_1',
        );

        expect(
          () => manager.handleToolCall(call),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'TOOL_EXECUTION_FAILED',
          )),
        );
      });

      test('should not wrap AppleFoundationException', () async {
        final tool = BaseTool(
          name: 'error_tool',
          description: 'Error tool',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool: (call) async {
              throw AppleFoundationException(
                'Custom error',
                code: 'CUSTOM_ERROR',
              );
            },
          },
        );

        final call = ToolCall(
          toolName: 'error_tool',
          arguments: {},
          sessionId: 'session_1',
        );

        expect(
          () => manager.handleToolCall(call),
          throwsA(isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'CUSTOM_ERROR',
          )),
        );
      });
    });

    group('closeSession', () {
      test('should close a session', () {
        final tool = BaseTool(
          name: 'test_tool',
          description: 'Test',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {tool: (call) async => 'result'},
        );

        expect(manager.isSessionActive('session_1'), true);
        expect(manager.activeSessionCount, 1);

        manager.closeSession('session_1');

        expect(manager.isSessionActive('session_1'), false);
        expect(manager.activeSessionCount, 0);
      });

      test('should handle closing non-existent session gracefully', () {
        manager.closeSession('non_existent');
        expect(manager.activeSessionCount, 0);
      });
    });

    group('getToolNames', () {
      test('should return tool names for a session', () {
        final tool1 = BaseTool(
          name: 'tool1',
          description: 'Tool 1',
          arguments: [],
        );
        final tool2 = BaseTool(
          name: 'tool2',
          description: 'Tool 2',
          arguments: [],
        );

        manager.registerSession(
          sessionId: 'session_1',
          toolHandlers: {
            tool1: (call) async => 'result1',
            tool2: (call) async => 'result2',
          },
        );

        final toolNames = manager.getToolNames('session_1');

        expect(toolNames, isNotNull);
        expect(toolNames!.length, 2);
        expect(toolNames, contains('tool1'));
        expect(toolNames, contains('tool2'));
      });

      test('should return null for non-existent session', () {
        final toolNames = manager.getToolNames('non_existent');
        expect(toolNames, isNull);
      });
    });
  });
}
