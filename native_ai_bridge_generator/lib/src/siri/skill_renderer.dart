import 'package:native_ai_bridge_generator/src/siri/manifest.dart';

Map<String, String> renderSkills(SiriManifest manifest) {
  return {
    for (final skill in manifest.skills)
      skillFilePath(skill.name): renderSkill(skill),
  };
}

String renderSkill(SiriSkill skill) {
  return [
    '---',
    'name: ${yamlScalar(skill.name)}',
    'description: ${yamlScalar(skill.description)}',
    '---',
    generatedSkillHeader,
    skill.body,
  ].join('\n');
}

String yamlScalar(String value) {
  if (_isPlainScalar(value)) return value;
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

bool _isPlainScalar(String value) {
  if (value.isEmpty || value != value.trim()) return false;
  if (RegExp(r'''^[-?:,\[\]{}#&*!|>'"%@`]''').hasMatch(value)) return false;
  if (value.contains(': ') || value.contains(' #') || value.endsWith(':')) {
    return false;
  }
  const reserved = {
    'true',
    'false',
    'yes',
    'no',
    'on',
    'off',
    'null',
    '~',
    '.inf',
    '-.inf',
    '.nan',
  };
  if (reserved.contains(value.toLowerCase())) return false;
  return num.tryParse(value) == null;
}
