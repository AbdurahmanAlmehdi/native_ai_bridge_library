# Native AI Bridge Generator

Code generators for the `native_ai_bridge` package:

- a `build_runner` builder that creates Foundation Models `Tool` classes from annotated Dart models, and
- a `siri` command that writes Siri AI tool intents, generable entities and app skills (Swift and `SKILL.md`) from annotated Dart. See [Siri AI tools and app skills](#siri-ai-tools-and-app-skills).

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  native_ai_bridge: ^0.2.2

dev_dependencies:
  build_runner: ^2.4.0
  native_ai_bridge_generator: ^0.2.0-dev.1
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

The generator accepts `analyzer` 10 to 14. If `pub get` cannot resolve, run:
```bash
flutter pub upgrade
```

## Siri AI tools and app skills

> Experimental. Apple's Siri AI Developer Preview needs the iOS 27.3 betas and may change between betas, so the annotations are `@experimental` and this command ships in a pre-release.

Siri AI calls Swift App Intents compiled into your app target; it never calls Dart. `dart run native_ai_bridge_generator:siri` turns annotated Dart into that Swift, plus `SKILL.md` files, so you only write each tool's handler by hand. See "Siri AI vs this package" in the `native_ai_bridge` README for what Siri AI needs and the limits of the preview.

The command is a standalone CLI, like `pigeon` or `flutter_native_splash`, not a `build_runner` builder: builders can't write into `ios/`.

### 1. Declare tools, entities and skills in Dart

Put them in one library, for example `lib/siri/siri_tools.dart`. Nothing in it runs in your app.

```dart
import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriTool(
  title: 'Get Forecast',
  description: 'Gets the weather forecast for a city, in degrees Celsius.',
)
class GetForecast {
  @SiriField(title: 'Request', description: 'The city and how many days.')
  late final ForecastRequest request;
}

@SiriGenerableEntity(title: 'Forecast Request')
class ForecastRequest {
  @SiriField(title: 'City', description: 'The city name in English.')
  late final String city;

  @SiriField(title: 'Days', description: 'How many days, from 1 to 7.')
  late final int days;
}

@SiriGenerableEntity(title: 'Units')
enum TemperatureUnit {
  @SiriField(title: 'Celsius', description: 'Degrees Celsius.')
  celsius,
  fahrenheit,
}

@SiriSkill(
  name: 'weather-forecast',
  description: 'Answers questions about the weather forecast for a city.',
  body: '''
Use the get forecast tool whenever the person asks about the weather.
Use 3 days when the person does not say how many.
''',
)
abstract final class WeatherForecastSkill {}
```

| Annotation | Put it on | Becomes |
|---|---|---|
| `@SiriTool(title, description)` | a class whose fields are the parameters | `<Class>.g.swift`: an `@AppIntent(.tool)` struct and a `<Class>Handler` protocol |
| `@SiriField(title, description)` | every tool parameter and entity property; optionally enum cases | `@Parameter` or `@Property` metadata, or an enum case's title and subtitle |
| `@SiriGenerableEntity({title})` | a class or an enum | an `@AppEntity(.generable)` `TransientAppEntity`, or an `AppEnum` |
| `@SiriSkill(name, description, body)` | any top-level declaration | `<name>/SKILL.md` |

A generable entity's `displayRepresentation` is its type title for every instance, because the generator can't know which property identifies an instance. Siri confirmations therefore show the type, not the values.

Supported types for parameters and properties: `String`, `int`, `double`, `bool`, `DateTime` (Swift `Date`), an enum or class marked `@SiriGenerableEntity` in the same library, and a `List` of these. Tool parameters may be nullable; entity properties may not, until a 27.3 compile shows Apple accepts optionals there.

On newer Dart SDKs the analyzer reports `experimental_member_use` for these annotations. Silence it in `analysis_options.yaml` if you prefer:

```yaml
analyzer:
  errors:
    experimental_member_use: ignore
```

### 2. Add `native_ai_bridge.yaml` at the app root

```yaml
siri:
  input: lib/siri/siri_tools.dart
  swift_out: ios/Runner/Siri/Generated
  skills_out: ios/Runner/Skills.skillsbundle/Skills
  compilation_condition: SIRI_AI_TOOLS
```

| Key | Required | Meaning |
|---|---|---|
| `input` | yes | The Dart library with the annotations. |
| `swift_out` | yes | Folder for the generated `.g.swift` files. |
| `skills_out` | yes | The `Skills` folder inside your `Skills.skillsbundle`. |
| `compilation_condition` | no | Wraps every Swift file in `#if <condition>`. See [Building only with the 27.3 SDK](#building-only-with-the-273-sdk). |

Unknown keys are an error, so a typo can't silently drop a setting.

### 3. Generate

```bash
dart run native_ai_bridge_generator:siri
```

Run it again whenever the Dart changes; unchanged files are not touched. In CI, check that the committed files are current:

```bash
dart run native_ai_bridge_generator:siri --check
```

`--check` writes nothing. It lists every missing, stale or orphaned file and exits 1, or prints `Siri files are up to date.` and exits 0.

| Exit code | Meaning |
|---|---|
| 0 | Done, or up to date with `--check`. |
| 1 | A validation error, a Dart error in the input, a file it refuses to overwrite, or out of date with `--check`. |
| 2 | Bad arguments, or `native_ai_bridge.yaml` missing or invalid. The error includes an example config. |

Every generated file starts with `// GENERATED by native_ai_bridge_generator. Do not edit.` (in `SKILL.md`, an HTML comment right after the frontmatter, which must stay on the first line). The command only overwrites files that carry this header and refuses to touch anything else. A file it no longer produces, such as the Swift for a deleted tool or the folder of a renamed skill, is an orphan: the command warns about it and `--check` fails, but you delete it by hand.

### 4. Add the output to Xcode once

The command never edits `project.pbxproj`. It warns when an output folder did not exist yet.

1. **Swift.** In Xcode, drag `ios/Runner/Siri` (or just `Generated`) onto the Runner group and choose to add it as a folder, so Xcode keeps it in sync (a synchronized group, Xcode 16 or later). Tick the Runner target. New generated files are then compiled without further changes.
2. **Skills.** Create the bundle with File > New > File from Template > Skills Bundle, keep the name `Skills`, and select the Runner target. Xcode adds `Skills.skillsbundle` to Copy Bundle Resources. Point `skills_out` at its `Skills` folder. An app target can have only one skills bundle.

### 5. Implement the handlers in Swift

Each tool gets a protocol named `<Tool>Handler` with one `perform` method that takes the tool's parameters and returns the text Siri says. Implement it and assign it to the tool's static `handler` at launch. Siri can run a tool while the app is closed; the system launches the app in the background, so `didFinishLaunching` still runs. No Flutter code is involved.

```swift
#if SIRI_AI_TOOLS
@available(iOS 27.3, *)
struct ForecastHandler: GetForecastHandler {
  func perform(request: ForecastRequest) async throws -> String {
    let forecast = try await WeatherService.forecast(city: request.city, days: request.days)
    return "Expect \(forecast.summary) in \(request.city)."
  }
}
#endif
```

```swift
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  #if SIRI_AI_TOOLS
    if #available(iOS 27.3, *) {
      GetForecast.handler = ForecastHandler()
    }
  #endif
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

Set each handler exactly once, at launch, before Siri can call the tool. `handler` is a `nonisolated(unsafe) static var`, so Swift does not check it for data races; assigning it later, or from several threads, is unsafe. If no handler is set, the tool throws `HandlerError.notSet`, and Siri says "<tool title> is not set up in this app yet." Handlers receive values only; the generated code never contains secrets. For any tool that changes state (adds to a cart, sends something, edits data), require authentication: add `static let authenticationPolicy = IntentAuthenticationPolicy.requiresAuthentication` in an extension of the generated tool struct, or write that tool by hand.

### Building only with the 27.3 SDK

The generated Swift is `@available(iOS 27.3, *)`, but the macros it uses exist only in the Xcode 27.3 SDK, and Xcode 27.1 and 27.3 ship the same Swift compiler, so `#if compiler(...)` can't tell them apart. Set `compilation_condition` and define that condition only when building against the 27.3 SDK. In `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`:

```
SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=iphoneos27.3*] = $(inherited) SIRI_AI_TOOLS
SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=iphonesimulator27.3*] = $(inherited) SIRI_AI_TOOLS
```

Older Xcode versions then build the app without the Siri code. The patterns match only 27.3 SDKs: a later SDK also builds without the Siri code, silently, until you add a line for it. Add lines for later SDKs as Apple ships them, or drop the condition once 27.3 is the oldest SDK you build with. If your Runner target sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS` itself, include `$(inherited)` there too. Wrap your handlers and their registration in the same `#if`.

### Validation errors

The command validates everything before writing anything. Each error names the Dart source location, for example:

```
lib/siri/siri_tools.dart:12:7: error [tool-metadata] Tool Search needs a non-empty title and description in @SiriTool.
```

| Code | Rule |
|---|---|
| `skill-name` | 1 to 64 characters from `a-z`, `0-9` and `-`, with no leading, trailing or double hyphen. Two skills with the same name clash and fail here too. |
| `skill-description` | Required, a single line, at most 1024 characters. |
| `skill-body` | At most 10,000 characters, Apple's limit, counting the generated header line. |
| `tool-metadata` | A non-empty title and description on every tool, parameter and entity property, and on any `@SiriField` on an enum case. |
| `unsupported-type` | A map, record, `dynamic`, a nullable `List`, a `List` of nullable values, a nested `List`, a class or enum without `@SiriGenerableEntity`, or a nullable entity property. |
| `name-clash` | A declaration marked both `@SiriTool` and `@SiriGenerableEntity`, which would write the same `.g.swift` file twice. |

A Dart error in the input file (an unresolved import, say, before `flutter pub get`) is reported as `error [dart]` with its location.

### What is not verified here

Siri behaviour needs a physical Apple Intelligence device on iOS 27.3, and the generated Swift needs the Xcode 27.3 SDK to compile. The generator's own tests compare its output with golden files. The example app in `native_ai_bridge/example` shows the whole setup.

## License

MIT
