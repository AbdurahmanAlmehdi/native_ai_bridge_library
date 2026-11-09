import 'package:native_ai_bridge_generator/src/siri/apple_templates.dart';
import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:native_ai_bridge_generator/src/siri/output_files.dart';
import 'package:native_ai_bridge_generator/src/siri/validator.dart';

Map<String, String> renderSwift(
  ValidatedSiriManifest validated, {
  String? compilationCondition,
}) {
  final manifest = validated.manifest;
  String file(List<String> body) =>
      _wrap(body, compilationCondition: compilationCondition);

  return {
    for (final tool in manifest.tools)
      swiftFileName(tool.name): file(_renderTool(tool)),
    for (final entity in manifest.entities)
      swiftFileName(entity.name): file(_renderEntity(entity)),
    for (final siriEnum in manifest.enums)
      swiftFileName(siriEnum.name): file(_renderEnum(siriEnum)),
  };
}

String _wrap(List<String> body, {String? compilationCondition}) {
  return [
    generatedSwiftHeader,
    '',
    if (compilationCondition != null) '#if $compilationCondition',
    'import $appleFramework',
    '',
    ...body,
    if (compilationCondition != null) '#endif',
    '',
  ].join('\n');
}

List<String> _renderTool(SiriToolSpec tool) {
  final handler = '${tool.name}Handler';
  final arguments = tool.parameters
      .map((p) => '${swiftIdentifier(p.name)}: ${swiftIdentifier(p.name)}')
      .join(', ');
  final title =
      'static let $appleTitleRequirement: $appleTitleType = '
      '${swiftString(tool.title)}';
  final description =
      '$appleIntentDescription(${swiftString(tool.description)})';
  final signature = tool.parameters
      .map((p) => '${swiftIdentifier(p.name)}: ${appleSwiftType(p.type)}')
      .join(', ');

  return [
    appleAvailability,
    'protocol $handler: Sendable {',
    '  func $applePerformRequirement($signature) async throws -> String',
    '}',
    '',
    appleAvailability,
    appleToolMacro,
    'struct ${tool.name}: $appleIntentProtocol {',
    '  $title',
    '  static let $appleDescriptionRequirement = $description',
    '',
    '  nonisolated(unsafe) static var handler: (any $handler)?',
    for (final parameter in tool.parameters) ...[
      '',
      '  $appleParameterWrapper(${_titleAndDescription(parameter)})',
      '  ${_declaration(parameter)}',
    ],
    '',
    '  init() {}',
    '',
    '  func $applePerformRequirement() async throws -> $appleDialogResult {',
    '    guard let handler = Self.handler else {',
    '      throw HandlerError.notSet',
    '    }',
    '    let reply = try await handler.$applePerformRequirement($arguments)',
    '    ${appleDialogReturn('reply')}',
    '  }',
    '',
    '  enum HandlerError: Error, $appleErrorMessageProtocol {',
    '    case notSet',
    '',
    '    var $appleErrorMessageRequirement: $appleTitleType {',
    '      ${swiftString('${tool.title} is not set up in this app yet.')}',
    '    }',
    '  }',
    '}',
  ];
}

List<String> _renderEntity(SiriEntitySpec entity) {
  return [
    appleAvailability,
    appleGenerableEntityMacro,
    'struct ${entity.name}: $appleTransientEntityProtocol {',
    '  ${_typeDisplay(entity.title)}',
    for (final property in entity.properties) ...[
      '',
      '  $applePropertyWrapper(${_titleAndDescription(property)})',
      '  ${_declaration(property)}',
    ],
    '',
    '  init() {}',
    '',
    '  var $appleDisplayRequirement: $appleDisplayRepresentation {',
    '    ${swiftString(entity.title)}',
    '  }',
    '}',
  ];
}

List<String> _renderEnum(SiriEnumSpec siriEnum) {
  final caseDisplay =
      'static let $appleCaseDisplayRepresentations: '
      '[${siriEnum.name}: $appleDisplayRepresentation] = [';
  return [
    appleAvailability,
    'enum ${siriEnum.name}: String, $appleEnumProtocol {',
    for (final enumCase in siriEnum.cases)
      '  case ${swiftIdentifier(enumCase.name)}',
    '',
    '  ${_typeDisplay(siriEnum.title)}',
    '  $caseDisplay',
    for (final enumCase in siriEnum.cases)
      '    .${swiftIdentifier(enumCase.name)}: ${_caseDisplay(enumCase)},',
    '  ]',
    '}',
  ];
}

String _typeDisplay(String title) =>
    'static let $appleTypeDisplayRequirement: '
    '$appleTypeDisplayRepresentation = ${swiftString(title)}';

String _declaration(SiriFieldSpec field) =>
    'var ${swiftIdentifier(field.name)}: ${appleSwiftType(field.type)}';

String _titleAndDescription(SiriFieldSpec field) =>
    '$appleTitleLabel: ${swiftString(field.title!)}, '
    '$appleDescriptionLabel: ${swiftString(field.description!)}';

String _caseDisplay(SiriEnumCaseSpec enumCase) {
  final subtitle = enumCase.subtitle;
  if (subtitle == null) return swiftString(enumCase.title);
  return '$appleDisplayRepresentation('
      '$appleTitleLabel: ${swiftString(enumCase.title)}, '
      '$appleSubtitleLabel: ${swiftString(subtitle)})';
}
