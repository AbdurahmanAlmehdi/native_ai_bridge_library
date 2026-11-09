import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:native_ai_bridge_generator/src/siri/output_files.dart';

enum SiriErrorCode {
  skillName('skill-name'),
  skillDescription('skill-description'),
  skillBody('skill-body'),
  toolMetadata('tool-metadata'),
  unsupportedType('unsupported-type'),
  nameClash('name-clash');

  const SiriErrorCode(this.id);

  final String id;
}

class SiriError {
  const SiriError(this.code, this.message, this.location);

  final SiriErrorCode code;
  final String message;
  final SourceLocation location;

  @override
  String toString() => '$location: error [${code.id}] $message';
}

const skillNameMaxLength = 64;
const skillDescriptionMaxLength = 1024;
const skillBodyMaxLength = 10000;
const int skillBodyBudget =
    skillBodyMaxLength - generatedSkillHeader.length - 1;

final _skillNamePattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

class ValidatedSiriManifest {
  const ValidatedSiriManifest._(this.manifest);

  final SiriManifest manifest;
}

class SiriValidationException implements Exception {
  const SiriValidationException(this.errors);

  final List<SiriError> errors;

  @override
  String toString() => errors.join('\n');
}

ValidatedSiriManifest validManifest(SiriManifest manifest) {
  final errors = validateManifest(manifest);
  if (errors.isNotEmpty) throw SiriValidationException(errors);
  return ValidatedSiriManifest._(manifest);
}

List<SiriError> validateManifest(SiriManifest manifest) {
  return [
    for (final tool in manifest.tools) ..._validateTool(tool),
    for (final entity in manifest.entities) ..._validateEntity(entity),
    for (final siriEnum in manifest.enums) ..._validateEnum(siriEnum),
    ..._validateSkills(manifest.skills),
    ..._validateNames(manifest),
  ];
}

Iterable<SiriError> _validateNames(SiriManifest manifest) sync* {
  final declarations = [
    for (final tool in manifest.tools) (tool.name, tool.location),
    for (final entity in manifest.entities) (entity.name, entity.location),
    for (final siriEnum in manifest.enums) (siriEnum.name, siriEnum.location),
  ];
  final seen = <String>{};
  for (final (name, location) in declarations) {
    if (!seen.add(name)) {
      yield SiriError(
        SiriErrorCode.nameClash,
        '$name is marked both @SiriTool and @SiriGenerableEntity; both would '
        'write ${swiftFileName(name)}. Use one annotation per declaration.',
        location,
      );
    }
  }
}

Iterable<SiriError> _validateTool(SiriToolSpec tool) sync* {
  if (_isBlank(tool.title) || _isBlank(tool.description)) {
    yield SiriError(
      SiriErrorCode.toolMetadata,
      'Tool ${tool.name} needs a non-empty title and description in '
      '@SiriTool.',
      tool.location,
    );
  }
  for (final parameter in tool.parameters) {
    yield* _validateField(
      parameter,
      owner: 'Parameter ${parameter.name} of tool ${tool.name}',
      allowOptional: true,
    );
  }
}

Iterable<SiriError> _validateEntity(SiriEntitySpec entity) sync* {
  if (_isBlank(entity.title)) {
    yield SiriError(
      SiriErrorCode.toolMetadata,
      'Entity ${entity.name} needs a non-empty title in @SiriGenerableEntity.',
      entity.location,
    );
  }
  for (final property in entity.properties) {
    yield* _validateField(
      property,
      owner: 'Property ${property.name} of entity ${entity.name}',
      allowOptional: false,
    );
  }
}

Iterable<SiriError> _validateEnum(SiriEnumSpec siriEnum) sync* {
  if (_isBlank(siriEnum.title)) {
    yield SiriError(
      SiriErrorCode.toolMetadata,
      'Enum ${siriEnum.name} needs a non-empty title in @SiriGenerableEntity.',
      siriEnum.location,
    );
  }
  for (final enumCase in siriEnum.cases) {
    if (_isBlank(enumCase.title) ||
        (enumCase.subtitle != null && _isBlank(enumCase.subtitle))) {
      yield SiriError(
        SiriErrorCode.toolMetadata,
        'Case ${enumCase.name} of enum ${siriEnum.name} needs a non-empty '
        'title and description in @SiriField.',
        enumCase.location,
      );
    }
  }
}

Iterable<SiriError> _validateField(
  SiriFieldSpec field, {
  required String owner,
  required bool allowOptional,
}) sync* {
  if (_isBlank(field.title) || _isBlank(field.description)) {
    yield SiriError(
      SiriErrorCode.toolMetadata,
      '$owner needs @SiriField with a non-empty title and description.',
      field.location,
    );
  }
  final problem = _typeProblem(field.type, allowOptional: allowOptional);
  if (problem != null) {
    yield SiriError(
      SiriErrorCode.unsupportedType,
      '$owner has an unsupported type: $problem. Use String, int, double, '
      'bool, DateTime, an enum or class marked @SiriGenerableEntity, or a '
      'List of these.',
      field.location,
    );
  }
}

String? _typeProblem(SiriType type, {required bool allowOptional}) {
  if (type case SiriUnsupportedType(:final reason)) return reason;
  if (type case SiriListType(:final element, :final isOptional)) {
    if (isOptional) return 'a nullable List';
    if (element is SiriListType) return 'a List of Lists';
    if (element.isOptional) return 'a List of nullable values';
    return _typeProblem(element, allowOptional: false);
  }
  if (type.isOptional && !allowOptional) {
    return 'a nullable type, which generable entities do not accept yet';
  }
  return null;
}

Iterable<SiriError> _validateSkills(List<SiriSkillSpec> skills) sync* {
  final seen = <String>{};
  for (final skill in skills) {
    final name = skill.name;
    if (name.isEmpty ||
        name.length > skillNameMaxLength ||
        !_skillNamePattern.hasMatch(name)) {
      yield SiriError(
        SiriErrorCode.skillName,
        'Skill name "$name" must be 1 to $skillNameMaxLength characters from '
        'a-z, 0-9 and "-", with no leading, trailing or double hyphen.',
        skill.location,
      );
    } else if (!seen.add(name)) {
      yield SiriError(
        SiriErrorCode.skillName,
        'Skill name "$name" is used twice; both would write '
        '$name/SKILL.md.',
        skill.location,
      );
    }

    final description = skill.description;
    if (_isBlank(description) ||
        description.contains('\n') ||
        description.contains('\r') ||
        description.runes.length > skillDescriptionMaxLength) {
      yield SiriError(
        SiriErrorCode.skillDescription,
        'Skill "$name" needs a description on a single line of 1 to '
        '$skillDescriptionMaxLength characters; it has '
        '${description.runes.length}.',
        skill.location,
      );
    }

    final bodyLength = skill.body.trimRight().runes.length;
    if (bodyLength > skillBodyBudget) {
      yield SiriError(
        SiriErrorCode.skillBody,
        'Skill "$name" has a body of $bodyLength characters; the limit is '
        '$skillBodyBudget (Apple allows $skillBodyMaxLength and the generated '
        'header line uses the rest).',
        skill.location,
      );
    }
  }
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;
