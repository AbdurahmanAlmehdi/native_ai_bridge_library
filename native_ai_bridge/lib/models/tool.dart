import 'tool_argument.dart';

// This is a tool that can be used in a session.
// It can be a tool that is defined in the session or a tool that is defined in the model.
// Tools are used to call external APIs or services.
// Example:
// class GetWeatherTool extends Tool {
//   @override
//   String get name => 'get_weather';
//   @override
//   String get description => 'Get the weather for a given city';
//   @override
//   List<ToolArgument> get arguments => [ToolArgument(name: 'city', type: ToolArgumentType.string, description: 'The city to get the weather for')];
// }
abstract class Tool {

  String get name;

  String get description;

  List<ToolArgument> get arguments;


  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'arguments': arguments.map((arg) => arg.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Tool(name: $name, description: $description, arguments: ${arguments.length})';
  }
}

class BaseTool extends Tool {
  @override
  final String name;

  @override
  final String description;

  @override
  final List<ToolArgument> arguments;


  BaseTool({
    required this.name,
    required this.description,
    required this.arguments,
  });


  factory BaseTool.fromJson(Map<String, dynamic> json) {
    return BaseTool(
      name: json['name'] as String,
      description: json['description'] as String,
      arguments:
          (json['arguments'] as List<dynamic>?)
              ?.map(
                (arg) => BaseToolArgument.fromJson(arg as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
