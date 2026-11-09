import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/native_ai_bridge.dart';

void main() {
  group('Siri annotations', () {
    test('can annotate declarations as const values from the barrel', () {
      const annotations = <Object>[
        SiriTool(title: 'Search', description: 'Finds items.'),
        SiriField(title: 'Query', description: 'Words to find.'),
        SiriGenerableEntity(),
        SiriSkill(name: 'store', description: 'Helps.', body: 'Body.'),
      ];

      expect(annotations, hasLength(4));
    });

    test('SiriGenerableEntity title is optional', () {
      expect(const SiriGenerableEntity().title, isNull);
      expect(const SiriGenerableEntity(title: 'Filter').title, 'Filter');
    });
  });
}
