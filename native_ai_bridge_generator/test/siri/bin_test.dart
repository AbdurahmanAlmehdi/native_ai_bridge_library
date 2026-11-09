import 'dart:io';

import 'package:test/test.dart';

void main() {
  Future<ProcessResult> siri(List<String> args) =>
      Process.run(Platform.resolvedExecutable, ['bin/siri.dart', ...args]);

  test('the executable prints usage and exits 0 for --help', () async {
    final result = await siri(['--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('--check'));
  });

  test('the executable passes the CLI exit code through', () async {
    final result = await siri(['--unknown']);

    expect(result.exitCode, 2);
  });
}
