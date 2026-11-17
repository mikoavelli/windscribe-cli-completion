#!/bin/bash
# Install the windscribe-cli bash completion.
#
# Without arguments the completion is installed for the current user into
# ~/.local/share/bash-completion/completions (bash-completion picks it up
# automatically in new interactive shells, no /etc changes needed).
#
# Options:
#   --user     install for the current user (default when not root)
#   --system   install for all users into /usr/share/bash-completion/completions
#              (uses sudo if not run as root)
#   --destdir  install into an explicit directory instead
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
        user)   dest="$HOME/.local/share/bash-completion/completions" ;;
        system) dest="/usr/share/bash-completion/completions" ;;
        auto)
            if ((EUID == 0)); then
                dest="/usr/share/bash-completion/completions"
            else
                dest="$HOME/.local/share/bash-completion/completions"
            fi
            ;;
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
