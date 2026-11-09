import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriTool(
  title: 'Get Forecast',
  description:
      'Gets the weather forecast for a city for the next few days, with '
      'temperatures in degrees Celsius.',
)
class GetForecast {
  @SiriField(
    title: 'Forecast Request',
    description: 'The city and how many days to forecast.',
  )
  late final ForecastRequest request;
}

@SiriGenerableEntity(title: 'Forecast Request')
class ForecastRequest {
  @SiriField(
    title: 'City',
    description: 'The city name in English, for example "Tripoli".',
  )
  late final String city;

  @SiriField(
    title: 'Days',
    description: 'How many days to forecast, from 1 to 7. 3 when not stated.',
  )
  late final int days;
}

@SiriSkill(
  name: 'weather-forecast',
  description:
      'Answers questions about the weather forecast for a city in the '
      'Native AI Bridge example app.',
  body: '''
Use the get forecast tool whenever the person asks about the weather,
temperature or rain in a city.

- Put the city name in English in the forecast request.
- Use 3 days when the person does not say how many, and never more than 7.
- Temperatures are in degrees Celsius. Do not convert them unless asked.
''',
)
abstract final class WeatherForecastSkill {}
