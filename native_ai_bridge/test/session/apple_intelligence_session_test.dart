import 'package:flutter_test/flutter_test.dart';
import 'package:native_ai_bridge/session/apple_intelligence_session.dart';
import 'package:native_ai_bridge/apple_foundation_flutter_platform_interface.dart';
import 'package:native_ai_bridge/enums/styles.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppleFoundationFlutterPlatform extends AppleFoundationFlutterPlatform
    with MockPlatformInterfaceMixin {
  final Map<String, bool> _sessions = {};
  int _sessionCounter = 0;

  @override
  Future<String> openSession(
    String instructions, {
    Map? toolHandlers,
  }) async {
    final sessionId = 'session_${_sessionCounter++}';
    _sessions[sessionId] = true;
    return sessionId;
  }

  @override
  Future<void> closeSession(String sessionId) async {
    _sessions.remove(sessionId);
  }

  @override
  Future<String?> ask(String prompt, {String? sessionId}) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return 'Response to: $prompt';
  }

  @override
  Future<Map<String, dynamic>> getStructuredData(
    String prompt, {
    String? sessionId,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return {'key': 'value'};
  }

  @override
  Future<List<String>> getListOfString(
    String prompt, {
    String? sessionId,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return ['item1', 'item2', 'item3'];
  }

  @override
  Future<String?> generateText(
    String prompt, {
    String? sessionId,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return 'Generated: $prompt';
  }

  @override
  Future<List<String>> generateAlternatives(
    String prompt, {
    String? sessionId,
    int count = 3,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return List.generate(count, (i) => 'Alternative ${i + 1}');
  }

  @override
  Future<String?> summarizeText(
    String text, {
    String? sessionId,
    SummarizationStyle style = SummarizationStyle.concise,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return 'Summary of: $text';
  }

  @override
  Future<Map<String, dynamic>> extractInformation(
    String text, {
    String? sessionId,
    List<String>? fields,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return {'extracted': 'data'};
  }

  @override
  Future<Map<String, double>> classifyText(
    String text, {
    String? sessionId,
    List<String>? categories,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return {'positive': 0.8, 'negative': 0.2};
  }

  @override
  Future<List<String>> generateSuggestions(
    String context, {
    String? sessionId,
    int maxSuggestions = 5,
  }) async {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return List.generate(
      maxSuggestions,
      (i) => 'Suggestion ${i + 1}',
    );
  }

  @override
  Stream<String> generateTextStream(
    String prompt, {
    String? sessionId,
  }) {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return Stream.fromIterable(['chunk1', 'chunk2', 'chunk3']);
  }

  @override
  Stream<String> getStructuredDataStream(
    String prompt, {
    String? sessionId,
  }) {
    if (sessionId != null && !_sessions.containsKey(sessionId)) {
      throw Exception('Session not found');
    }
    return Stream.value('{"key": "value"}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleIntelligenceSession', () {
    late MockAppleFoundationFlutterPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockAppleFoundationFlutterPlatform();
      AppleFoundationFlutterPlatform.instance = mockPlatform;
    });

    group('create', () {
      test('should create a new session', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        expect(session, isNotNull);
        expect(session.isActive, true);
        expect(session.sessionId, isNotEmpty);
      });

      test('should create multiple independent sessions', () async {
        final session1 = await AppleIntelligenceSession.create(
          'You are a technical expert',
        );
        final session2 = await AppleIntelligenceSession.create(
          'You are a storyteller',
        );

        expect(session1.sessionId, isNot(equals(session2.sessionId)));
        expect(session1.isActive, true);
        expect(session2.isActive, true);
      });
    });

    group('close', () {
      test('should close the session', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        expect(session.isActive, true);

        await session.close();

        expect(session.isActive, false);
      });

      test('should handle multiple close calls gracefully', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        await session.close();
        await session.close();

        expect(session.isActive, false);
      });
    });

    group('ask', () {
      test('should ask a question', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final response = await session.ask('What is AI?');

        expect(response, contains('What is AI?'));
        await session.close();
      });

      test('should throw error when session is closed', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        await session.close();

        expect(
          () => session.ask('What is AI?'),
          throwsStateError,
        );
      });
    });

    group('getStructuredData', () {
      test('should get structured data', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final data = await session.getStructuredData('Create a profile');

        expect(data, isA<Map<String, dynamic>>());
        expect(data, isNotEmpty);
        await session.close();
      });

      test('should throw error when session is closed', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        await session.close();

        expect(
          () => session.getStructuredData('Create a profile'),
          throwsStateError,
        );
      });
    });

    group('getListOfString', () {
      test('should get list of strings', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final list = await session.getListOfString('Give me a list');

        expect(list, isA<List<String>>());
        expect(list.length, 3);
        await session.close();
      });
    });

    group('generateText', () {
      test('should generate text', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final text = await session.generateText('Tell me a story');

        expect(text, isNotNull);
        expect(text, contains('Tell me a story'));
        await session.close();
      });
    });

    group('generateAlternatives', () {
      test('should generate alternatives with default count', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final alternatives = await session.generateAlternatives('Rewrite this');

        expect(alternatives, isA<List<String>>());
        expect(alternatives.length, 3);
        await session.close();
      });

      test('should generate alternatives with custom count', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final alternatives =
            await session.generateAlternatives('Rewrite this', count: 5);

        expect(alternatives.length, 5);
        await session.close();
      });
    });

    group('summarizeText', () {
      test('should summarize text with default style', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final summary = await session.summarizeText('Long text here...');

        expect(summary, isNotNull);
        expect(summary, contains('Long text here...'));
        await session.close();
      });

      test('should summarize text with custom style', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final summary = await session.summarizeText(
          'Long text here...',
          style: SummarizationStyle.detailed,
        );

        expect(summary, isNotNull);
        await session.close();
      });
    });

    group('extractInformation', () {
      test('should extract information', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final info = await session.extractInformation('Some text');

        expect(info, isA<Map<String, dynamic>>());
        await session.close();
      });

      test('should extract specific fields', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final info = await session.extractInformation(
          'Some text',
          fields: ['name', 'email'],
        );

        expect(info, isA<Map<String, dynamic>>());
        await session.close();
      });
    });

    group('classifyText', () {
      test('should classify text', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final classification = await session.classifyText('Some text');

        expect(classification, isA<Map<String, double>>());
        await session.close();
      });

      test('should classify with custom categories', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final classification = await session.classifyText(
          'Some text',
          categories: ['positive', 'negative', 'neutral'],
        );

        expect(classification, isA<Map<String, double>>());
        await session.close();
      });
    });

    group('generateSuggestions', () {
      test('should generate suggestions with default max', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final suggestions = await session.generateSuggestions('Context');

        expect(suggestions, isA<List<String>>());
        expect(suggestions.length, 5);
        await session.close();
      });

      test('should generate suggestions with custom max', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final suggestions = await session.generateSuggestions(
          'Context',
          maxSuggestions: 3,
        );

        expect(suggestions.length, 3);
        await session.close();
      });
    });

    group('generateTextStream', () {
      test('should stream text chunks', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final chunks = <String>[];
        await for (final chunk in session.generateTextStream('Tell a story')) {
          chunks.add(chunk);
        }

        expect(chunks.length, 3);
        expect(chunks, contains('chunk1'));
        expect(chunks, contains('chunk2'));
        expect(chunks, contains('chunk3'));
        await session.close();
      });

      test('should throw error when session is closed', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        await session.close();

        expect(
          () => session.generateTextStream('Tell a story'),
          throwsStateError,
        );
      });
    });

    group('getStructuredDataStream', () {
      test('should stream structured data', () async {
        final session = await AppleIntelligenceSession.create(
          'You are a helpful assistant',
        );

        final chunks = <String>[];
        await for (final chunk
            in session.getStructuredDataStream('Create data')) {
          chunks.add(chunk);
        }

        expect(chunks.length, 1);
        expect(chunks[0], contains('key'));
        await session.close();
      });
    });
  });
}
