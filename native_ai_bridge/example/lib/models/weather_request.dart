import 'package:native_ai_bridge/native_ai_bridge.dart';

/// A model representing a weather information request.
///
/// This model is annotated with @GenerateTool to automatically generate
/// a Tool class that can be used with Apple Intelligence sessions.
@GenerateTool(
  name: 'get_weather',
  description: 'Retrieve current weather information for a specific city',
)
class WeatherRequest {
  /// Fields will be converted to tool arguments automatically but you can also manually annotate them with @GenerateToolArgument to customize their behavior.
  final String? countryCode;

  /// Optional country code for disambiguation
  // @GenerateToolArgument(
  //   description: 'Two-letter country code (e.g., "US", "UK")',
  //   isOptional: true,
  // )
  // final String? countryCode;

  /// Units for temperature (metric or imperial)
  @GenerateToolArgument(
    description:
        'Temperature units: "metric" (Celsius) or "imperial" (Fahrenheit)',
    isOptional: true,
    constraints: {
      'enum': ['metric', 'imperial'],
    },
  )
  final String? units;

  /// The name of the city to get weather information for
  final String city;

  const WeatherRequest({
    required this.city,
    this.countryCode,
    this.units = 'metric',
  });

  Map<String, dynamic> toJson() => {
    'city': city,
    if (countryCode != null) 'countryCode': countryCode,
    if (units != null) 'units': units,
  };

  factory WeatherRequest.fromJson(Map<String, dynamic> json) => WeatherRequest(
    city: json['city'] as String,
    countryCode: json['countryCode'] as String?,
    units: json['units'] as String?,
  );
}
