import 'package:native_ai_bridge_generator/src/siri/apple_templates.dart';
import 'package:native_ai_bridge_generator/src/siri/manifest.dart';

Map<String, String> renderSwift(
  SiriManifest manifest, {
  String? compilationCondition,
}) {
  String file(List<String> body) =>
      _wrap(body, compilationCondition: compilationCondition);

  return {
    for (final tool in manifest.tools)
      '${tool.name}.g.swift': file(_renderTool(tool)),
    for (final entity in manifest.entities)
      '${entity.name}.g.swift': file(_renderEntity(entity)),
    for (final siriEnum in manifest.enums)
      '${siriEnum.name}.g.swift': file(_renderEnum(siriEnum)),
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

List<String> _renderTool(SiriTool tool) {
  final handler = '${tool.name}Handler';
  final arguments = tool.parameters
      .map((p) => '${p.name}: ${swiftIdentifier(p.name)}')
      .join(', ');
  final description =
      '$appleIntentDescription(${swiftString(tool.description)})';
  final signature = tool.parameters
      .map((p) => '${swiftIdentifier(p.name)}: ${appleSwiftType(p.type)}')
      .join(', ');

  return [
    appleAvailability,
    'protocol $handler: Sendable {',
    '  func perform($signature) async throws -> String',
    '}',
    '',
    appleAvailability,
    appleToolMacro,
    'struct ${tool.name}: $appleIntentProtocol {',
    '  static let title: $appleTitleType = ${swiftString(tool.title)}',
    '  static let description = $description',
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
    '  func perform() async throws -> $appleDialogResult {',
    '    guard let handler = Self.handler else {',
    '      throw HandlerError.notSet',
    '    }',
    '    let reply = try await handler.perform($arguments)',
    r'    return .result(dialog: "\(reply)")',
    '  }',
    '',
    '  enum HandlerError: Error {',
    '    case notSet',
    '  }',
    '}',
  ];
}

List<String> _renderEntity(SiriEntity entity) {
  final typeDisplay =
      'static let typeDisplayRepresentation: '
      '$appleTypeDisplayRepresentation = ${swiftString(entity.title)}';
  return [
    appleAvailability,
    appleGenerableEntityMacro,
    'struct ${entity.name}: $appleTransientEntityProtocol {',
    '  $typeDisplay',
    for (final property in entity.properties) ...[
      '',
      '  $applePropertyWrapper(${_titleAndDescription(property)})',
      '  ${_declaration(property)}',
    ],
    '',
    '  init() {}',
    '',
    '  var displayRepresentation: $appleDisplayRepresentation {',
    '    ${swiftString(entity.title)}',
    '  }',
    '}',
  ];
}

List<String> _renderEnum(SiriEnum siriEnum) {
  final typeDisplay =
      'static let typeDisplayRepresentation: '
      '$appleTypeDisplayRepresentation = ${swiftString(siriEnum.title)}';
  final caseDisplay =
      'static let $appleCaseDisplayRepresentations: '
      '[${siriEnum.name}: $appleDisplayRepresentation] = [';
  return [
    appleAvailability,
    'enum ${siriEnum.name}: String, $appleEnumProtocol {',
    for (final enumCase in siriEnum.cases)
      '  case ${swiftIdentifier(enumCase.name)}',
    '',
    '  $typeDisplay',
    '  $caseDisplay',
    for (final enumCase in siriEnum.cases)
      '    .${swiftIdentifier(enumCase.name)}: ${_caseDisplay(enumCase)},',
    '  ]',
    '}',
  ];
}

String _declaration(SiriField field) =>
    'var ${swiftIdentifier(field.name)}: ${appleSwiftType(field.type)}';

String _titleAndDescription(SiriField field) =>
    'title: ${swiftString(field.title!)}, '
    'description: ${swiftString(field.description!)}';

String _caseDisplay(SiriEnumCase enumCase) {
  final subtitle = enumCase.subtitle;
  if (subtitle == null) return swiftString(enumCase.title);
  return '$appleDisplayRepresentation('
      'title: ${swiftString(enumCase.title)}, '
      'subtitle: ${swiftString(subtitle)})';
}
