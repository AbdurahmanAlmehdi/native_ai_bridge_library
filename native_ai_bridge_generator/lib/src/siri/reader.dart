import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:native_ai_bridge_generator/src/siri/output_files.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

const _annotationsUrl =
    'package:native_ai_bridge/annotations/siri_annotations.dart';
const _toolChecker = TypeChecker.fromUrl('$_annotationsUrl#SiriTool');
const _fieldChecker = TypeChecker.fromUrl('$_annotationsUrl#SiriField');
const _entityChecker = TypeChecker.fromUrl(
  '$_annotationsUrl#SiriGenerableEntity',
);
const _skillChecker = TypeChecker.fromUrl('$_annotationsUrl#SiriSkill');

class SiriReadException implements Exception {
  const SiriReadException(this.messages);

  final List<String> messages;

  @override
  String toString() => messages.join('\n');
}

Future<SiriManifest> readSiriManifest(
  String inputPath, {
  required String root,
}) async {
  final absolute = p.normalize(p.absolute(root, inputPath));
  final collection = AnalysisContextCollection(includedPaths: [absolute]);
  try {
    final result = await collection
        .contextFor(absolute)
        .currentSession
        .getResolvedLibrary(absolute);
    if (result is! ResolvedLibraryResult) {
      final path = _relative(absolute, root);
      throw SiriReadException([
        '$path: could not be resolved as a Dart library.',
      ]);
    }

    final errors = [
      for (final unit in result.units)
        for (final diagnostic in unit.diagnostics)
          if (diagnostic.severity == Severity.error)
            _formatDiagnostic(unit, diagnostic, root),
    ];
    if (errors.isNotEmpty) throw SiriReadException(errors);

    return _ManifestReader(result.element, root).read();
  } finally {
    await collection.dispose();
  }
}

class _ManifestReader {
  _ManifestReader(this.library, this.root);

  final LibraryElement library;
  final String root;

  SiriManifest read() {
    return SiriManifest(
      tools: [
        for (final element in library.classes)
          if (_toolChecker.firstAnnotationOfExact(element) case final tool?)
            _readTool(element, ConstantReader(tool)),
      ],
      entities: [
        for (final element in library.classes)
          if (_entityChecker.firstAnnotationOfExact(element) case final entity?)
            _readEntity(element, ConstantReader(entity)),
      ],
      enums: [
        for (final element in library.enums)
          if (_entityChecker.firstAnnotationOfExact(element) case final entity?)
            _readEnum(element, ConstantReader(entity)),
      ],
      skills: [
        for (final annotated in LibraryReader(
          library,
        ).annotatedWith(_skillChecker))
          _readSkill(annotated.element, annotated.annotation),
      ],
    );
  }

  SiriToolSpec _readTool(ClassElement element, ConstantReader annotation) {
    return SiriToolSpec(
      name: element.displayName,
      title: annotation.read('title').stringValue,
      description: annotation.read('description').stringValue,
      parameters: _readFields(element),
      location: _locate(element),
    );
  }

  SiriEntitySpec _readEntity(ClassElement element, ConstantReader annotation) {
    return SiriEntitySpec(
      name: element.displayName,
      title: _typeTitle(element, annotation),
      properties: _readFields(element),
      location: _locate(element),
    );
  }

  SiriEnumSpec _readEnum(EnumElement element, ConstantReader annotation) {
    return SiriEnumSpec(
      name: element.displayName,
      title: _typeTitle(element, annotation),
      cases: [
        for (final constant in element.constants) _readEnumCase(constant),
      ],
      location: _locate(element),
    );
  }

  SiriEnumCaseSpec _readEnumCase(FieldElement constant) {
    final field = _fieldChecker.firstAnnotationOfExact(constant);
    final reader = field == null ? null : ConstantReader(field);
    return SiriEnumCaseSpec(
      name: constant.displayName,
      title:
          reader?.read('title').stringValue ??
          splitIntoWords(constant.displayName),
      subtitle: reader?.read('description').stringValue,
      location: _locate(constant),
    );
  }

  SiriSkillSpec _readSkill(Element element, ConstantReader annotation) {
    return SiriSkillSpec(
      name: annotation.read('name').stringValue,
      description: annotation.read('description').stringValue,
      body: normalizeSkillBody(annotation.read('body').stringValue),
      location: _locate(element),
    );
  }

  String _typeTitle(Element element, ConstantReader annotation) {
    final title = annotation.read('title');
    return title.isNull
        ? splitIntoWords(element.displayName, titleCase: true)
        : title.stringValue;
  }

  List<SiriFieldSpec> _readFields(ClassElement element) {
    return [
      for (final field in element.fields)
        if (!field.isStatic && field.isOriginDeclaration) _readField(field),
    ];
  }

  SiriFieldSpec _readField(FieldElement field) {
    final annotation = _fieldChecker.firstAnnotationOfExact(field);
    final reader = annotation == null ? null : ConstantReader(annotation);
    return SiriFieldSpec(
      name: field.displayName,
      type: _mapType(field.type),
      title: reader?.read('title').stringValue,
      description: reader?.read('description').stringValue,
      location: _locate(field),
    );
  }

  SiriType _mapType(DartType type) {
    final isOptional = type.nullabilitySuffix == NullabilitySuffix.question;
    final scalar = type.isDartCoreString
        ? SiriScalar.string
        : type.isDartCoreInt
        ? SiriScalar.integer
        : type.isDartCoreDouble
        ? SiriScalar.decimal
        : type.isDartCoreBool
        ? SiriScalar.boolean
        : null;
    if (scalar != null) return SiriScalarType(scalar, isOptional: isOptional);
    if (type is RecordType) {
      return SiriUnsupportedType(
        'a record ${type.getDisplayString()}',
        isOptional: isOptional,
      );
    }
    if (type is! InterfaceType) {
      return SiriUnsupportedType(
        type.getDisplayString(),
        isOptional: isOptional,
      );
    }

    final element = type.element;
    if (element.library.isDartCore && element.displayName == 'DateTime') {
      return SiriScalarType(SiriScalar.date, isOptional: isOptional);
    }
    if (type.isDartCoreList) {
      return SiriListType(
        _mapType(type.typeArguments.single),
        isOptional: isOptional,
      );
    }
    if (_entityChecker.hasAnnotationOfExact(element)) {
      if (element.library != library) {
        return SiriUnsupportedType(
          '${element.displayName}, which is declared outside the input '
          'library',
          isOptional: isOptional,
        );
      }
      if (element is EnumElement) {
        return SiriEnumType(element.displayName, isOptional: isOptional);
      }
      if (element is ClassElement) {
        return SiriEntityType(element.displayName, isOptional: isOptional);
      }
    }
    final name = type.getDisplayString();
    return SiriUnsupportedType(
      element is EnumElement || element is ClassElement && !type.isDartCoreMap
          ? '$name, which is not marked @SiriGenerableEntity'
          : name,
      isOptional: isOptional,
    );
  }

  SourceLocation _locate(Element element) {
    final fragment = element.firstFragment;
    final unit = fragment.libraryFragment!;
    final location = unit.lineInfo.getLocation(
      fragment.nameOffset ?? fragment.offset,
    );
    return SourceLocation(
      _relative(unit.source.fullName, root),
      location.lineNumber,
      location.columnNumber,
    );
  }
}

String _formatDiagnostic(
  ResolvedUnitResult unit,
  Diagnostic diagnostic,
  String root,
) {
  final location = unit.lineInfo.getLocation(
    diagnostic.offset,
  );
  final where =
      '${_relative(unit.path, root)}:${location.lineNumber}:'
      '${location.columnNumber}';
  return '$where: error [dart] ${diagnostic.message}';
}

String _relative(String path, String root) =>
    p.posix.joinAll(p.split(p.relative(path, from: p.absolute(root))));

String splitIntoWords(String identifier, {bool titleCase = false}) {
  final words = identifier
      .replaceAll(RegExp('^_+'), '')
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])|([A-Z])([A-Z][a-z])'),
        (m) => m[1] != null ? '${m[1]} ${m[2]}' : '${m[3]} ${m[4]}',
      )
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return identifier;
  return [
    _capitalize(words.first),
    for (final word in words.skip(1))
      if (titleCase)
        _capitalize(word)
      else if (word == word.toUpperCase())
        word
      else
        word.toLowerCase(),
  ].join(' ');
}

String _capitalize(String word) => word[0].toUpperCase() + word.substring(1);
