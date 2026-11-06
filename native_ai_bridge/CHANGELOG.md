## 0.2.1

* Fix the homepage, repository and issue tracker links. They pointed at a repository that does not exist; the package lives in `native_ai_bridge_library`. No code changes.

## 0.2.0

### Features
* `generateStructured` returns JSON that is guaranteed to match a JSON-Schema-style map, using guided generation (`DynamicGenerationSchema`).
* `generateStructured` accepts `images` for the iOS 27 vision-capable model.
* `getCapabilities` reports availability, vision support and whether the current locale is supported.
* Errors keep their native code: `UNSUPPORTED_LANGUAGE`, `CONTEXT_WINDOW_EXCEEDED`, `GUARDRAIL_VIOLATION`, `RATE_LIMITED`, `VISION_UNSUPPORTED`, `INVALID_SCHEMA`.
* `AppleFoundationException` and `NativeAiCapabilities` are exported.

### Fixes
* FoundationModels is weak-linked, so apps with a deployment target below iOS 26 no longer fail to launch on older iOS versions.
* Availability is no longer cached while the model is downloading or Apple Intelligence is off.
* `getStructuredData` returned a map where Dart expected a JSON string.
* `temperature` and `maxTokens` are passed to the model.
* Streaming sends text chunks instead of snapshot objects.

## 0.1.0

### BREAKING CHANGES
* Package renamed from `apple_foundation_flutter` to `native_ai_bridge`
* iOS plugin class renamed from `AppleFoundationFlutterPlugin` to `NativeAiBridgePlugin`
* Method channel names updated from `apple_foundation_flutter` to `native_ai_bridge`
* All imports must be updated to use `package:native_ai_bridge`

### Features
* Added `AppleIntelligenceSession` class for better session management
* Added proper error handling for resource availability
* Added documentation for handling RUN_ERROR and MODEL_NOT_READY errors

### Technical
* Updated iOS requirements to iOS 26.0+
* Updated Xcode requirements to Xcode 26.0 beta 2
* Updated package metadata with new repository URLs
* Fixed various bugs and improved stability
* Added note about future MacOS support

### Migration Guide
See README.md for migration instructions from `apple_foundation_flutter`

## 0.0.1

* Initial release
* Basic implementation of Apple Foundation Models framework integration
* Support for text generation, structured data, and streaming responses
* Session management capabilities
* Error handling and availability checks
