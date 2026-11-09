import 'package:native_ai_bridge_generator/src/siri/reader.dart';
import 'package:test/test.dart';

void main() {
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
