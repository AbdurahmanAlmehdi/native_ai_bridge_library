import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const siriConfigFileName = 'native_ai_bridge.yaml';

const siriConfigExample = '''
siri:
  input: lib/siri/siri_tools.dart
  swift_out: ios/Runner/Siri/Generated
  skills_out: ios/Runner/Skills.skillsbundle/Skills
  compilation_condition: SIRI_AI_TOOLS
''';

class SiriConfigException implements Exception {
  const SiriConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SiriConfig {
  const SiriConfig({
    required this.input,
    required this.swiftOut,
    required this.skillsOut,
    this.compilationCondition,
  });

  factory SiriConfig.load(String root) {
    final file = File(p.join(root, siriConfigFileName));
    if (!file.existsSync()) {
      throw const SiriConfigException('$siriConfigFileName not found.');
    }
    final Object? document;
    try {
      document = loadYaml(file.readAsStringSync());
    } on YamlException catch (error) {
      throw SiriConfigException(
        '$siriConfigFileName is not valid YAML: ${error.message}',
      );
    }
    final siri = document is YamlMap ? document['siri'] : null;
    if (siri is! YamlMap) {
      throw const SiriConfigException(
        '$siriConfigFileName has no "siri" section.',
      );
    }

    final unknown = siri.keys.where((key) => !_keys.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw SiriConfigException(
        'Unknown keys in the "siri" section: ${unknown.join(', ')}.',
      );
    }

    final condition = _string(siri, 'compilation_condition', required: false);
    if (condition != null &&
        !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(condition)) {
      throw SiriConfigException(
        'compilation_condition "$condition" is not a Swift identifier.',
      );
    }

    return SiriConfig(
      input: _string(siri, 'input')!,
      swiftOut: _string(siri, 'swift_out')!,
      skillsOut: _string(siri, 'skills_out')!,
      compilationCondition: condition,
    );
  }

  static const _keys = {
    'input',
    'swift_out',
    'skills_out',
    'compilation_condition',
  };

  final String input;
  final String swiftOut;
  final String skillsOut;
  final String? compilationCondition;

  static String? _string(YamlMap map, String key, {bool required = true}) {
    final value = map[key];
    if (value == null && !required) return null;
    if (value is! String || value.trim().isEmpty) {
      throw SiriConfigException('"siri.$key" must be a non-empty string.');
    }
    return value.trim();
  }
}
