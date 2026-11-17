#!/bin/bash
# Test harness for completions/windscribe-cli.bash.
#
# Sources the completion with a stubbed `windscribe-cli` on PATH (so tests do
# not depend on the live Windscribe service) and asserts the COMPREPLY for a
# battery of completion scenarios. Run: ./test/run-tests.bash

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
STUB_DIR="$TEST_DIR/stub-bin"
mkdir -p "$STUB_DIR"

# --- Stub windscribe-cli ---------------------------------------------------
cat > "$STUB_DIR/windscribe-cli" <<'EOF'
#!/bin/bash
case "$1" in
    locations)
        case "$2" in
            fav)
                printf 'Atlanta - Magic City [203.0.113.99]\nNo locations.\n' ;;
            static)
                printf 'Amsterdam - 203.0.113.10\nToronto - 198.51.100.7\n' ;;
            *)
                cat <<'LOCATIONS'
Best Location - Wurstchen (10 Gbps)
US Central - Atlanta - Magic City (Pro) (10 Gbps)
US Central - Denver - Mile High (Pro)
EU - Paris - Eiffel
LOCATIONS
                ;;
        esac
        ;;
    ports)
        case "$2" in
            wireguard) printf '443, 80, 53, 123\n' ;;
            udp) printf '443, 1194\n' ;;
            tcp) printf '443, 80\n' ;;
            stealth) printf '443, 8443\n' ;;
            wstunnel) printf '443\n' ;;
        esac
        ;;
    *)
        printf 'windscribe-cli stub\n' ;;
esac
exit 0
EOF
chmod +x "$STUB_DIR/windscribe-cli"

export PATH="$STUB_DIR:$PATH"
command -v windscribe-cli >/dev/null || { echo "stub not on PATH" >&2; exit 2; }
[[ "$(command -v windscribe-cli)" == "$STUB_DIR/windscribe-cli" ]] || { echo "stub shadowed by real windscribe-cli; aborting" >&2; exit 2; }

# Load bash-completion (idempotent) then the completion under test.
[[ -r /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
source "$PROJECT_ROOT/windscribe-cli.bash"

# --- Test machinery ----------------------------------------------------------
passes=0
failures=0

# complete_words WORD... — set COMP_WORDS/COMP_CWORD as readline would after
# typing the words, run the completion, print COMPREPLY one per line.
complete_words() {
    COMP_WORDS=("$@")
    COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
    COMP_LINE="${COMP_WORDS[*]}"
    COMP_POINT=${#COMP_LINE}
    COMPREPLY=()
    _windscribe_cli
    printf '%s\n' "${COMPREPLY[@]}" | sed '/^$/d'
}

# assert_completion NAME EXPECTED WORD...
#   EXPECTED is a newline-separated list of candidates (use $'a\nb' for two).
assert_completion() {
    local name="$1"
    local expected="$2"
    shift 2
    local actual
    actual="$(complete_words "$@" | LC_ALL=C sort)"
    expected="$(printf '%s\n' "$expected" | sed '/^$/d' | LC_ALL=C sort)"
    if [[ "$actual" == "$expected" ]]; then
        printf 'ok   %s\n' "$name"
        ((passes++))
    else
        printf 'FAIL %s\n     expected:\n     %s\n     actual:\n     %s\n' "$name" "${expected//$'\n'/$'\n'     }" "${actual//$'\n'/$'\n'     }"
        ((failures++))
    fi
}

# --- Tests -------------------------------------------------------------------
assert_completion 'no arguments completes all commands' \
    $'connect\ndisconnect\nstatus\nfirewall\nlocations\nports\namneziawg\nip\nlogin\nlogout\nupdate\nlogs\nkeylimit\nignoresslerrors\nversion\nhelp' \
    windscribe-cli ""

assert_completion 'command prefix completes to nearest match' \
    'connect' \
    windscribe-cli conn

assert_completion 'firewall takes on|off' \
    $'off\non' \
    windscribe-cli firewall ""

assert_completion 'firewall takes nothing after on' \
    '' \
    windscribe-cli firewall on ""

assert_completion 'logout takes on|off' \
    $'off\non' \
    windscribe-cli logout ""

assert_completion 'ignoresslerrors takes on|off' \
    $'off\non' \
    windscribe-cli ignoresslerrors ""

assert_completion 'keylimit takes keep|delete' \
    $'delete\nkeep' \
    windscribe-cli keylimit ""

assert_completion 'locations takes fav|static' \
    $'fav\nstatic' \
    windscribe-cli locations ""

assert_completion 'locations fav takes nothing else' \
    '' \
    windscribe-cli locations fav ""

assert_completion 'ports takes protocols' \
    $'stealth\ntcp\nudp\nwireguard\nwstunnel' \
    windscribe-cli ports ""

assert_completion 'ports takes no extra arguments' \
    '' \
    windscribe-cli ports udp ""

assert_completion 'logs takes send' \
    'send' \
    windscribe-cli logs ""

assert_completion 'help takes a command' \
    $'connect\ndisconnect\nstatus\nfirewall\nlocations\nports\namneziawg\nip\nlogin\nlogout\nupdate\nlogs\nkeylimit\nignoresslerrors\nversion\nhelp' \
    windscribe-cli help ""

assert_completion 'connect offers best/static and locations' \
    $'Best Location\nDenver\nEU\nEiffel\nMagic City\nMile High\nParis\nUS Central\nWurstchen\nbest\nstatic\nAtlanta\nwireguard\nudp\ntcp\nstealth\nwstunnel' \
    windscribe-cli connect ""

assert_completion 'connect completes single-word location prefix' \
    'Atlanta' \
    windscribe-cli connect "At"

assert_completion 'connect completes multi-word nickname (quoted by readline on insert)' \
    'Magic City' \
    windscribe-cli connect "Magic"

assert_completion 'connect after location completes protocols' \
    $'stealth\ntcp\nudp\nwireguard\nwstunnel' \
    windscribe-cli connect best ""

assert_completion 'connect static offers static cities and IPs' \
    $'198.51.100.7\n203.0.113.10\nAmsterdam\nToronto' \
    windscribe-cli connect static ""

assert_completion 'connect static <city> completes protocols' \
    $'stealth\ntcp\nudp\nwireguard\nwstunnel' \
    windscribe-cli connect static Amsterdam ""

assert_completion 'connect protocol prefix completes protocols' \
    'stealth' \
    windscribe-cli connect best s

assert_completion 'connect protocol:port completes ports for protocol' \
    $'wireguard:123\nwireguard:443\nwireguard:53\nwireguard:80' \
    windscribe-cli connect best wireguard:

assert_completion 'connect flags: -h, --help and -n' \
    $'-h\n--help\n-n' \
    windscribe-cli connect -

assert_completion 'disconnect flags: -h, --help and -n' \
    $'-h\n--help\n-n' \
    windscribe-cli disconnect -

assert_completion 'other commands also accept -h and --help' \
    $'-h\n--help' \
    windscribe-cli status -

assert_completion 'top-level flags: -h, --help, --version' \
    $'-h\n--help\n--version' \
    windscribe-cli -

assert_completion 'connect takes a bare protocol as first argument' \
    'wireguard' \
    windscribe-cli connect wir

assert_completion 'connect protocol:port as first argument' \
    $'stealth:443\nstealth:8443' \
    windscribe-cli connect stealth:

assert_completion 'connect takes protocol as first argument without location' \
    $'wireguard\nwstunnel' \
    windscribe-cli connect "w"

assert_completion 'ip takes rotate|fav|unfav' \
    $'fav\nrotate\nunfav' \
    windscribe-cli ip ""

assert_completion 'ip unfav completes pinned favourite IPs' \
    '203.0.113.99' \
    windscribe-cli ip unfav ""

assert_completion 'ip rotate takes no argument' \
    '' \
    windscribe-cli ip rotate ""

assert_completion 'disconnect flags after command: sanity' \
    '' \
    windscribe-cli disconnect on ""

# --- Summary -------------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$passes" "$failures"
((failures == 0))
