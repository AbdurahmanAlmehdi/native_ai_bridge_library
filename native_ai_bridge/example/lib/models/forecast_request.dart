import 'package:native_ai_bridge/native_ai_bridge.dart';

/// A model representing a weather forecast request.
/// 
/// This demonstrates using the generator with various argument types
/// including integers with constraints.
@GenerateTool(
  name: 'get_forecast',
  description: 'Get weather forecast for a city over multiple days',
)
class ForecastRequest {
  /// The name of the city
  @GenerateToolArgument(
    description: 'The city name to get forecast for',
  )
  final String city;

  /// Number of days to forecast
  @GenerateToolArgument(
    description: 'Number of forecast days (1-7)',
    isOptional: true,
    constraints: {
      'min': 1,
      'max': 7,
    },
  )
  final int? days;

  /// Include hourly breakdown
  @GenerateToolArgument(
    description: 'Whether to include hourly breakdown',
    isOptional: true,
  )
  final bool? includeHourly;

  const ForecastRequest({
    required this.city,
    this.days = 3,
    this.includeHourly = false,
  });

  Map<String, dynamic> toJson() => {
        'city': city,
        if (days != null) 'days': days,
        if (includeHourly != null) 'includeHourly': includeHourly,
      };

  factory ForecastRequest.fromJson(Map<String, dynamic> json) =>
      ForecastRequest(
        city: json['city'] as String,
        days: json['days'] as int?,
        includeHourly: json['includeHourly'] as bool?,
      );
}
