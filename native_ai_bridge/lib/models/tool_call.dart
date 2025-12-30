// When the model decides to call a tool, it will send a ToolCall object to the tool handler.
// which is then handled using the ToolCallHandler.
class ToolCall {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String sessionId;
  const ToolCall({
    required this.toolName,
    required this.arguments,
    required this.sessionId,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final args = json['arguments'];
    return ToolCall(
      toolName: json['toolName'] as String,
      arguments: args is Map
          ? Map<String, dynamic>.from(args)
          : args as Map<String, dynamic>,
      sessionId: json['sessionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toolName': toolName,
      'arguments': arguments,
      'sessionId': sessionId,
    };
  }

  @override
  String toString() {
    return 'ToolCall(toolName: $toolName, arguments: $arguments, sessionId: $sessionId)';
  }
}
