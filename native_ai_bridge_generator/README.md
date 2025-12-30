# Native AI Bridge Generator

A code generator for the `native_ai_bridge` package that automatically creates Tool classes from annotated Dart model classes.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  native_ai_bridge: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  native_ai_bridge_generator: ^0.1.0
```

## Usage

### 1. Create an Annotated Model

Create a model class and annotate it with `@GenerateTool`:

```dart
import 'package:native_ai_bridge/native_ai_bridge.dart';

@GenerateTool(
  name: 'get_weather',
  description: 'Retrieve current weather information for a city',
)
class WeatherRequest {
  final String city;
  final String? countryCode;
  
  @GenerateToolArgument(
    description: 'Temperature units: "metric" or "imperial"',
    isOptional: true,
    constraints: {
      'enum': ['metric', 'imperial'],
    },
  )
  final String? units;

  const WeatherRequest({
    required this.city,
    this.countryCode,
    this.units = 'metric',
  });
}
```

### 2. Run the Generator

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `weather_request.tool.g.dart`:

```dart
class WeatherRequestTool extends BaseTool {
  WeatherRequestTool()
      : super(
          name: 'get_weather',
          description: 'Retrieve current weather information for a city',
          arguments: [
            BaseToolArgument(
              name: 'city',
              type: ToolArgumentType.string,
              description: 'City',
              isOptional: false,
            ),
            BaseToolArgument(
              name: 'countryCode',
              type: ToolArgumentType.string,
              description: 'Country code',
              isOptional: true,
            ),
            BaseToolArgument(
              name: 'units',
              type: ToolArgumentType.string,
              description: 'Temperature units: "metric" or "imperial"',
              isOptional: true,
              constraints: {'enum': ['metric', 'imperial']},
            ),
          ],
        );
}
```

### 3. Use the Generated Tool

```dart
import 'package:native_ai_bridge/native_ai_bridge.dart';
import 'models/weather_request.tool.g.dart';

void main() async {
  // Create an instance of the generated tool
  final weatherTool = WeatherRequestTool();

  // Create a session with tool handler
  final session = await AppleIntelligenceSession.create(
    'You are a helpful weather assistant.',
    toolHandlers: {
      weatherTool: (ToolCall call) async {
        final city = call.arguments['city'] as String;
        final units = call.arguments['units'] as String? ?? 'metric';
        
        // Fetch actual weather data here
        return 'Weather in $city: 22°${units == 'metric' ? 'C' : 'F'}, Sunny';
      },
    },
  );

  // Ask a question that triggers the tool
  final response = await session.ask('What is the weather in London?');
  print(response);

  await session.close();
}
```

## Annotations

### @GenerateTool

Marks a class for Tool generation.

**Parameters:**
- `name` (String, optional): Tool name. Defaults to snake_case of class name.
- `description` (String, optional): Tool description. Defaults to "Tool for ClassName".

### @GenerateToolArgument

Customizes a field's tool argument properties.

**Parameters:**
- `description` (String, optional): Argument description. Auto-generated from field name if not provided.
- `isOptional` (bool, optional): Whether the argument is optional. Defaults to field nullability.
- `exclude` (bool, optional): Exclude this field from tool arguments.
- `constraints` (Map<String, dynamic>, optional): Validation constraints like min, max, enum.

## Supported Types

The generator supports these Dart types:

- `String` → `ToolArgumentType.string`
- `int` → `ToolArgumentType.integer`
- `double` → `ToolArgumentType.double_`
- `bool` → `ToolArgumentType.boolean`
- `List<String>` → `ToolArgumentType.string` (array)
- `Map<String, dynamic>` → `ToolArgumentType.string` (JSON)

## Examples

### Integer with Constraints

```dart
@GenerateTool(
  name: 'get_forecast',
  description: 'Get multi-day weather forecast',
)
class ForecastRequest {
  final String city;

  @GenerateToolArgument(
    description: 'Number of forecast days (1-7)',
    constraints: {
      'min': 1,
      'max': 7,
    },
  )
  final int? days;

  const ForecastRequest({
    required this.city,
    this.days = 3,
  });
}
```

### Boolean Arguments

```dart
@GenerateTool(name: 'search')
class SearchRequest {
  final String query;

  @GenerateToolArgument(
    description: 'Include archived results',
    isOptional: true,
  )
  final bool? includeArchived;
}
```

### Excluding Fields

```dart
@GenerateTool(name: 'create_user')
class UserRequest {
  final String username;
  final String email;

  @GenerateToolArgument(exclude: true)
  final String? internalId; // Won't be included in tool arguments
}
```

## Build Configuration

Create `build.yaml` in your project:

```yaml
targets:
  $default:
    builders:
      native_ai_bridge_generator|tool_builder:
        enabled: true
        generate_for:
          - lib/models/*.dart
```

## Troubleshooting

### Generated files not found

Make sure to run:
```bash
dart run build_runner build
```

### Import errors

Import the generated file:
```dart
import 'your_model.tool.g.dart';
```

### Analyzer warnings

The warnings about analyzer version can be safely ignored, or update your dependencies:
```bash
flutter pub upgrade
```

## License

MIT
