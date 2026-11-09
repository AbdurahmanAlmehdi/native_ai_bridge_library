import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:native_ai_bridge_generator/src/siri/skill_renderer.dart';
import 'package:native_ai_bridge_generator/src/siri/swift_renderer.dart';
import 'package:test/test.dart';

const _location = SourceLocation('lib/siri/siri_tools.dart', 1, 1);

SiriField _field(String name, SiriType type) => SiriField(
  name: name,
  type: type,
  title: 'Title',
  description: 'Description',
  location: _location,
);

void main() {
  group('renderSwift', () {
    const manifest = SiriManifest(
      tools: [
        SiriTool(
          name: 'Ping',
          title: r'Say "hi" \ wave',
          description: 'Line one\nline two',
          parameters: [],
          location: _location,
        ),
      ],
    );

    test('starts every file with the generated header', () {
      final ping = renderSwift(manifest)['Ping.g.swift']!;

      expect(ping.split('\n').first, generatedSwiftHeader);
    });

    test('omits the #if block without a compilation condition', () {
      final ping = renderSwift(manifest)['Ping.g.swift']!;

      expect(ping, isNot(contains('#if')));
      expect(ping, isNot(contains('#endif')));
    });

    test('wraps the file in the compilation condition', () {
      final ping = renderSwift(
        manifest,
        compilationCondition: 'SIRI_AI_TOOLS',
      )['Ping.g.swift']!;

      expect(ping, contains('\n#if SIRI_AI_TOOLS\nimport AppIntents\n'));
      expect(ping, endsWith('}\n#endif\n'));
    });

    test('escapes Swift string literals', () {
      final ping = renderSwift(manifest)['Ping.g.swift']!;

      expect(ping, contains(r'"Say \"hi\" \\ wave"'));
      expect(ping, contains(r'IntentDescription("Line one\nline two")'));
    });

    test('calls a parameterless handler with no arguments', () {
      final ping = renderSwift(manifest)['Ping.g.swift']!;

      expect(ping, contains('func perform() async throws -> String'));
      expect(ping, contains('try await handler.perform()'));
    });

    test('backticks Swift keywords used as parameter names', () {
      final files = renderSwift(
        SiriManifest(
          tools: [
            SiriTool(
              name: 'Move',
              title: 'Move',
              description: 'Moves it.',
              parameters: [
                _field('func', const SiriScalarType(SiriScalar.string)),
              ],
              location: _location,
            ),
          ],
        ),
      );

      expect(files['Move.g.swift'], contains('var `func`: String'));
      expect(files['Move.g.swift'], contains('perform(`func`: String)'));
      expect(files['Move.g.swift'], contains('perform(`func`: `func`)'));
    });

    test('maps every supported type', () {
      final files = renderSwift(
        SiriManifest(
          entities: [
            SiriEntity(
              name: 'Everything',
              title: 'Everything',
              properties: [
                _field('a', const SiriScalarType(SiriScalar.string)),
                _field('b', const SiriScalarType(SiriScalar.integer)),
                _field('c', const SiriScalarType(SiriScalar.decimal)),
                _field('d', const SiriScalarType(SiriScalar.boolean)),
                _field('e', const SiriScalarType(SiriScalar.date)),
                _field('f', const SiriEnumType('Sort')),
                _field('g', const SiriEntityType('Range')),
                _field('h', const SiriListType(SiriEntityType('Range'))),
              ],
              location: _location,
            ),
          ],
        ),
      );

      expect(
        files['Everything.g.swift'],
        stringContainsInOrder([
          'var a: String',
          'var b: Int',
          'var c: Double',
          'var d: Bool',
          'var e: Date',
          'var f: Sort',
          'var g: Range',
          'var h: [Range]',
        ]),
      );
    });
  });

  group('renderSkill', () {
    SiriSkill skill({
      String name = 'store',
      String description = 'Helps.',
      String body = 'Body.\n',
    }) => SiriSkill(
      name: name,
      description: description,
      body: body,
      location: _location,
    );

    test('writes only name and description in the frontmatter', () {
      expect(
        renderSkill(skill()),
        '---\n'
        'name: store\n'
        'description: Helps.\n'
        '---\n'
        '$generatedSkillHeader\n'
        'Body.\n',
      );
    });

    test('quotes a description YAML would misread', () {
      expect(
        renderSkill(skill(description: r'Help: "now" \ later')),
        contains(r'description: "Help: \"now\" \\ later"'),
      );
      expect(
        renderSkill(skill(description: '- starts with a dash')),
        contains('description: "- starts with a dash"'),
      );
      expect(
        renderSkill(skill(description: 'yes')),
        contains('description: "yes"'),
      );
    });

    test('quotes a name YAML would read as another type', () {
      expect(renderSkill(skill(name: 'yes')), contains('name: "yes"\n'));
      expect(renderSkill(skill(name: '2026')), contains('name: "2026"\n'));
      expect(renderSkill(skill()), contains('name: store\n'));
    });
  });

  group('normalizeSkillBody', () {
    test('trims blank lines around the body and ends with a newline', () {
      expect(
        normalizeSkillBody('\n\nFirst.\r\n\nSecond.  \n\n'),
        'First.\n\nSecond.\n',
      );
    });
  });

  group('splitIntoWords', () {
    test('splits camel case into a sentence', () {
      expect(splitIntoWords('priceLowToHigh'), 'Price low to high');
      expect(splitIntoWords('HTTPServer'), 'HTTP server');
    });

    test('splits Pascal case into a title', () {
      expect(
        splitIntoWords('ProductSearch', titleCase: true),
        'Product Search',
      );
    });
  });
}
