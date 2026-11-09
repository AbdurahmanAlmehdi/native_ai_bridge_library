import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/native_ai_bridge.dart';

void main() {
  group('Siri annotations', () {
    test('are exported from the package barrel as const values', () {
      const tool = SiriTool(title: 'Search', description: 'Finds items.');
      const field = SiriField(title: 'Query', description: 'Words to find.');
      const entity = SiriGenerableEntity();
      const skill = SiriSkill(
        name: 'store-search',
        description: 'Helps find items.',
        body: 'Use the search tool.',
      );

      expect(tool.title, 'Search');
      expect(tool.description, 'Finds items.');
      expect(field.title, 'Query');
      expect(field.description, 'Words to find.');
      expect(entity.title, isNull);
      expect(const SiriGenerableEntity(title: 'Filter').title, 'Filter');
      expect(skill.name, 'store-search');
      expect(skill.description, 'Helps find items.');
      expect(skill.body, 'Use the search tool.');
    });
  });
}
