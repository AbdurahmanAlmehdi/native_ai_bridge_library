import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/apple_foundation_flutter_method_channel.dart';
import 'package:native_ai_bridge/native_ai_bridge.dart';
import 'package:native_ai_bridge/utils/generation_schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('native_ai_bridge');
  final platform = MethodChannelAppleFoundationFlutter();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  MethodCall? lastCall;

  void respondWith(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      lastCall = call;
      return handler(call);
    });
  }

  tearDown(() {
    lastCall = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('withPropertyOrder', () {
    test('records property order on nested objects and array items', () {
      final schema = withPropertyOrder({
        'type': 'object',
        'properties': {
          'term': {'type': 'string'},
          'price': {
            'type': 'object',
            'properties': {
              'min': {'type': 'number'},
              'max': {'type': 'number'},
            },
          },
          'tags': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'b': {'type': 'string'},
                'a': {'type': 'string'},
              },
            },
          },
        },
      });

      expect(schema['propertyOrder'], ['term', 'price', 'tags']);
      final properties = schema['properties'] as Map;
      expect((properties['price'] as Map)['propertyOrder'], ['min', 'max']);
      expect(
        ((properties['tags'] as Map)['items'] as Map)['propertyOrder'],
        ['b', 'a'],
      );
    });

    test('keeps an explicit propertyOrder', () {
      final schema = withPropertyOrder({
        'type': 'object',
        'propertyOrder': ['b', 'a'],
        'properties': {
          'a': {'type': 'string'},
          'b': {'type': 'string'},
        },
      });

      expect(schema['propertyOrder'], ['b', 'a']);
    });
  });

  group('generateStructured', () {
    test('sends schema, images and options, and decodes the result', () async {
      respondWith((_) async => '{"term":"phone","max":1500}');

      final result = await platform.generateStructured(
        prompt: 'phones under 1500',
        schema: {
          'type': 'object',
          'properties': {
            'term': {'type': 'string'},
            'max': {'type': 'number'},
          },
        },
        instructions: 'Extract filters',
        images: [Uint8List.fromList([1, 2, 3])],
        temperature: 0,
      );

      expect(result, {'term': 'phone', 'max': 1500});
      expect(lastCall!.method, 'generateStructured');
      final args = lastCall!.arguments as Map;
      expect(args['prompt'], 'phones under 1500');
      expect(args['instructions'], 'Extract filters');
      expect(args['temperature'], 0);
      expect((args['schema'] as Map)['propertyOrder'], ['term', 'max']);
      expect((args['images'] as List).single, isA<Uint8List>());
    });

    test('keeps the native error code', () async {
      respondWith(
        (_) async => throw PlatformException(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'Arabic is not supported',
        ),
      );

      expect(
        () => platform.generateStructured(
          prompt: 'هواتف سامسونج',
          schema: {'type': 'object', 'properties': {}},
        ),
        throwsA(
          isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'UNSUPPORTED_LANGUAGE',
          ),
        ),
      );
    });

    test('rejects a non-object response', () async {
      respondWith((_) async => '["a"]');

      expect(
        () => platform.generateStructured(
          prompt: 'x',
          schema: {'type': 'object', 'properties': {}},
        ),
        throwsA(
          isA<AppleFoundationException>().having(
            (e) => e.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
    });

    test('rejects an empty prompt without calling native code', () async {
      respondWith((_) async => '{}');

      await expectLater(
        platform.generateStructured(prompt: '  ', schema: const {}),
        throwsA(isA<AppleFoundationException>()),
      );
      expect(lastCall, isNull);
    });
  });

  group('getCapabilities', () {
    test('parses the native map', () async {
      respondWith(
        (_) async => {
          'available': true,
          'reason': 'Available',
          'vision': true,
          'supportsCurrentLocale': false,
          'supportedLanguages': ['en-Latn-US'],
        },
      );

      final capabilities = await platform.getCapabilities();

      expect(capabilities.available, isTrue);
      expect(capabilities.vision, isTrue);
      expect(capabilities.supportsCurrentLocale, isFalse);
      expect(capabilities.supportedLanguages, ['en-Latn-US']);
    });

    test('reports unsupported platform when no plugin is registered', () async {
      final capabilities = await platform.getCapabilities();

      expect(capabilities.available, isFalse);
      expect(capabilities.code, 'UNSUPPORTED_PLATFORM');
    });
  });
}
