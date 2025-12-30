import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'tool_generator.dart';

Builder toolGeneratorBuilder(BuilderOptions options) {
  return LibraryBuilder(ToolGenerator(), generatedExtension: '.tool.dart');
}
