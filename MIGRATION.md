# Migration Guide: apple_foundation_flutter → native_ai_bridge

The `native_ai_bridge` package is the successor to `apple_foundation_flutter`. Both packages are available on pub.dev, but `native_ai_bridge` is the recommended package for all new and existing projects.

## Package Information

**Legacy package:** `apple_foundation_flutter` (still available on pub.dev)
**New package:** `native_ai_bridge` (recommended)

Both packages provide the same functionality, but `native_ai_bridge` receives active development, updates, and bug fixes.

## Why the Rename?

- Better reflects the package's role as a bridge between Flutter and native AI frameworks
- Prepares for future multi-platform support (macOS support coming soon)
- More descriptive and discoverable name

## Migration Steps

### 1. Update pubspec.yaml

Replace the old package with the new one:

```yaml
dependencies:
  # OLD - Remove this
  # apple_foundation_flutter: ^0.1.1

  # NEW - Add this
  native_ai_bridge: ^0.1.0
```

If you're using the code generator:

```yaml
dev_dependencies:
  # OLD - Remove this
  # apple_foundation_flutter_generator: ^0.1.0

  # NEW - Add this
  native_ai_bridge_generator: ^0.1.0
  build_runner: ^2.4.0
```

### 2. Update Imports

Update all import statements in your Dart files:

```dart
// OLD
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

// NEW
import 'package:native_ai_bridge/native_ai_bridge.dart';
```

### 3. Update iOS Configuration (if applicable)

The iOS plugin class has been renamed. If you have any custom configuration or plugin references:

**Old:** `AppleFoundationFlutterPlugin`
**New:** `NativeAiBridgePlugin`

**Old method channel:** `apple_foundation_flutter`
**New method channel:** `native_ai_bridge`

Most users won't need to change anything in their iOS code, as these changes are handled internally.

### 4. API Compatibility

**Good news!** All API methods remain exactly the same. No code changes needed beyond updating imports.

The following classes and methods work identically:
- `AppleIntelligenceSession`
- `AppleFoundationFlutter`
- `BaseTool`, `BaseToolArgument`, `ToolCall`
- `ToolHandlerManager`
- All generation methods (`ask`, `generateText`, `summarizeText`, etc.)

### 5. Code Generator

If you're using the code generator, the annotations remain the same:

```dart
// Still works the same way
@GenerateTool(
  name: 'get_weather',
  description: 'Get weather for a city',
)
class WeatherRequest {
  final String city;

  @GenerateToolArgument(
    description: 'Temperature units',
    constraints: {'enum': ['metric', 'imperial']},
  )
  final String? units;
}
```

Run the generator after updating packages:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Complete Example Migration

### Before (apple_foundation_flutter)

```dart
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

void main() async {
  final plugin = AppleFoundationFlutter();

  if (await plugin.isAvailable()) {
    final session = await AppleIntelligenceSession.create(
      'You are a helpful assistant',
    );

    final response = await session.ask('Hello!');
    print(response);

    await session.close();
  }
}
```

### After (native_ai_bridge)

```dart
import 'package:native_ai_bridge/native_ai_bridge.dart';

void main() async {
  final plugin = AppleFoundationFlutter();

  if (await plugin.isAvailable()) {
    final session = await AppleIntelligenceSession.create(
      'You are a helpful assistant',
    );

    final response = await session.ask('Hello!');
    print(response);

    await session.close();
  }
}
```

The only change is the import statement!

## Automated Migration Script

You can use this bash script to automatically update imports in your project:

```bash
#!/bin/bash
# Save as migrate_to_native_ai_bridge.sh

find lib -type f -name "*.dart" -exec sed -i '' \
  's/package:apple_foundation_flutter/package:native_ai_bridge/g' {} +

echo "Migration complete! Don't forget to update pubspec.yaml"
```

Run it from your project root:

```bash
chmod +x migrate_to_native_ai_bridge.sh
./migrate_to_native_ai_bridge.sh
```

## What's New in native_ai_bridge 0.1.0?

While migrating, you'll also get these improvements:

- **Better Documentation**: Enhanced README with clearer examples
- **Comprehensive Tests**: 70+ tests ensuring reliability
- **Improved Error Handling**: More detailed error messages and codes
- **Code Generator**: Separate package for generating Tool classes from annotated models
- **Future-Ready**: Prepared for macOS support (coming soon)

## Need Help?

If you encounter any issues during migration:

1. Check that you've updated both the package name in `pubspec.yaml` and all imports
2. Run `flutter clean && flutter pub get` to ensure dependencies are fresh
3. If using the code generator, delete generated files and regenerate: `dart run build_runner clean && dart run build_runner build`
4. [Open an issue](https://github.com/AbdurahmanAlmehdi/native_ai_bridge_library/issues) if problems persist

## Package Status

Both packages are available on pub.dev:

- **apple_foundation_flutter**: Legacy package (no longer actively developed)
  - Last version: 0.1.1
  - Status: Stable but will not receive new features or updates
  - Use case: Only if you need to maintain existing projects without migration

- **native_ai_bridge**: Current package (actively developed)
  - Current version: 0.1.0+
  - Status: Active development with new features and updates
  - Use case: Recommended for all new projects and migrations

## Should I Migrate?

**Yes, if:**
- You want access to new features and improvements
- You need bug fixes and ongoing support
- You're starting a new project
- You want better documentation and examples

**You can wait if:**
- Your project is in maintenance mode with no planned updates
- Migration would require significant testing resources
- The current functionality meets all your needs

However, we recommend planning migration as `apple_foundation_flutter` will not receive updates, security patches, or new features.
