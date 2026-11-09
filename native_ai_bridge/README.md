# Native AI Bridge

A Flutter plugin that provides access to Apple's on-device Foundation Models framework, available on iOS 26.0 and above. This plugin allows you to integrate Apple Intelligence features directly into your Flutter applications, offering powerful, private, and efficient AI capabilities.

**Note**: Currently iOS only, but since Foundation Models works on macOS, support will be added in a future update.

## Features

- **On-Device & Private**: All processing happens locally, ensuring user data remains private.
- **Text Generation**: Create rich, context-aware text content.
- **Streaming Support**: Stream text and structured JSON responses in real-time for a dynamic UX.
- **Structured Data**: Generate structured data (e.g., JSON) from natural language prompts.
- **Session Management**: Maintain conversation history and context with sessions.
- **Tool Calling**: Extend the model with custom tools for fetching data, performing actions, and integrating with frameworks.
- **Advanced Control**: Fine-tune model output with parameters like temperature, token limits, and more.
- **Helper Functions**: Includes specialized methods for summarization, classification, alternative generation, and information extraction.
- **Availability Checks**: Gracefully check if Apple Intelligence is available on the user's device.

## Requirements

- **Platform**: the plugin installs on iOS 14.0+ and the model runs on iOS 26.0+ (image input needs iOS 27.0+). FoundationModels is weak-linked, so apps that support older iOS versions still launch there.
- **IDE**: Xcode 26.0+ (Xcode 27 for image input)
- **Flutter**: 3.0+

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  native_ai_bridge: ^0.2.2
```

Then run:

```bash
flutter pub get
```

### Code Generator (Optional)

For automatic Tool class generation from annotated models:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  native_ai_bridge_generator: ^0.1.0
```

## Usage

You can use this plugin in two ways:

### 1. Using AppleIntelligenceSession (Recommended)

The session class provides a more object-oriented approach with automatic session management:

```dart
import 'package:native_ai_bridge/native_ai_bridge.dart';

// Create a new session
final session = await AppleIntelligenceSession.create(
  'You are a helpful AI assistant that provides concise responses.',
);

try {

  final response = await session.ask('What is quantum computing?');
  print(response);

  // Generate structured data
  final data = await session.getStructuredData(
    'Create a profile for a quantum computer scientist',
  );
  print(data);

  // Stream responses
  await for (final chunk in session.generateTextStream('Tell me a story')) {
    print(chunk); // Process each chunk as it arrives
  }
} finally {
  // Always close the session when done
  await session.close();
}
```

You can create multiple independent sessions:

```dart
// Create two sessions with different contexts
final techSession = await AppleIntelligenceSession.create(
  'You are a technical expert in computer science.',
);
final storySession = await AppleIntelligenceSession.create(
  'You are a creative storyteller.',
);

// Use them independently
final techResponse = await techSession.ask('Explain APIs');
final storyResponse = await storySession.ask('Tell me a short story');

// Close both sessions when done
await techSession.close();
await storySession.close();
```

### 2. Using the Plugin Directly

If you prefer to manage sessions yourself or need more direct control:

```dart
import 'package:native_ai_bridge/native_ai_bridge.dart';

final plugin = AppleFoundationFlutter();

// Check availability
final bool isAvailable = await plugin.isAvailable();
if (!isAvailable) {
  final status = await plugin.getAvailabilityStatus();
  print('Apple Intelligence is not available: ${status['reason']}');
  return;
}

// Create a session manually
final sessionId = await plugin.openSession(
  'You are a helpful assistant.',
);

try {
  // Use the session ID in calls
  final response = await plugin.generateText(
    'What is machine learning?',
    sessionId: sessionId,
  );
  print(response);

  // Stream responses
  String streamedResponse = '';
  final textStream = plugin.generateTextStream(
    'Tell me a story about AI',
    sessionId: sessionId,
  );

  await for (final chunk in textStream) {
    streamedResponse += chunk;
  }
} finally {
  // Clean up the session
  await plugin.closeSession(sessionId);
}
```

## API Reference

### Core Methods

- **`Future<bool> isAvailable()`**: Checks if Apple Intelligence is supported and enabled.
- **`Future<Map<String, dynamic>> getAvailabilityStatus()`**: Gets a detailed status, including a reason if unavailable.
- **`Future<String?> getPlatformVersion()`**: Gets the underlying iOS version.

### Session Management

- **`Future<String> openSession(String instructions)`**: Creates a new session with system-level instructions and returns a unique session ID.
- **`Future<void> closeSession(String sessionId)`**: Closes and cleans up a session.

### Generation Methods (Single Response)

These methods return a complete response after generation is finished.

- **`Future<String?> ask(String prompt, {String? sessionId})`**: A simple method for a single question-and-answer interaction.
- **`Future<String?> generateText(String prompt, {String? sessionId, int? maxTokens, double? temperature, double? topP})`**: Generates text with advanced options.
- **`Future<Map<String, dynamic>> getStructuredData(String prompt, {String? sessionId})`**: Generates a JSON object from a prompt.
- **`Future<List<String>> getListOfString(String prompt, {String? sessionId})`**: Generates a list of strings, where each item is on a new line.
- **`Future<List<String>> generateAlternatives(String prompt, {String? sessionId, int count})`**: Generates a specified number of variations for a given text.
- **`Future<String?> summarizeText(String text, {String? sessionId, SummarizationStyle style})`**: Summarizes a piece of text in a specific style.
- **`Future<Map<String, dynamic>> extractInformation(String text, {String? sessionId, List<String>? fields})`**: Extracts specific fields from text into a JSON object.
- **`Future<Map<String, double>> classifyText(String text, {String? sessionId, List<String>? categories})`**: Classifies text against a list of categories and returns confidence scores.
- **`Future<List<String>> generateSuggestions(String context, {String? sessionId, int maxSuggestions})`**: Provides contextual suggestions.

### Generation Methods (Streaming)

- **`Stream<String> generateTextStream(String prompt, {String? sessionId, ...})`**: Streams generated text as a series of chunks.
- **`Stream<String> getStructuredDataStream(String prompt, {String? sessionId})`**: Streams a complete JSON object as a raw string. The stream will emit the full string in one or more chunks.

## Error Handling

The plugin uses `AppleFoundationException` for errors. It's best to wrap API calls in a `try-catch` block.

```dart
try {
  final session = await AppleIntelligenceSession.create('You are a helpful assistant');
  final result = await session.generateText('Hello!');
} on AppleFoundationException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  // e.g., 'UNSUPPORTED_OS_VERSION', 'MODEL_NOT_READY', etc.
  switch (e.code) {
    case 'UNSUPPORTED_OS_VERSION':
      // Handle OS not supported
      break;
    case 'MODEL_NOT_READY':
      // Inform user the model is downloading
      break;
    // ... handle other specific error codes
  }
}
```

### Structured output with a schema

`generateStructured` uses Apple's guided generation, so the result always matches the schema. Properties are generated in the order you write them.

```dart
final ai = AppleFoundationFlutter();
final capabilities = await ai.getCapabilities();
if (!capabilities.available) return;

final filters = await ai.generateStructured(
  instructions: 'Turn shopping queries into search filters.',
  prompt: 'samsung phones under 1500, cheapest first',
  schema: {
    'type': 'object',
    'properties': {
      'searchTerm': {'type': 'string'},
      'brand': {'type': 'string', 'description': 'Brand name if one is named'},
      'maxPrice': {'type': 'number'},
      'sort': {'enum': ['none', 'priceAscending', 'priceDescending']},
    },
    'required': ['searchTerm', 'sort'],
  },
);
```

Supported schema keys: `type` (`object`, `array`, `string`, `number`, `integer`, `boolean`), `properties`, `required`, `items`, `minItems`, `maxItems`, `enum` (strings) and `description`.

Pass `images` (encoded JPEG/PNG/HEIC bytes) to reason about photos. This needs iOS 27 and `capabilities.vision`; otherwise the call throws `VISION_UNSUPPORTED`.

### Common Error Codes

- **`UNSUPPORTED_OS_VERSION`**: The iOS version is below 26.0.
- **`DEVICE_NOT_ELIGIBLE`**: The device hardware does not support Apple Intelligence.
- **`APPLE_INTELLIGENCE_NOT_ENABLED`**: The user has not enabled Apple Intelligence in Settings.
- **`MODEL_NOT_READY`**: The language model is still downloading or is otherwise not ready.
- **`TIMEOUT_ERROR`**: The request to the native side timed out.
- **`GENERATION_ERROR`**: An error occurred within the native model during generation.
- **`UNSUPPORTED_LANGUAGE`**: The prompt or locale is in a language the model does not support.
- **`CONTEXT_WINDOW_EXCEEDED`**: Instructions, prompt and output do not fit the context window.
- **`GUARDRAIL_VIOLATION`**: The safety guardrails blocked the prompt or the response.
- **`RATE_LIMITED`**: Too many requests, usually while the app is in the background.
- **`VISION_UNSUPPORTED`** / **`INVALID_IMAGE`**: Image input is unavailable or the bytes could not be decoded.
- **`INVALID_SCHEMA`**: The schema passed to `generateStructured` uses an unsupported shape.
- **`INVALID_ARGUMENTS`**: One of the arguments passed to the method was invalid (e.g., empty prompt).
- **`RUN_ERROR`**: Failed to run the prompt, often due to missing resources. This commonly occurs when:
  - The model resources are still downloading
  - The Local Sanitizer Asset is not yet available
  - Incompatible versions of Xcode
  - The device is low on storage space
  - The model was recently installed and is still initializing

### Handling Resource Availability

When you first install the app or update to a new iOS version, Apple's Foundation Models framework may need to download additional resources. If you have macOS 26 beta 2, make sure you are using Xcode 26 beta 2 as well. If not, you might encounter `RUN_ERROR` or `MODEL_NOT_READY` errors.

## Tool Calling

The plugin supports tool calling, allowing the model to interact with external code for fetching data, performing actions, and integrating with other frameworks.

Quick example:

```dart
// Define a tool
final weatherTool = BaseTool(
  name: 'getWeather',
  description: 'Get weather for a city',
  arguments: [
    BaseToolArgument(
      name: 'city',
      type: ToolArgumentType.string,
      description: 'The city name',
    ),
  ],
);

// Pair tool with its handler
final toolHandlers = {
  weatherTool: (ToolCall call) async {
    final city = call.arguments['city'];
    return await fetchWeather(city);
  },
};

// Create session with tools (tools and handlers are paired)
final session = await AppleIntelligenceSession.create(
  'Help with weather information',
  toolHandlers: toolHandlers,
);

// Model can now call your tool
final response = await session.ask('What\'s the weather in Boston?');
```

### Code Generation for Tools

Instead of manually creating Tool classes, you can use the `native_ai_bridge_generator` package to automatically generate them from annotated model classes.

**Step 1**: Create an annotated model:

```dart
import 'package:native_ai_bridge/native_ai_bridge.dart';

@GenerateTool(
  name: 'get_weather',
  description: 'Retrieve current weather information for a city',
)
class WeatherRequest {
  final String city;

  @GenerateToolArgument(
    description: 'Temperature units: "metric" or "imperial"',
    constraints: {'enum': ['metric', 'imperial']},
  )
  final String? units;

  const WeatherRequest({
    required this.city,
    this.units = 'metric',
  });
}
```

**Step 2**: Run the generator:

```bash
dart run build_runner build
```

**Step 3**: Use the generated tool:

```dart
import 'models/weather_request.tool.g.dart';

final weatherTool = WeatherRequestTool(); // Auto-generated!
final session = await AppleIntelligenceSession.create(
  'Help with weather',
  toolHandlers: {
    weatherTool: (call) async => fetchWeather(call.arguments['city']),
  },
);
```

See the [generator README](../native_ai_bridge_generator/README.md) for full documentation.

## Siri AI vs this package

Apple's Siri AI Developer Preview (iOS 27.3 betas) lets Siri call your app's actions as **tools**, fill **generable entities** from what a person says, and follow **app skills** written as `SKILL.md` files. None of that goes through Foundation Models, and none of it can be registered from Dart.

| | This package | Siri AI |
|---|---|---|
| What runs | Your prompts, on Apple's on-device model | Siri, which calls your app |
| Where you declare it | Dart, at runtime | Swift App Intents and a skills bundle in the app target |
| When Apple finds it | When you call the plugin | At build time, when Xcode extracts App Intents metadata |
| Needs a running Flutter engine | Yes | No. Siri calls compiled Swift, even when the app is not running |

So a Siri AI tool must be a Swift `AppIntent` compiled into your Runner target. A tool defined with `BaseTool` in Dart is only visible to the Foundation Models session you pass it to.

### What Siri AI needs

A tool is an `AppIntent` marked with `@AppIntent(.tool)`. The intent, and each of its parameters, needs a title and a description written for someone who does not know your app:

```swift
import AppIntents

@available(iOS 27.3, *)
@AppIntent(.tool)
struct AddToCart: AppIntent {
  static let title: LocalizedStringResource = "Add to Cart"
  static let description = IntentDescription("Adds a product to the shopping cart.")

  @Parameter(title: "Product", description: "The product to add")
  var product: ProductEntity

  @Parameter(title: "Quantity", description: "How many to add, from 1 to 10", default: 1)
  var quantity: Int

  func perform() async throws -> some IntentResult & ProvidesDialog {
    try await Cart.shared.add(product, quantity: quantity)
    return .result(dialog: "Added \(product.name) to your cart.")
  }
}
```

An app skill is a `SKILL.md` file in `Skills.skillsbundle/Skills/<name>/`. Create the bundle once in Xcode (File > New > File from Template > Skills Bundle) and add it to the app target. The frontmatter holds only `name` and `description`:

```markdown
---
name: store-shopping
description: Helps a shopper find products in the store and add them to the cart.
---
Use the search products tool first whenever the shopper describes something to buy.
After adding a product, offer to open the cart. Never offer to pay; checkout happens in the app.
```

Xcode validates the bundle at build time. The name must be 1 to 64 characters from `a-z`, `0-9` and `-` and match its folder, the description must be one line of at most 1024 characters, and the body is limited to 10,000 characters. A bundle with errors provides no skills, and nothing warns you at runtime.

### Limits of the preview

- **OS and SDK.** Every Siri AI symbol is introduced in iOS 27.3 and needs the Xcode 27.3 beta SDK. Mark the Swift with `@available(iOS 27.3, *)`; devices on older versions keep your existing App Shortcuts.
- **Devices.** iPhone, iPad, Mac and Apple Vision Pro models that support Apple Intelligence, in regions where Apple Intelligence and Siri AI are available. Test on a physical device; Apple's skill testing guide asks for a device, not the Simulator.
- **Languages.** At the start of the preview Siri AI runs in English, French, Japanese, Korean, Portuguese and Spanish. Arabic is not supported.
- **Distribution.** Siri AI reaches only development builds and internal TestFlight testers. External TestFlight testers and App Store users do not get it, even when the build contains the tools.
- **API churn.** Apple says the App Intents API and Siri behaviour may change during the preview.

### Generating the Swift from Dart

You still ship Swift, but you do not have to write the boilerplate. `native_ai_bridge_generator` reads experimental Dart annotations (`@SiriTool`, `@SiriField`, `@SiriGenerableEntity` and `@SiriSkill`) and writes the Swift intents, generable entities, a handler protocol per tool and validated `SKILL.md` files:

```bash
dart run native_ai_bridge_generator:siri
```

You implement each tool's handler in Swift. See the [generator README](../native_ai_bridge_generator/README.md#siri-ai-tools-and-app-skills) for setup.

## Privacy

This plugin processes all data locally on the device using Apple's Foundation Models framework. **No data is transmitted to external servers**, ensuring complete privacy and compliance with data protection regulations.

## Contributing

We welcome contributions! Please see our Contributing Guide for more details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [Flutter Plugin Development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
