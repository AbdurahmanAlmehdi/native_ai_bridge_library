import 'dart:io';

import 'package:native_ai_bridge_generator/src/siri/output_files.dart';
import 'package:path/path.dart' as p;

class SiriOutputPlan {
  const SiriOutputPlan({
    required this.missing,
    required this.stale,
    required this.unheadered,
    required this.orphaned,
    required this.unchanged,
  });

  final List<String> missing;
  final List<String> stale;
  final List<String> unheadered;
  final List<String> orphaned;
  final List<String> unchanged;

  bool get isClean =>
      missing.isEmpty &&
      stale.isEmpty &&
      unheadered.isEmpty &&
      orphaned.isEmpty;
}

SiriOutputPlan planSiriOutput(
  String root,
  Map<String, String> files, {
  required String swiftOut,
  required String skillsOut,
}) {
  final missing = <String>[];
  final stale = <String>[];
  final unheadered = <String>[];
  final unchanged = <String>[];

  for (final MapEntry(key: path, value: content) in _sorted(files)) {
    final file = File(p.join(root, path));
    if (!file.existsSync()) {
      missing.add(path);
      continue;
    }
    final existing = file.readAsStringSync();
    if (!isGeneratedFile(path, existing)) {
      unheadered.add(path);
    } else if (existing != content) {
      stale.add(path);
    } else {
      unchanged.add(path);
    }
  }

  final orphaned = [
    for (final path in _generatedCandidates(root, swiftOut, skillsOut))
      if (!files.containsKey(path) &&
          isGeneratedFile(path, File(p.join(root, path)).readAsStringSync()))
        path,
  ];

  return SiriOutputPlan(
    missing: missing,
    stale: stale,
    unheadered: unheadered,
    orphaned: orphaned,
    unchanged: unchanged,
  );
}

List<String> writeSiriOutput(
  String root,
  Map<String, String> files,
  SiriOutputPlan plan,
) {
  final written = [...plan.missing, ...plan.stale]..sort();
  for (final path in written) {
    File(p.join(root, path))
      ..createSync(recursive: true)
      ..writeAsStringSync(files[path]!);
  }
  return written;
}

bool isGeneratedFile(String path, String content) {
  final lines = content.split('\n');
  if (path.endsWith(swiftFileSuffix)) {
    return lines.first == generatedSwiftHeader;
  }
  if (lines.first != '---') return false;
  final closing = lines.indexOf('---', 1);
  return closing > 0 &&
      closing + 1 < lines.length &&
      lines[closing + 1] == generatedSkillHeader;
}

Iterable<MapEntry<String, String>> _sorted(Map<String, String> files) =>
    files.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

List<String> _generatedCandidates(
  String root,
  String swiftOut,
  String skillsOut,
) {
  final swiftDir = Directory(p.join(root, swiftOut));
  final skillsDir = Directory(p.join(root, skillsOut));
  return [
    if (swiftDir.existsSync())
      for (final entity in swiftDir.listSync())
        if (entity is File && entity.path.endsWith(swiftFileSuffix))
          p.posix.join(swiftOut, p.basename(entity.path)),
    if (skillsDir.existsSync())
      for (final entity in skillsDir.listSync())
        if (entity is Directory &&
            File(p.join(entity.path, skillFileName)).existsSync())
          p.posix.join(skillsOut, p.basename(entity.path), skillFileName),
  ]..sort();
}
