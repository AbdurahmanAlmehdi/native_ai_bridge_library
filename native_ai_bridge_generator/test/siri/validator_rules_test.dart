import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:native_ai_bridge_generator/src/siri/output_files.dart';
import 'package:native_ai_bridge_generator/src/siri/validator.dart';
import 'package:test/test.dart';

const _location = SourceLocation('lib/siri/siri_tools.dart', 3, 7);

SiriSkillSpec _skill({
  String name = 'store',
  String description = 'Helps.',
  String body = 'Body.\n',
}) => SiriSkillSpec(
  name: name,
  description: description,
  body: body,
  location: _location,
);

SiriFieldSpec _field(
  SiriType type, {
  String? title = 'T',
  String? description,
}) => SiriFieldSpec(
  name: 'value',
  type: type,
  title: title,
  description: description ?? 'D',
  location: _location,
);

SiriToolSpec _tool(List<SiriFieldSpec> parameters, {String name = 'Search'}) =>
    SiriToolSpec(
      name: name,
      title: 'Search',
      description: 'Finds things.',
      parameters: parameters,
      location: _location,
    );

SiriEntitySpec _entity(
  List<SiriFieldSpec> properties, {
  String name = 'Filter',
  String title = 'Filter',
}) => SiriEntitySpec(
  name: name,
  title: title,
  properties: properties,
  location: _location,
);

List<String> _codes(SiriManifest manifest) =>
    validateManifest(manifest).map((error) => error.code.id).toList();

void main() {
  group('skill-name', () {
    test('accepts exactly 64 characters and rejects 65', () {
      expect(_codes(SiriManifest(skills: [_skill(name: 'a' * 64)])), isEmpty);
      expect(_codes(SiriManifest(skills: [_skill(name: 'a' * 65)])), [
        'skill-name',
      ]);
    });

    test('rejects leading, trailing and double hyphens and empty names', () {
      for (final name in ['-store', 'store-', 'st--ore', '', 'Store']) {
        expect(
          _codes(SiriManifest(skills: [_skill(name: name)])),
          ['skill-name'],
          reason: name,
        );
      }
    });
  });

  group('skill-description', () {
    test('accepts exactly 1024 characters and rejects 1025', () {
      expect(
        _codes(SiriManifest(skills: [_skill(description: 'a' * 1024)])),
        isEmpty,
      );
      expect(
        _codes(SiriManifest(skills: [_skill(description: 'a' * 1025)])),
        ['skill-description'],
      );
    });

    test('rejects a blank description', () {
      expect(_codes(SiriManifest(skills: [_skill(description: '  ')])), [
        'skill-description',
      ]);
    });
  });

  group('skill-body', () {
    test('accepts a body at the budget and rejects one past it', () {
      expect(
        _codes(
          SiriManifest(skills: [_skill(body: '${'a' * skillBodyBudget}\n')]),
        ),
        isEmpty,
      );
      expect(
        _codes(
          SiriManifest(
            skills: [_skill(body: '${'a' * (skillBodyBudget + 1)}\n')],
          ),
        ),
        ['skill-body'],
      );
    });

    test('leaves room for the generated header within Apple limit', () {
      expect(
        skillBodyBudget + generatedSkillHeader.length + 1,
        skillBodyMaxLength,
      );
    });
  });

  group('tool-metadata', () {
    test('flags a blank entity title', () {
      expect(_codes(SiriManifest(entities: [_entity([], title: ' ')])), [
        'tool-metadata',
      ]);
    });

    test('flags a blank enum title and blank case metadata', () {
      final errors = validateManifest(
        const SiriManifest(
          enums: [
            SiriEnumSpec(
              name: 'Sort',
              title: '',
              cases: [
                SiriEnumCaseSpec(name: 'a', title: '', location: _location),
                SiriEnumCaseSpec(
                  name: 'b',
                  title: 'B',
                  subtitle: ' ',
                  location: _location,
                ),
                SiriEnumCaseSpec(name: 'c', title: 'C', location: _location),
              ],
              location: _location,
            ),
          ],
        ),
      );

      const caseRule = 'needs a non-empty title and description in @SiriField.';
      expect(errors.map((error) => error.message), [
        'Enum Sort needs a non-empty title in @SiriGenerableEntity.',
        'Case a of enum Sort $caseRule',
        'Case b of enum Sort $caseRule',
      ]);
    });

    test('flags an entity property without @SiriField', () {
      expect(
        _codes(
          SiriManifest(
            entities: [
              _entity([
                _field(const SiriScalarType(SiriScalar.string), title: null),
              ]),
            ],
          ),
        ),
        ['tool-metadata'],
      );
    });
  });

  group('unsupported-type', () {
    String message(SiriType type) => validateManifest(
      SiriManifest(
        tools: [
          _tool([_field(type)]),
        ],
      ),
    ).single.message;

    test('rejects a List of Lists', () {
      expect(
        message(
          const SiriListType(SiriListType(SiriScalarType(SiriScalar.string))),
        ),
        contains('unsupported type: a List of Lists.'),
      );
    });

    test('rejects a List of nullable values', () {
      expect(
        message(
          const SiriListType(
            SiriScalarType(SiriScalar.string, isOptional: true),
          ),
        ),
        contains('unsupported type: a List of nullable values.'),
      );
    });

    test('accepts nullable scalars, enums and entities on tools', () {
      expect(
        _codes(
          SiriManifest(
            tools: [
              _tool([
                _field(const SiriScalarType(SiriScalar.date, isOptional: true)),
                _field(const SiriEnumType('Sort', isOptional: true)),
                _field(const SiriEntityType('Filter', isOptional: true)),
                _field(const SiriListType(SiriEntityType('Filter'))),
              ]),
            ],
          ),
        ),
        isEmpty,
      );
    });
  });

  group('name-clash', () {
    test('rejects a tool and an entity with the same name', () {
      final errors = validateManifest(
        SiriManifest(
          tools: [_tool([])],
          entities: [_entity([], name: 'Search')],
        ),
      );

      const message =
          'lib/siri/siri_tools.dart:3:7: error [name-clash] Search is marked '
          'both @SiriTool and @SiriGenerableEntity; both would write '
          'Search.g.swift. Use one annotation per declaration.';
      expect(errors.map((error) => '$error'), [message]);
    });
  });
}
