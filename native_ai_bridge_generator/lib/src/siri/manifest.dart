class SourceLocation {
  const SourceLocation(this.path, this.line, this.column);

  final String path;
  final int line;
  final int column;

  @override
  String toString() => '$path:$line:$column';
}

enum SiriScalar { string, integer, decimal, boolean, date }

sealed class SiriType {
  const SiriType({required this.isOptional});

  final bool isOptional;
}

class SiriScalarType extends SiriType {
  const SiriScalarType(this.scalar, {super.isOptional = false});

  final SiriScalar scalar;
}

class SiriEnumType extends SiriType {
  const SiriEnumType(this.name, {super.isOptional = false});

  final String name;
}

class SiriEntityType extends SiriType {
  const SiriEntityType(this.name, {super.isOptional = false});

  final String name;
}

class SiriListType extends SiriType {
  const SiriListType(this.element, {super.isOptional = false});

  final SiriType element;
}

class SiriUnsupportedType extends SiriType {
  const SiriUnsupportedType(this.reason, {super.isOptional = false});

  final String reason;
}

class SiriFieldSpec {
  const SiriFieldSpec({
    required this.name,
    required this.type,
    required this.location,
    this.title,
    this.description,
  });

  final String name;
  final SiriType type;
  final SourceLocation location;
  final String? title;
  final String? description;
}

class SiriToolSpec {
  const SiriToolSpec({
    required this.name,
    required this.title,
    required this.description,
    required this.parameters,
    required this.location,
  });

  final String name;
  final String title;
  final String description;
  final List<SiriFieldSpec> parameters;
  final SourceLocation location;
}

class SiriEntitySpec {
  const SiriEntitySpec({
    required this.name,
    required this.title,
    required this.properties,
    required this.location,
  });

  final String name;
  final String title;
  final List<SiriFieldSpec> properties;
  final SourceLocation location;
}

class SiriEnumCaseSpec {
  const SiriEnumCaseSpec({
    required this.name,
    required this.title,
    required this.location,
    this.subtitle,
  });

  final String name;
  final String title;
  final String? subtitle;
  final SourceLocation location;
}

class SiriEnumSpec {
  const SiriEnumSpec({
    required this.name,
    required this.title,
    required this.cases,
    required this.location,
  });

  final String name;
  final String title;
  final List<SiriEnumCaseSpec> cases;
  final SourceLocation location;
}

class SiriSkillSpec {
  const SiriSkillSpec({
    required this.name,
    required this.description,
    required this.body,
    required this.location,
  });

  final String name;
  final String description;
  final String body;
  final SourceLocation location;
}

class SiriManifest {
  const SiriManifest({
    this.tools = const [],
    this.entities = const [],
    this.enums = const [],
    this.skills = const [],
  });

  final List<SiriToolSpec> tools;
  final List<SiriEntitySpec> entities;
  final List<SiriEnumSpec> enums;
  final List<SiriSkillSpec> skills;
}
