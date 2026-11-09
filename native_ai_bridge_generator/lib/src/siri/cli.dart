import 'dart:io';

import 'package:args/args.dart';
import 'package:native_ai_bridge_generator/src/siri/config.dart';
import 'package:native_ai_bridge_generator/src/siri/output_files.dart';
import 'package:native_ai_bridge_generator/src/siri/reader.dart';
import 'package:native_ai_bridge_generator/src/siri/skill_renderer.dart';
import 'package:native_ai_bridge_generator/src/siri/swift_renderer.dart';
import 'package:native_ai_bridge_generator/src/siri/validator.dart';
import 'package:native_ai_bridge_generator/src/siri/writer.dart';
import 'package:path/path.dart' as p;

const _command = 'dart run native_ai_bridge_generator:siri';

final _parser = ArgParser()
  ..addFlag(
    'check',
    negatable: false,
    help: 'Write nothing. Exit 1 if any file is missing, stale or orphaned.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

Future<int> run(
  List<String> args, {
  String? root,
  StringSink? out,
  StringSink? err,
}) async {
  final appRoot = root ?? Directory.current.path;
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;

  final ArgResults options;
  try {
    options = _parser.parse(args);
  } on FormatException catch (error) {
    stderrSink
      ..writeln(error.message)
      ..writeln(_usage());
    return 2;
  }
  if (options.flag('help')) {
    stdoutSink.writeln(_usage());
    return 0;
  }
  if (options.rest.isNotEmpty) {
    stderrSink
      ..writeln('Unexpected arguments: ${options.rest.join(' ')}')
      ..writeln(_usage());
    return 2;
  }

  final SiriConfig config;
  try {
    config = SiriConfig.load(appRoot);
  } on SiriConfigException catch (error) {
    stderrSink
      ..writeln(error.message)
      ..writeln('Add $siriConfigFileName at the app root, for example:')
      ..writeln()
      ..write(siriConfigExample);
    return 2;
  }

  if (!File(p.join(appRoot, config.input)).existsSync()) {
    stderrSink.writeln('Input ${config.input} does not exist.');
    return 2;
  }

  final ValidatedSiriManifest manifest;
  try {
    manifest = validManifest(
      await readSiriManifest(config.input, root: appRoot),
    );
  } on SiriReadException catch (error) {
    error.messages.forEach(stderrSink.writeln);
    return 1;
  } on SiriValidationException catch (error) {
    final count = error.errors.length;
    stderrSink
      ..writeAll(error.errors, '\n')
      ..writeln()
      ..writeln(
        '$count error${count == 1 ? '' : 's'} in ${config.input}. '
        'Nothing was written.',
      );
    return 1;
  }

  final files = {
    for (final MapEntry(:key, :value) in renderSwift(
      manifest,
      compilationCondition: config.compilationCondition,
    ).entries)
      p.posix.join(config.swiftOut, key): value,
    for (final MapEntry(:key, :value) in renderSkills(manifest).entries)
      p.posix.join(config.skillsOut, key): value,
  };
  final plan = planSiriOutput(
    appRoot,
    files,
    swiftOut: config.swiftOut,
    skillsOut: config.skillsOut,
  );

  if (options.flag('check')) {
    return _check(plan, stdoutSink, stderrSink);
  }
  return _write(appRoot, config, files, plan, stdoutSink, stderrSink);
}

int _check(SiriOutputPlan plan, StringSink out, StringSink err) {
  if (plan.isClean) {
    out.writeln('Siri files are up to date.');
    return 0;
  }
  for (final path in plan.missing) {
    err.writeln('missing: $path');
  }
  for (final path in plan.stale) {
    err.writeln('stale: $path');
  }
  for (final path in plan.unheadered) {
    err.writeln('not generated: $path has no generated header');
  }
  for (final path in plan.orphaned) {
    err.writeln('orphaned: $path is no longer generated; delete it by hand');
  }
  err.writeln('Siri files are out of date. Run $_command.');
  return 1;
}

int _write(
  String root,
  SiriConfig config,
  Map<String, String> files,
  SiriOutputPlan plan,
  StringSink out,
  StringSink err,
) {
  if (plan.unheadered.isNotEmpty) {
    for (final path in plan.unheadered) {
      err.writeln(
        'Refusing to overwrite $path: it has no generated header, so it '
        'was not written by this tool. Move or delete it, then run again.',
      );
    }
    return 1;
  }

  final hasSwift = files.keys.any((path) => path.endsWith(swiftFileSuffix));
  final hasSkills = files.keys.any((path) => path.endsWith(skillFileName));
  if (hasSwift && !Directory(p.join(root, config.swiftOut)).existsSync()) {
    err.writeln(
      'warning: ${config.swiftOut} did not exist, so it was created. Add it '
      'to the Runner target in Xcode as a folder (a synchronized group) so '
      'the generated Swift is compiled.',
    );
  }
  final bundle = p.posix.dirname(config.skillsOut);
  if (hasSkills && !Directory(p.join(root, bundle)).existsSync()) {
    err.writeln(
      'warning: $bundle did not exist, so it was created. Xcode only '
      'compiles skills from a bundle added to the app target: create it '
      'with File > New > File from Template > Skills Bundle, or add this '
      'folder to Copy Bundle Resources.',
    );
  }

  final written = writeSiriOutput(root, files, plan);
  for (final path in written) {
    out.writeln('wrote $path');
  }
  for (final path in plan.orphaned) {
    err.writeln(
      'warning: $path is no longer generated; delete it by hand.',
    );
  }
  out.writeln(
    '${written.length} written, ${plan.unchanged.length} unchanged.',
  );
  return 0;
}

String _usage() =>
    'Generate Siri AI tool intents and app skills from Dart annotations.\n\n'
    'Usage: $_command [--check]\n\n'
    'Reads the "siri" section of $siriConfigFileName in the current '
    'directory.\n\n'
    '${_parser.usage}';
