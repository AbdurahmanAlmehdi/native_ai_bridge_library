import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/models/tool_call.dart';

void main() {
  group('ToolCall', () {
    test('should create ToolCall with required properties', () {
      final toolCall = ToolCall(
        toolName: 'get_weather',
        arguments: {'city': 'Boston'},
        sessionId: 'session_123',
      );

      expect(toolCall.toolName, 'get_weather');
      expect(toolCall.arguments, {'city': 'Boston'});
      expect(toolCall.sessionId, 'session_123');
    });

    test('should create ToolCall with multiple arguments', () {
      final toolCall = ToolCall(
        toolName: 'get_weather',
        arguments: {
          'city': 'Boston',
          'units': 'metric',
          'language': 'en',
        },
        sessionId: 'session_123',
      );

      expect(toolCall.arguments.length, 3);
      expect(toolCall.arguments['city'], 'Boston');
      expect(toolCall.arguments['units'], 'metric');
      expect(toolCall.arguments['language'], 'en');
    });

    test('should create ToolCall with empty arguments', () {
      final toolCall = ToolCall(
        toolName: 'get_weather',
        arguments: {},
        sessionId: 'session_123',
      );

      expect(toolCall.arguments, isEmpty);
    });

    test('should handle various argument types', () {
      final toolCall = ToolCall(
        toolName: 'test_tool',
        arguments: {
          'stringParam': 'test',
          'intParam': 42,
          'doubleParam': 3.14,
          'boolParam': true,
          'listParam': ['a', 'b', 'c'],
          'mapParam': {'key': 'value'},
        },
        sessionId: 'session_123',
      );

      expect(toolCall.arguments['stringParam'], 'test');
      expect(toolCall.arguments['intParam'], 42);
      expect(toolCall.arguments['doubleParam'], 3.14);
      expect(toolCall.arguments['boolParam'], true);
      expect(toolCall.arguments['listParam'], ['a', 'b', 'c']);
      expect(toolCall.arguments['mapParam'], {'key': 'value'});
    });

    test('should convert to JSON correctly', () {
      final toolCall = ToolCall(
        toolName: 'get_weather',
        arguments: {'city': 'Boston', 'units': 'metric'},
        sessionId: 'session_123',
      );

      final json = toolCall.toJson();

      expect(json['toolName'], 'get_weather');
      expect(json['arguments'], {'city': 'Boston', 'units': 'metric'});
      expect(json['sessionId'], 'session_123');
    });

    test('should convert from JSON correctly', () {
      final json = {
        'toolName': 'get_weather',
        'arguments': {'city': 'Boston', 'units': 'metric'},
        'sessionId': 'session_123',
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.toolName, 'get_weather');
      expect(toolCall.arguments, {'city': 'Boston', 'units': 'metric'});
      expect(toolCall.sessionId, 'session_123');
    });

    test('should handle JSON with Map arguments', () {
      final json = {
        'toolName': 'get_weather',
        'arguments': {'city': 'Boston'},
        'sessionId': 'session_123',
      };

      final toolCall = ToolCall.fromJson(json);

      expect(toolCall.arguments, isA<Map<String, dynamic>>());
      expect(toolCall.arguments['city'], 'Boston');
    });

    test('should round-trip through JSON correctly', () {
      final original = ToolCall(
        toolName: 'get_weather',
        arguments: {
          'city': 'Boston',
          'units': 'metric',
          'count': 5,
        },
        sessionId: 'session_123',
      );

      final json = original.toJson();
      final restored = ToolCall.fromJson(json);

      expect(restored.toolName, original.toolName);
      expect(restored.arguments, original.arguments);
      expect(restored.sessionId, original.sessionId);
    });

    test('toString should return formatted string', () {
      final toolCall = ToolCall(
        toolName: 'get_weather',
        arguments: {'city': 'Boston'},
        sessionId: 'session_123',
      );

      final string = toolCall.toString();

      expect(string, contains('get_weather'));
      expect(string, contains('city'));
      expect(string, contains('Boston'));
      expect(string, contains('session_123'));
    });
  });
}
