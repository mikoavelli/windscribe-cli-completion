# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-11-17

### Added

- Bash tab completion for `windscribe-cli`: all commands, subcommands,
  on/off and keep/delete arguments, protocols and `protocol:port` expansion
  from `windscribe-cli ports`.
- Global top-level flags `-h`, `--help`, `--version`.
- `connect` accepts a bare protocol as its first argument
  (`connect wireguard`), including `protocol:port` expansion.
- Every command accepts `-h`/`--help`; `connect` and `disconnect` also `-n`.
- Live candidates from the CLI itself: locations and nicknames
  (`windscribe-cli locations`), static cities/IPs (`locations static`) and
  pinned favourite IPs (`locations fav`). Multi-word locations are quoted
  by readline on insertion.
- Test suite (`test/run-tests.bash`) driven by a stubbed `windscribe-cli`.
- Arch Linux package: `PKGBUILD` installs the completion into
  `/usr/share/bash-completion/completions`, the same place packaged
  completions live. Build with `makepkg`, install with
  `sudo pacman -U`.

### Removed

- `install.sh` / `uninstall.sh`: superseded by the pacman package.
