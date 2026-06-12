# pub_score_checker

A Dart CLI that runs [`pana`](https://pub.dev/packages/pana) against a local or published Dart/Flutter package and exits with a non-zero code when the pub score drops below an acceptable threshold.

## Installation

```sh
dart install https://github.com/mrverdant13/pub_score_checker.git
```

Alternatively, using `dart pub global activate`:

```sh
dart pub global activate --source git https://github.com/mrverdant13/pub_score_checker
```

## Usage

```
pub_score_checker check_pub_score <subcommand> [options]
```

### `local` — analyze a package by path

Runs pana against a package directory on disk.

```sh
pub_score_checker check_pub_score local \
  --package-path path/to/my_package \
  --threshold 10
```

| Flag | Abbr | Required | Description |
|---|---|---|---|
| `--package-path` | `-p` | yes | Path to the local package directory. |
| `--threshold` | `-t` | no | Maximum missing points allowed before failing (default: `0`). |
| `--markdown-output` | `-m` | no | Path to write a Markdown report of failing sections. |

### `remote` — analyze a published package by name

Fetches and runs pana against a package from pub.dev.

```sh
pub_score_checker check_pub_score remote \
  --package-name my_package \
  --threshold 10
```

| Flag | Abbr | Required | Description |
|---|---|---|---|
| `--package-name` | `-n` | yes | Name of the package on pub.dev. |
| `--threshold` | `-t` | no | Maximum missing points allowed before failing (default: `0`). |
| `--markdown-output` | `-m` | no | Path to write a Markdown report of failing sections. |

## Options

### `--threshold` / `-t`

The number of missing pub points the check tolerates before failing. Defaults to `0`, meaning any missing point causes a non-zero exit.

```sh
# Passes as long as the package is missing 20 points or fewer
pub_score_checker check_pub_score remote \
  --package-name my_package \
  --threshold 20
```

### `--markdown-output` / `-m`

When provided, writes a Markdown file listing every failing report section with its score and summary. Useful for surfacing issues in CI pull-request comments.

```sh
pub_score_checker check_pub_score local \
  --package-path . \
  --threshold 0 \
  --markdown-output pub_score_report.md
```

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Check passed — missing points are within the threshold. |
| `1` | Check failed — missing points exceed the threshold, or pana analysis failed. |
| `64` | Bad usage — invalid flags or missing required options. |
