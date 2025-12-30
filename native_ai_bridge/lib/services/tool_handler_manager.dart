import 'dart:async';
import 'dart:developer' as developer;

import '../exception/apple_foundation_flutter_exception.dart';
import '../models/tool.dart';
import '../models/tool_call.dart';

typedef ToolCallHandler = Future<dynamic> Function(ToolCall toolCall);

class ToolHandlerManager {
  final Map<String, _SessionHandlers> _sessions = {};

  void registerSession({
    required String sessionId,
    required Map<Tool, ToolCallHandler> toolHandlers,
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (_sessions.containsKey(sessionId)) {
      throw AppleFoundationException(
        'Session already registered: $sessionId',
        code: 'SESSION_ALREADY_EXISTS',
      );
    }


    final toolNames = toolHandlers.keys.map((t) => t.name).toList();
    final uniqueNames = toolNames.toSet();
    if (toolNames.length != uniqueNames.length) {
      throw AppleFoundationException(
        'Duplicate tool names detected',
        code: 'DUPLICATE_TOOL_NAMES',
      );
    }

    final handlersByName = <String, ToolCallHandler>{};
    for (final entry in toolHandlers.entries) {
      handlersByName[entry.key.name] = entry.value;
    }

    _sessions[sessionId] = _SessionHandlers(
      handlers: handlersByName,
      createdAt: DateTime.now(),
      isActive: true,
      timeout: timeout,
    );

    developer.log(
      'Registered session $sessionId with ${toolHandlers.length} tools',
      name: 'ToolHandlerManager',
    );
  }

  Future<dynamic> handleToolCall(ToolCall call) async {
    final sessionHandlers = _sessions[call.sessionId];

    if (sessionHandlers == null) {
      throw AppleFoundationException(
        'Session not found: ${call.sessionId}',
        code: 'SESSION_NOT_FOUND',
      );
    }

    if (!sessionHandlers.isActive) {
      throw AppleFoundationException(
        'Session is inactive: ${call.sessionId}',
        code: 'SESSION_INACTIVE',
      );
    }

    final handler = sessionHandlers.handlers[call.toolName];
    if (handler == null) {
      throw AppleFoundationException(
        'No handler registered for tool: ${call.toolName}',
        code: 'TOOL_HANDLER_NOT_FOUND',
        details: {
          'toolName': call.toolName,
          'sessionId': call.sessionId,
          'availableTools': sessionHandlers.handlers.keys.toList(),
        },
      );
    }

    return await _executeWithTimeout(
      handler: handler,
      call: call,
      timeout: sessionHandlers.timeout,
    );
  }

  void closeSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session != null) {
      session.isActive = false;
      _sessions.remove(sessionId);
      developer.log('Closed session $sessionId', name: 'ToolHandlerManager');
    }
  }

  int get activeSessionCount => _sessions.length;

  bool isSessionActive(String sessionId) {
    final session = _sessions[sessionId];
    return session != null && session.isActive;
  }

  List<String>? getToolNames(String sessionId) {
    final session = _sessions[sessionId];
    return session?.handlers.keys.toList();
  }

  Future<dynamic> _executeWithTimeout({
    required ToolCallHandler handler,
    required ToolCall call,
    required Duration timeout,
  }) async {
    try {
      return await handler(call).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Handler execution timed out', timeout);
        },
      );
    } on TimeoutException {
      throw AppleFoundationException(
        'Tool handler timed out: ${call.toolName}',
        code: 'TOOL_HANDLER_TIMEOUT',
        details: {'toolName': call.toolName, 'timeout': timeout.inSeconds},
      );
    } catch (e) {
      if (e is AppleFoundationException) {
        rethrow;
      }
      throw AppleFoundationException(
        'Tool execution failed: ${call.toolName}',
        code: 'TOOL_EXECUTION_FAILED',
        details: {
          'toolName': call.toolName,
          'errorType': e.runtimeType.toString(),
        },
      );
    }
  }
}


class _SessionHandlers {
  final Map<String, ToolCallHandler> handlers;
  final DateTime createdAt;
  final Duration timeout;
  bool isActive;

  _SessionHandlers({
    required this.handlers,
    required this.createdAt,
    required this.isActive,
    required this.timeout,
  });
}
