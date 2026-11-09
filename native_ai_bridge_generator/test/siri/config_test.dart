import 'package:native_ai_bridge_generator/src/siri/config.dart';
import 'package:test/test.dart';

void main() {
  group('SiriConfig.parse', () {
    test('normalizes the output folders', () {
      final config = SiriConfig.parse('''
siri:
  input: lib/siri/siri_tools.dart
  swift_out: ios/Runner/./Siri/Generated/
  skills_out: ios/Runner/Skills.skillsbundle/Skills/
''');

      expect(config.input, 'lib/siri/siri_tools.dart');
      expect(config.swiftOut, 'ios/Runner/Siri/Generated');
      expect(config.skillsOut, 'ios/Runner/Skills.skillsbundle/Skills');
      expect(config.compilationCondition, isNull);
    });

    test('reads the compilation condition', () {
      final config = SiriConfig.parse(siriConfigExample);

      expect(config.compilationCondition, 'SIRI_AI_TOOLS');
    });
  });
}
