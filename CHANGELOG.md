# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Bash tab completion for `windscribe-cli`: all commands, subcommands,
  on/off and keep/delete arguments, `-n`/`--help` flags, protocols and
  `protocol:port` expansion from `windscribe-cli ports`.
- Live candidates from the CLI itself: locations and nicknames
  (`windscribe-cli locations`), static cities/IPs (`locations static`) and
  pinned favourite IPs (`locations fav`). Multi-word locations are quoted
  by readline on insertion.
- Test suite (`test/run-tests.bash`) driven by a stubbed `windscribe-cli`.
- `install.sh` / `uninstall.sh`: per-user (default) or system-wide install
  into bash-completion's directories; `--destdir` for packaging.

## [0.0.0]

Project scaffolded: README, MIT license, changelog.
