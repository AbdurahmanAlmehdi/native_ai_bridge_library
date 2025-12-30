import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:native_ai_bridge_generator/src/tool_generator.dart';

Builder toolBuilder(BuilderOptions options) => LibraryBuilder(
      ToolGenerator(),
      generatedExtension: '.tool.g.dart',
    );
