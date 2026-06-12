import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:pub_score_checker/pub_score_checker.dart';

Future<void> main(List<String> arguments) async {
  final runner = PubScoreCheckerCommandRunner();
  try {
    exitCode = await runner.run(arguments) ?? 0;
  } on UsageException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(e.usage);
    exitCode = 64;
  }
}
