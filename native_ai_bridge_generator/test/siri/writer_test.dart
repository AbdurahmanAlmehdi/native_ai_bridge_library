import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:native_ai_bridge_generator/src/siri/writer.dart';
import 'package:test/test.dart';

void main() {
  group('isGeneratedFile', () {
    test('needs the Swift header on the first line', () {
      expect(
        isGeneratedFile('A.g.swift', '$generatedSwiftHeader\nx\n'),
        isTrue,
      );
      expect(
        isGeneratedFile('A.g.swift', 'x\n$generatedSwiftHeader\n'),
        isFalse,
      );
    });

    test('needs the skill header right after the frontmatter', () {
      expect(
        isGeneratedFile(
          'a/SKILL.md',
          '---\nname: a\n---\n$generatedSkillHeader\nBody.\n',
        ),
        isTrue,
      );
      expect(
        isGeneratedFile(
          'a/SKILL.md',
          '---\nname: a\n---\nQuoting it:\n$generatedSkillHeader\n',
        ),
        isFalse,
      );
      expect(
        isGeneratedFile('a/SKILL.md', '$generatedSkillHeader\nBody.\n'),
        isFalse,
      );
    });
  });
}
