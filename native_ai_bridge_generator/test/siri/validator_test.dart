import 'package:native_ai_bridge_generator/src/siri/reader.dart';
import 'package:native_ai_bridge_generator/src/siri/validator.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Future<List<String>> _errors(String fixture) async {
  final manifest = await readSiriManifest(
    invalidFixture(fixture),
    root: '.',
  );
  return validateManifest(manifest).map((error) => '$error').toList();
}

String _error(
  String fixture,
  int line,
  int column,
  String code,
  String message,
) => '${invalidFixture(fixture)}:$line:$column: error [$code] $message';

void main() {
  test('skill-name rejects bad characters and duplicate names', () async {
    expect(await _errors('skill_name'), [
      _error(
        'skill_name',
        4,
        22,
        'skill-name',
        'Skill name "Store--Shopping" must be 1 to 64 characters from '
            'a-z, 0-9 and "-", with no leading, trailing or double hyphen.',
      ),
      _error(
        'skill_name',
        10,
        22,
        'skill-name',
        'Skill name "store" is used twice; both would write '
            'store/SKILL.md.',
      ),
    ]);
  });

  test('skill-description rejects a multi-line description', () async {
    expect(await _errors('skill_description'), [
      _error(
        'skill_description',
        8,
        22,
        'skill-description',
        'Skill "store" needs a description on a '
            'single line of 1 to 1024 characters; it has 36.',
      ),
    ]);
  });

  test('skill-body rejects a body over the limit', () async {
    expect(await _errors('skill_body'), [
      _error(
        'skill_body',
        87,
        22,
        'skill-body',
        'Skill "store" has a body of 10124 characters; the '
            'limit is $skillBodyBudget (Apple allows 10000 and the generated '
            'header line uses the rest).',
      ),
    ]);
  });

  test('tool-metadata requires titles and descriptions', () async {
    expect(await _errors('tool_metadata'), [
      _error(
        'tool_metadata',
        4,
        7,
        'tool-metadata',
        'Tool Search needs a non-empty title and '
            'description in @SiriTool.',
      ),
      _error(
        'tool_metadata',
        5,
        21,
        'tool-metadata',
        'Parameter query of tool Search needs @SiriField '
            'with a non-empty title and description.',
      ),
      _error(
        'tool_metadata',
        8,
        18,
        'tool-metadata',
        'Parameter limit of tool Search needs @SiriField '
            'with a non-empty title and description.',
      ),
    ]);
  });

  test('unsupported-type rejects types Siri cannot generate', () async {
    const supported =
        'Use String, int, double, bool, DateTime, an enum or class marked '
        '@SiriGenerableEntity, or a List of these.';
    expect(await _errors('unsupported_type'), [
      _error(
        'unsupported_type',
        6,
        34,
        'unsupported-type',
        'Parameter filters of tool Search has an '
            'unsupported type: Map<String, String>. $supported',
      ),
      _error(
        'unsupported_type',
        9,
        31,
        'unsupported-type',
        'Parameter range of tool Search has an '
            'unsupported type: a record (double, double). $supported',
      ),
      _error(
        'unsupported_type',
        12,
        22,
        'unsupported-type',
        'Parameter anything of tool Search has an '
            'unsupported type: dynamic. $supported',
      ),
      _error(
        'unsupported_type',
        15,
        28,
        'unsupported-type',
        'Parameter tags of tool Search has an '
            'unsupported type: a nullable List. $supported',
      ),
      _error(
        'unsupported_type',
        18,
        20,
        'unsupported-type',
        'Parameter store of tool Search has an '
            'unsupported type: Store, which is not marked '
            '@SiriGenerableEntity. $supported',
      ),
      _error(
        'unsupported_type',
        26,
        22,
        'unsupported-type',
        'Property brand of entity Filter has an '
            'unsupported type: a nullable type, which generable entities do '
            'not accept yet. $supported',
      ),
    ]);
  });

  test('unsupported-type rejects an entity from another library', () async {
    final manifest = await readSiriManifest(
      'test/siri/fixtures/cross_library/siri_tools.dart',
      root: '.',
    );

    const message =
        'test/siri/fixtures/cross_library/siri_tools.dart:8:21: error '
        '[unsupported-type] Parameter filter of tool Search has an '
        'unsupported type: Filter, which is declared outside the input '
        'library. Use String, int, double, bool, DateTime, an enum or '
        'class marked @SiriGenerableEntity, or a List of these.';
    expect(validateManifest(manifest).map((error) => '$error'), [message]);
  });
}
