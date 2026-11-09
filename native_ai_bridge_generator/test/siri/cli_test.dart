import 'dart:io';

import 'package:native_ai_bridge_generator/src/siri/cli.dart';
import 'package:native_ai_bridge_generator/src/siri/manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

const _swiftOut = 'ios/Runner/Siri/Generated';
const _skillsOut = 'ios/Runner/Skills.skillsbundle/Skills';

class _Result {
  _Result(this.exitCode, this.out, this.err);

  final int exitCode;
  final String out;
  final String err;
}

Future<_Result> _run(Directory root, [List<String> args = const []]) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = await run(args, root: root.path, out: out, err: err);
  return _Result(code, '$out', '$err');
}

File _file(Directory root, String path) => File(p.join(root.path, path));

Map<String, String> _snapshot(Directory root) => {
  for (final entity in Directory(
    p.join(root.path, 'ios'),
  ).listSync(recursive: true))
    if (entity is File)
      p.relative(entity.path, from: root.path): entity.readAsStringSync(),
};

void main() {
  test('writes every file and warns about missing Xcode folders', () async {
    final root = await createApp();

    final result = await _run(root);

    expect(result.exitCode, 0, reason: result.err);
    expect(result.out, contains('7 written, 0 unchanged.'));
    expect(result.err, contains('warning: $_swiftOut did not exist'));
    expect(
      result.err,
      contains('warning: ios/Runner/Skills.skillsbundle did not exist'),
    );
    expect(
      _file(root, '$_swiftOut/SearchProducts.g.swift').readAsStringSync(),
      File('test/siri/goldens/swift/SearchProducts.g.swift').readAsStringSync(),
    );
    expect(
      _file(root, '$_skillsOut/store-shopping/SKILL.md').readAsStringSync(),
      File(
        'test/siri/goldens/skills/store-shopping/SKILL.md',
      ).readAsStringSync(),
    );
  });

  test('is idempotent', () async {
    final root = await createApp();
    await _run(root);
    final before = _snapshot(root);
    final modified = {
      for (final path in before.keys)
        path: _file(root, path).lastModifiedSync(),
    };

    final second = await _run(root);

    expect(second.exitCode, 0);
    expect(second.out, '0 written, 7 unchanged.\n');
    expect(second.err, isEmpty);
    expect(_snapshot(root), before);
    for (final MapEntry(key: path, value: time) in modified.entries) {
      expect(_file(root, path).lastModifiedSync(), time, reason: path);
    }
  });

  group('--check', () {
    test('exits 0 when every file is up to date', () async {
      final root = await createApp();
      await _run(root);

      final result = await _run(root, ['--check']);

      expect(result.exitCode, 0);
      expect(result.out, 'Siri files are up to date.\n');
    });

    test('exits 1 and lists stale, missing and orphaned files', () async {
      final root = await createApp();
      await _run(root);
      _file(root, '$_swiftOut/AddToCart.g.swift').writeAsStringSync(
        '$generatedSwiftHeader\nold\n',
      );
      _file(root, '$_skillsOut/order-help/SKILL.md').deleteSync();
      _file(root, '$_swiftOut/OldTool.g.swift').writeAsStringSync(
        '$generatedSwiftHeader\nold\n',
      );
      _file(root, '$_skillsOut/old-skill/SKILL.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('---\n---\n$generatedSkillHeader\nold\n');
      final before = _snapshot(root);

      final result = await _run(root, ['--check']);

      expect(result.exitCode, 1);
      expect(
        result.err,
        'missing: $_skillsOut/order-help/SKILL.md\n'
        'stale: $_swiftOut/AddToCart.g.swift\n'
        'orphaned: $_swiftOut/OldTool.g.swift is no longer generated; '
        'delete it by hand\n'
        'orphaned: $_skillsOut/old-skill/SKILL.md is no longer generated; '
        'delete it by hand\n'
        'Siri files are out of date. Run '
        'dart run native_ai_bridge_generator:siri.\n',
      );
      expect(_snapshot(root), before);
    });

    test('exits 1 when nothing has been generated yet', () async {
      final root = await createApp();

      final result = await _run(root, ['--check']);

      expect(result.exitCode, 1);
      expect(
        result.err,
        contains('missing: $_swiftOut/SearchProducts.g.swift'),
      );
      expect(Directory(p.join(root.path, 'ios')).existsSync(), isFalse);
    });

    test('exits 1 on a file without the generated header', () async {
      final root = await createApp();
      await _run(root);
      _file(
        root,
        '$_swiftOut/AddToCart.g.swift',
      ).writeAsStringSync('struct AddToCart {}\n');

      final result = await _run(root, ['--check']);

      expect(result.exitCode, 1);
      expect(
        result.err,
        contains(
          'not generated: $_swiftOut/AddToCart.g.swift has no generated '
          'header',
        ),
      );
    });
  });

  test('never overwrites a file without the generated header', () async {
    final root = await createApp();
    _file(root, '$_skillsOut/store-shopping/SKILL.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('---\nname: store-shopping\n---\nMine.\n');

    final result = await _run(root);

    expect(result.exitCode, 1);
    expect(
      result.err,
      contains(
        'Refusing to overwrite $_skillsOut/store-shopping/SKILL.md: it has '
        'no generated header',
      ),
    );
    expect(
      _file(root, '$_skillsOut/store-shopping/SKILL.md').readAsStringSync(),
      '---\nname: store-shopping\n---\nMine.\n',
    );
    expect(Directory(p.join(root.path, _swiftOut)).existsSync(), isFalse);
  });

  test('keeps orphaned files and warns about them', () async {
    final root = await createApp();
    await _run(root);
    _file(root, '$_swiftOut/OldTool.g.swift').writeAsStringSync(
      '$generatedSwiftHeader\nold\n',
    );
    _file(root, '$_swiftOut/Handwritten.g.swift').writeAsStringSync('mine\n');

    final result = await _run(root);

    expect(result.exitCode, 0);
    expect(
      result.err,
      'warning: $_swiftOut/OldTool.g.swift is no longer generated; delete it '
      'by hand.\n',
    );
    expect(_file(root, '$_swiftOut/OldTool.g.swift').existsSync(), isTrue);
  });

  test('omits the #if block when compilation_condition is unset', () async {
    final root = await createApp(
      config:
          '''
siri:
  input: lib/siri/siri_tools.dart
  swift_out: $_swiftOut
  skills_out: $_skillsOut
''',
    );

    await _run(root);

    expect(
      _file(root, '$_swiftOut/AddToCart.g.swift').readAsStringSync(),
      isNot(contains('#if')),
    );
  });

  test('exits 1 and writes nothing on validation errors', () async {
    final root = await createApp(input: invalidFixture('tool_metadata'));

    final result = await _run(root);

    expect(result.exitCode, 1);
    expect(
      result.err,
      contains(
        'lib/siri/siri_tools.dart:4:7: error [tool-metadata] Tool Search '
        'needs a non-empty title and description in @SiriTool.',
      ),
    );
    expect(
      result.err,
      contains('3 errors in lib/siri/siri_tools.dart. Nothing was written.'),
    );
    expect(Directory(p.join(root.path, 'ios')).existsSync(), isFalse);
  });

  test('exits 1 with the location of a Dart error in the input', () async {
    final root = await createApp();
    _file(root, 'lib/siri/siri_tools.dart').writeAsStringSync(
      'class Broken {\n  final Missing value;\n}\n',
    );

    final result = await _run(root);

    expect(result.exitCode, 1);
    expect(result.err, contains('lib/siri/siri_tools.dart:2:9: error [dart]'));
  });

  group('exits 2', () {
    test('when the config file is missing and prints an example', () async {
      final root = await createApp();
      _file(root, 'native_ai_bridge.yaml').deleteSync();

      final result = await _run(root);

      expect(result.exitCode, 2);
      expect(result.err, contains('native_ai_bridge.yaml not found.'));
      expect(result.err, contains('siri:\n  input: lib/siri/siri_tools.dart'));
      expect(result.err, contains('compilation_condition: SIRI_AI_TOOLS'));
    });

    test('when the config has an unknown key', () async {
      final root = await createApp(
        config: 'siri:\n  input: a.dart\n  swiftout: x\n',
      );

      final result = await _run(root);

      expect(result.exitCode, 2);
      expect(
        result.err,
        contains('Unknown keys in the "siri" section: swiftout.'),
      );
    });

    test('when the compilation condition is not an identifier', () async {
      final root = await createApp(
        config:
            'siri:\n  input: a.dart\n  swift_out: a\n  skills_out: b\n'
            '  compilation_condition: SIRI AI\n',
      );

      final result = await _run(root);

      expect(result.exitCode, 2);
      expect(result.err, contains('is not a Swift identifier'));
    });

    test('when the input file does not exist', () async {
      final root = await createApp();
      _file(root, 'lib/siri/siri_tools.dart').deleteSync();

      final result = await _run(root);

      expect(result.exitCode, 2);
      expect(
        result.err,
        'Input lib/siri/siri_tools.dart does not exist.\n',
      );
    });

    test('on an unknown flag', () async {
      final root = await createApp();

      final result = await _run(root, ['--fix']);

      expect(result.exitCode, 2);
      expect(result.err, contains('Could not find an option named "--fix"'));
    });
  });

  test('--help prints usage and exits 0', () async {
    final root = await createApp();

    final result = await _run(root, ['--help']);

    expect(result.exitCode, 0);
    expect(result.out, contains('--check'));
  });
}
