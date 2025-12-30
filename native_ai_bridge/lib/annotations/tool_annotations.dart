/// Annotation to mark a class as a Tool that should be generated.
///
/// Example:
/// ```dart
/// @GenerateTool(description: 'Get weather information for a city')
/// class GetWeatherModel {
///   final String city;
///   final int? days;
/// }
/// ```
class GenerateTool {
  /// The name of the tool. If not provided, it will be generated from the class name
  /// by converting PascalCase to snake_case (e.g., GetWeatherModel -> get_weather_model).
  final String? name;

  final String? description;

  const GenerateTool({this.name, this.description});
}

/// Annotation to customize a field's behavior when generating ToolArgument.
///
/// Example:
/// ```dart
/// @GenerateTool()
/// class GetWeatherModel {
///   @GenerateToolArgument(description: 'The city name', isOptional: false)
///   final String city;
///
///   @GenerateToolArgument(description: 'Number of days to forecast', isOptional: true)
///   final int? days;
/// }
/// ```
class GenerateToolArgument {
  final String? description;

  final bool? isOptional;

  final Map<String, dynamic>? constraints;

  final bool exclude;

  const GenerateToolArgument({
    this.description,
    this.isOptional,
    this.constraints,
    this.exclude = false,
  });
}
