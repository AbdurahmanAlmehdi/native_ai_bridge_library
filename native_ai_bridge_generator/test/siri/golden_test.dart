import 'package:native_ai_bridge_generator/src/siri/reader.dart';
import 'package:native_ai_bridge_generator/src/siri/skill_renderer.dart';
import 'package:native_ai_bridge_generator/src/siri/swift_renderer.dart';
import 'package:native_ai_bridge_generator/src/siri/validator.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late ValidatedSiriManifest manifest;

  setUpAll(() async {
    manifest = validManifest(
      await readSiriManifest(validFixture, root: '.'),
    );
  });

  test('renders the expected Swift files', () {
    final files = renderSwift(manifest, compilationCondition: 'SIRI_AI_TOOLS');

    expect(files.keys, [
      'SearchProducts.g.swift',
      'AddToCart.g.swift',
      'ProductSearch.g.swift',
      'PriceRange.g.swift',
      'ProductSort.g.swift',
    ]);
    files.forEach((name, content) => expectGolden(content, 'swift/$name'));
    expect(goldenFiles('swift'), files.keys.toList()..sort());
  });

  test('renders the expected SKILL.md files', () {
    final files = renderSkills(manifest);

    expect(files.keys, ['store-shopping/SKILL.md', 'order-help/SKILL.md']);
    files.forEach((path, content) => expectGolden(content, 'skills/$path'));
    expect(goldenFiles('skills'), files.keys.toList()..sort());
  });
}
