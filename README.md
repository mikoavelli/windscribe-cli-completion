# windscribe-completion

Bash tab completion for [Windscribe](https://windscribe.com/)'s command-line
client, `windscribe-cli`. After installation the whole command surface —
commands, subcommands, flags, protocols, and even live locations — completes
on `TAB`, the way other packages' completions do.

## Install

Build and install the pacman package like any other:

```sh
makepkg -si
```

This installs `/usr/share/bash-completion/completions/windscribe-cli` — the
same path every other completion on the system comes from. Open a new shell
and press TAB: bash-completion loads it automatically on first use. No
sourcing, no `.bashrc` edits. Remove with
`sudo pacman -R windscribe-cli-bash-completion`.

Then just try:

```sh
windscribe-cli <TAB>
windscribe-cli connect <TAB>        # best, static, or a live location
windscribe-cli connect best w<TAB>  # wireguard ...
windscribe-cli connect best wireguard:<TAB>
windscribe-cli ports <TAB>
windscribe-cli help <TAB>
```

## What completes

| Input | Completions |
| --- | --- |
| `windscribe-cli <TAB>` | all 16 commands |
| `windscribe-cli -<TAB>` | `-h`, `--help`, `--version` |
| `connect <TAB>` | `best`, `static`, the protocols, and live locations from `windscribe-cli locations` (regions, cities, nicknames; multi-word nicknames are quoted on insert) |
| `connect static <TAB>` | static-IP cities and IPs from `windscribe-cli locations static` |
| `connect … <TAB>` | `wireguard`, `udp`, `tcp`, `stealth`, `wstunnel` |
| `connect … wireguard:<TAB>` | the ports `windscribe-cli ports wireguard` reports |
| `locations <TAB>` | `fav`, `static` |
| `ports <TAB>` | the five protocols |
| `ip <TAB>` | `rotate`, `fav`, `unfav`; `ip unfav <TAB>` completes pinned IPs |
| `firewall` / `logout` / `ignoresslerrors` | `on`, `off` |
| `keylimit` | `keep`, `delete` |
| `logs` | `send` |
| `help <TAB>` | the command list |
| everywhere | `-h`/`--help` everywhere; `-n` on `connect`/`disconnect` |

Completion queries to the CLI are cached by the shell session only as long as
bash lives; nothing is persisted.

## How it works

Subcommands and fixed arguments complete statically. Everything account- or
server-dependent — locations, ports, favourite IPs — is completed by asking
`windscribe-cli` itself (`locations`, `ports …`), so the candidates always
match the running daemon. Completions are generated per `TAB` press; the CLI
is fast enough for that.

## Development

```sh
./test/run-tests.bash
```

The test suite stubs `windscribe-cli` on `PATH` (it asserts the stub is the
binary on `PATH` and refuses to run otherwise), so tests never touch the
real daemon.

Rebuild the package with `makepkg -f`; after editing `windscribe-cli.bash`,
refresh its checksum with `updpkgsums`.

## Progress

Tracked like the rest of the project: `CHANGELOG.md` for released behaviour,
conventional-commit git history for the audit trail.

- [x] Project scaffold, license, changelog
- [x] Bash completion for the full `windscribe-cli` command surface
- [x] Live location / static IP / pinned-IP candidates
- [x] Test suite with stubbed CLI (27 tests)
- [x] Arch package (`PKGBUILD`, installs into
      `/usr/share/bash-completion/completions` like packaged completions)
- [x] Release `v0.1.0`
- [ ] Fish completion (maybe, if there is demand)
- [ ] Zsh completion (out of scope for now — bash was requested)

## License

MIT, see [LICENSE](LICENSE).
