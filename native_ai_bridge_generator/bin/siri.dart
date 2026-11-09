import 'dart:io';

import 'package:native_ai_bridge_generator/src/siri/cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await run(args);
}
