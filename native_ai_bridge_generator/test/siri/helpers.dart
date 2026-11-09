import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const validFixture = 'test/siri/fixtures/valid/siri_tools.dart';

String invalidFixture(String name) => 'test/siri/fixtures/invalid/$name.dart';

void expectGolden(String actual, String goldenPath) {
  final file = File(p.join('test/siri/goldens', goldenPath));
  if (Platform.environment['UPDATE_GOLDENS'] == '1' &&
      (!file.existsSync() || file.readAsStringSync() != actual)) {
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(actual);
    fail('Updated golden $goldenPath. Run again without UPDATE_GOLDENS=1.');
  }
  expect(
    file.existsSync(),
    isTrue,
    reason: 'Missing golden $goldenPath. Run with UPDATE_GOLDENS=1.',
  );
  expect(actual, file.readAsStringSync(), reason: 'Golden $goldenPath');
}

List<String> goldenFiles(String folder) {
  final directory = Directory(p.join('test/siri/goldens', folder));
  return [
    for (final entity in directory.listSync(recursive: true))
      if (entity is File)
        p.posix.joinAll(p.split(p.relative(entity.path, from: directory.path))),
  ]..sort();
}

Future<Directory> createApp({
  String config = '''
siri:
  input: lib/siri/siri_tools.dart
  swift_out: ios/Runner/Siri/Generated
  skills_out: ios/Runner/Skills.skillsbundle/Skills
  compilation_condition: SIRI_AI_TOOLS
''',
  String input = validFixture,
}) async {
  final root = Directory.systemTemp.createTempSync('siri_cli_test_');
  addTearDown(() => root.deleteSync(recursive: true));

  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: app\n');
  File(p.join(root.path, 'native_ai_bridge.yaml')).writeAsStringSync(config);
  File(p.join(root.path, 'lib/siri/siri_tools.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(File(input).readAsStringSync());
  File(p.join(root.path, '.dart_tool/package_config.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync(await _absolutePackageConfig());
  return root;
}

Future<String> _absolutePackageConfig() async {
  final configUri = (await Isolate.packageConfig)!;
  final json =
      jsonDecode(File.fromUri(configUri).readAsStringSync())
          as Map<String, dynamic>;
  final packages = [
    for (final package in json['packages'] as List<dynamic>)
      {
        ...package as Map<String, dynamic>,
        'rootUri': configUri.resolve(package['rootUri'] as String).toString(),
      },
  ];
  return jsonEncode({...json, 'packages': packages});
}
