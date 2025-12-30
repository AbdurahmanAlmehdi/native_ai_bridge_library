# Native AI Bridge Generator

Code generator for creating `Tool` classes from annotated model classes. This package works with `apple_foundation_flutter` to automatically generate tool definitions from your data models.

## Features

- Automatically generate `Tool` classes from annotated model classes
- Convert model fields to `ToolArgument` definitions
- Support for custom descriptions, optional parameters, and constraints
- Type mapping from Dart types to `ToolArgumentType`

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apple_foundation_flutter:
    path: ../apple_foundation_flutter  # or use pub.dev version
  native_ai_bridge_generator:
    path: ../native_ai_bridge_generator  # or use pub.dev version

dev_dependencies:
  build_runner: ^2.4.0
```

Then run:

```bash
flutter pub get
```

## Usage

### 1. Annotate your model class

```dart
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

@GenerateTool(description: 'Filter products by various criteria')
class ProductFilterModel {
  final String? categoryId;
  final List<String>? brandIds;
  final String? search;
  final String? sku;
  final int page;
  final int pageSize;
  final bool isInStock;
  final Map<String, List<String>> attributeFilters;
  final String? title;
  final double? minPrice;
  final double? maxPrice;

  const ProductFilterModel({
    this.categoryId,
    this.brandIds,
    this.search,
    this.sku,
    this.page = 1,
    this.pageSize = 20,
    this.isInStock = true,
    this.attributeFilters = const {},
    this.title,
    this.minPrice,
    this.maxPrice,
  });
}
```

### 2. Run code generation

```bash
flutter pub run build_runner build
```

### 3. Use the generated Tool

```dart
import 'product_filter_model.dart';
import 'product_filter_model.tool.dart'; // Generated file

// Use the generated tool
final tool = ProductFilterModelTool();

// Use it in a session
final session = await AppleIntelligenceSession.create(
  'You are a helpful assistant',
  toolHandlers: {
    tool: (call) async {
      // Handle the tool call
      final categoryId = call.arguments['categoryId'] as String?;
      // ... process the filter
      return {'result': 'filtered products'};
    },
  },
);
```

## Annotation Options

### @GenerateTool

- `name` (String?): Custom tool name. If not provided, generated from class name (PascalCase -> snake_case)
- `description` (String?): Tool description. If not provided, uses default

### @GenerateToolArgument

Apply to individual fields to customize their behavior:

- `description` (String?): Custom description for the argument
- `isOptional` (bool?): Whether the argument is optional (defaults to true for nullable fields)
- `constraints` (Map<String, dynamic>?): Constraints like min, max, pattern
- `exclude` (bool): Exclude this field from tool generation (default: false)

Example:

```dart
@GenerateTool()
class GetWeatherModel {
  @GenerateToolArgument(description: 'The city name', isOptional: false)
  final String city;

  @GenerateToolArgument(
    description: 'Number of days to forecast',
    isOptional: true,
    constraints: {'min': 1, 'max': 7},
  )
  final int? days;
}
```

## Supported Types

The generator supports the following Dart types:

- `String` → `ToolArgumentType.string`
- `int` → `ToolArgumentType.integer`
- `double` → `ToolArgumentType.double_`
- `bool` → `ToolArgumentType.boolean`
- `List<T>` → `ToolArgumentType.string` (JSON array representation)
- `Map<K, V>` → `ToolArgumentType.string` (JSON representation)
- Custom types (enums, classes) → `ToolArgumentType.string` (serialized representation)

## Generated Code

The generator creates a file named `{your_class_name}.tool.dart` with a class `{YourClassName}Tool` that extends `BaseTool`.

Example output for `ProductFilterModel`:

```dart
// GENERATED CODE - DO NOT MODIFY MANUALLY
class ProductFilterModelTool extends BaseTool {
  ProductFilterModelTool()
      : super(
          name: 'product_filter_model',
          description: 'Filter products by various criteria',
          arguments: [
            BaseToolArgument(name: 'categoryId', type: ToolArgumentType.string, description: 'Category id', isOptional: true),
            BaseToolArgument(name: 'brandIds', type: ToolArgumentType.string, description: 'Brand ids', isOptional: true),
            // ... more arguments
          ],
        );
}
```

