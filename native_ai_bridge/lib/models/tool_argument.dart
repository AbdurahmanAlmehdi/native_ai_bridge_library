import '../enums/tool_argument_type.dart';

// This can be a parameter of a tool call for example if a weather api requires a city name as an argument.
// CityToolArgument extends ToolArgument and has a type of ToolArgumentType.string and a name of "city".
abstract class ToolArgument {
  String get name;
  ToolArgumentType get type;
  String get description;
  bool get isOptional;

  /// Optional constraints for the argument.
  ///
  /// For example, for numeric types, this could contain range constraints.
  /// 
  /// {
  ///   "min": 1,
  ///   "max": 100
  /// }
  /// 
  /// {
  ///   "pattern": "^[a-zA-Z]+$"
  /// }
  Map<String, dynamic>? get constraints;


  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toJson(),
      'description': description,
      'isOptional': isOptional,
      if (constraints != null) 'constraints': constraints,
    };
  }

  @override
  String toString() {
    return 'ToolArgument(name: $name, type: ${type.value}, description: $description, isOptional: $isOptional)';
  }
}


class BaseToolArgument extends ToolArgument {
  @override
  final String name;

  @override
  final ToolArgumentType type;

  @override
  final String description;

  @override
  final bool isOptional;

  @override
  final Map<String, dynamic>? constraints;


  BaseToolArgument({
    required this.name,
    required this.type,
    required this.description,
    this.isOptional = false,
    this.constraints,
  });


  factory BaseToolArgument.fromJson(Map<String, dynamic> json) {
    return BaseToolArgument(
      name: json['name'] as String,
      type: ToolArgumentType.fromString(json['type'] as String),
      description: json['description'] as String,
      isOptional: json['isOptional'] as bool? ?? false,
      constraints: json['constraints'] as Map<String, dynamic>?,
    );
  }
}
