import 'package:native_ai_bridge_generator/src/siri/manifest.dart';

const appleFramework = 'AppIntents';
const appleAvailability = '@available(iOS 27.3, *)';
const appleToolMacro = '@AppIntent(.tool)';
const appleIntentProtocol = 'AppIntent';
const appleGenerableEntityMacro = '@AppEntity(.generable)';
const appleTransientEntityProtocol = 'TransientAppEntity';
const appleEnumProtocol = 'AppEnum';
const appleParameterWrapper = '@Parameter';
const applePropertyWrapper = '@Property';
const appleTitleType = 'LocalizedStringResource';
const appleIntentDescription = 'IntentDescription';
const appleTypeDisplayRepresentation = 'TypeDisplayRepresentation';
const appleDisplayRepresentation = 'DisplayRepresentation';
const appleCaseDisplayRepresentations = 'caseDisplayRepresentations';
const appleDialogResult = 'some IntentResult & ProvidesDialog';
const appleTitleRequirement = 'title';
const appleDescriptionRequirement = 'description';
const applePerformRequirement = 'perform';
const appleTypeDisplayRequirement = 'typeDisplayRepresentation';
const appleDisplayRequirement = 'displayRepresentation';
const appleTitleLabel = 'title';
const appleDescriptionLabel = 'description';
const appleSubtitleLabel = 'subtitle';
const appleErrorMessageProtocol = 'CustomLocalizedStringResourceConvertible';
const appleErrorMessageRequirement = 'localizedStringResource';

String appleDialogReturn(String value) =>
    'return .result(dialog: "\\($value)")';

String appleSwiftType(SiriType type) {
  final base = switch (type) {
    SiriScalarType(:final scalar) => switch (scalar) {
      SiriScalar.string => 'String',
      SiriScalar.integer => 'Int',
      SiriScalar.decimal => 'Double',
      SiriScalar.boolean => 'Bool',
      SiriScalar.date => 'Date',
    },
    SiriEnumType(:final name) => name,
    SiriEntityType(:final name) => name,
    SiriListType(:final element) => '[${appleSwiftType(element)}]',
    SiriUnsupportedType(:final reason) => throw StateError(
      'Unsupported types are rejected before rendering: $reason',
    ),
  };
  return type.isOptional ? '$base?' : base;
}

String swiftString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
}

String swiftIdentifier(String name) =>
    _swiftKeywords.contains(name) ? '`$name`' : name;

const _swiftKeywords = {
  'Any',
  'Protocol',
  'Self',
  'Type',
  'as',
  'associatedtype',
  'break',
  'case',
  'catch',
  'class',
  'continue',
  'default',
  'defer',
  'deinit',
  'do',
  'else',
  'enum',
  'extension',
  'fallthrough',
  'false',
  'fileprivate',
  'for',
  'func',
  'guard',
  'if',
  'import',
  'in',
  'init',
  'inout',
  'internal',
  'is',
  'let',
  'nil',
  'open',
  'operator',
  'private',
  'protocol',
  'public',
  'repeat',
  'rethrows',
  'return',
  'self',
  'static',
  'struct',
  'subscript',
  'super',
  'switch',
  'throw',
  'throws',
  'true',
  'try',
  'typealias',
  'var',
  'where',
  'while',
};
