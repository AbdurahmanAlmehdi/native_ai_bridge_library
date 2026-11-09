## Unreleased

* **BREAKING:** Removed `toolGeneratorBuilder` and `lib/src/tool_generator_builder.dart`. It was never wired into `build.yaml`. Use `toolBuilder` from `package:native_ai_bridge_generator/builder.dart`, which `build.yaml` already uses.
* **BREAKING:** Requires Dart 3.9 or later. Moved to `analyzer >=10.0.0 <15.0.0`, `source_gen ^4.1.2` and `build >=4.0.0 <6.0.0`, so the generator resolves next to current Flutter apps.
* Depends on `native_ai_bridge ^0.2.1` instead of `^0.1.0`.
* Removed the unused `dart_style` dependency and the Flutter dev dependencies. The package is pure Dart and now uses `very_good_analysis`.
* Fixed the homepage, repository and issue tracker links.
* `@GenerateTool` output is unchanged.

## 0.1.0

* Initial release
* Code generator for creating Tool classes from annotated model classes
* Support for `@GenerateTool` annotation on classes
* Support for `@GenerateToolArgument` annotation on fields
* Automatic type mapping from Dart types to ToolArgumentType
* Support for constraints (min, max, enum)
* Support for optional and required arguments
* Support for excluding fields from generation
* Support for custom tool names and descriptions
