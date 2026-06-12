import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:pana/pana.dart';

class PubScoreCheckerCommandRunner extends CommandRunner<int> {
  PubScoreCheckerCommandRunner()
      : super(
          'pub_score_checker',
          'Evaluate the health and quality of a Dart package.',
        ) {
    addCommand(CheckPubScoreCommand());
  }
}

class CheckPubScoreCommand extends Command<int> {
  CheckPubScoreCommand() {
    addSubcommand(LocalCommand());
    addSubcommand(RemoteCommand());
  }

  @override
  String get name => 'check_pub_score';

  @override
  String get description => 'Check the pub score of a Dart package.';

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

abstract class PubScoreCheckerCommand extends Command<int> {
  PubScoreCheckerCommand() {
    argParser
      ..addOption(
        _thresholdOption,
        abbr: 't',
        help: 'Maximum missing points allowed before failing.',
        defaultsTo: '0',
      )
      ..addOption(
        _markdownOutputOption,
        abbr: 'm',
        help: 'Path to write a Markdown report of failing sections.',
      );
  }

  static const _thresholdOption = 'threshold';
  static const _markdownOutputOption = 'markdown-output';

  int get _threshold => int.parse(argResults![_thresholdOption] as String);

  String? get _markdownOutput => argResults![_markdownOutputOption] as String?;

  Future<Summary> analyze(PackageAnalyzer analyzer);

  @override
  Future<int> run() async {
    Logger.root.level = Level.OFF;

    final toolEnv = await ToolEnvironment.create();
    final analyzer = PackageAnalyzer(toolEnv);

    stdout.writeln('Running pana analysis...');
    final summary = await analyze(analyzer);
    final report = summary.report;

    if (report == null) {
      stderr.writeln(
        'Analysis failed: ${summary.errorMessage ?? 'unknown error'}',
      );
      return 1;
    }

    final grantedPoints = report.grantedPoints;
    final maxPoints = report.maxPoints;
    final missingPoints = maxPoints - grantedPoints;

    stdout
        .writeln('Score: $grantedPoints/$maxPoints (missing: $missingPoints)');

    final mdOutputPath = _markdownOutput;
    if (mdOutputPath != null) {
      await _writeMarkdownReport(report, mdOutputPath);
    }

    if (missingPoints > _threshold) {
      stderr.writeln(
        'Check failed: $missingPoints missing points exceeds '
        'threshold of $_threshold.',
      );
      return 1;
    }

    stdout.writeln('Check passed.');
    return 0;
  }

  Future<void> _writeMarkdownReport(Report report, String outputPath) async {
    final buffer = StringBuffer();
    for (final section in report.sections) {
      if (section.grantedPoints >= section.maxPoints) continue;
      buffer
        ..writeln(
          '## ${section.title} '
          '(${section.grantedPoints}/${section.maxPoints})',
        )
        ..writeln()
        ..writeln(section.summary)
        ..writeln();
    }
    await File(outputPath).writeAsString(buffer.toString());
  }
}

class LocalCommand extends PubScoreCheckerCommand {
  LocalCommand() {
    argParser.addOption(
      _packagePathOption,
      abbr: 'p',
      help: 'Path to the local package directory.',
      mandatory: true,
    );
  }

  static const _packagePathOption = 'package-path';

  @override
  String get name => 'local';

  @override
  String get description =>
      'Check the pub score of a local Dart package by path.';

  @override
  Future<Summary> analyze(PackageAnalyzer analyzer) {
    final packagePath = argResults![_packagePathOption] as String;
    return analyzer.inspectDir(packagePath);
  }
}

class RemoteCommand extends PubScoreCheckerCommand {
  RemoteCommand() {
    argParser.addOption(
      _packageNameOption,
      abbr: 'n',
      help: 'Name of the package on pub.dev.',
      mandatory: true,
    );
  }

  static const _packageNameOption = 'package-name';

  @override
  String get name => 'remote';

  @override
  String get description =>
      'Check the pub score of a published Dart package by name.';

  @override
  Future<Summary> analyze(PackageAnalyzer analyzer) {
    final packageName = argResults![_packageNameOption] as String;
    return analyzer.inspectPackage(packageName);
  }
}
