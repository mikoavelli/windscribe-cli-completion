#!/bin/bash
# Install the windscribe-cli bash completion, the same way packaged
# completions are installed: into the system bash-completion directory
# /usr/share/bash-completion/completions/windscribe-cli (uses sudo if not
# root). A new shell picks it up automatically — no sourcing, ever.
#
# Options:
#   --system   install into /usr/share/bash-completion/completions
#              (default; uses sudo if not root)
#   --user     install for the current user into
#              ~/.local/share/bash-completion/completions instead
#   --destdir  install into an explicit directory instead (no sudo)
#   -h|--help  show this help

set -euo pipefail

NAME=windscribe-cli
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/completions/$NAME.bash"

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

mode=auto
destdir=""

while (($#)); do
    case "$1" in
        --user) mode=user ;;
        --system) mode=system ;;
        --destdir) destdir="${2:?--destdir needs a value}"; shift ;;
        -h|--help) usage 0 ;;
        *) echo "unknown option: $1" >&2; usage 1 ;;
    esac
    shift
done

[[ -f $SRC ]] || { echo "completion source not found: $SRC" >&2; exit 1; }

if [[ -n $destdir ]]; then
    dest="$destdir"
else
    case "$mode" in
        auto|system) dest="/usr/share/bash-completion/completions" ;;
        user)        dest="$HOME/.local/share/bash-completion/completions" ;;
    esac
fi

if [[ $dest == /usr/share/* && $EUID -ne 0 ]]; then
    command -v sudo >/dev/null || { echo "need root or sudo to install into $dest" >&2; exit 1; }
    sudo install -D -m 0644 "$SRC" "$dest/$NAME"
else
    install -D -m 0644 "$SRC" "$dest/$NAME"
fi

# Sanity check: the installed file must parse.
bash -n "$dest/$NAME"

cat <<EOF
Installed $dest/$NAME

That's all. Open a new shell and press TAB — bash-completion loads it
automatically on first use, exactly like packaged completions.
EOF
