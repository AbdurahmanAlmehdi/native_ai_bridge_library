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
