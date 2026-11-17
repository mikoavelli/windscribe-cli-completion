#!/bin/bash
# Remove the windscribe-cli bash completion installed by install.sh.
#
# Usage:
#   ./uninstall.sh              remove from the same place install.sh put it
#   ./uninstall.sh --user       remove the per-user install
#   ./uninstall.sh --system     remove the system-wide install (uses sudo)
#   ./uninstall.sh --destdir D  remove from directory D instead

set -euo pipefail

NAME=windscribe-cli

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
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

if [[ -n $destdir ]]; then
    target="$destdir/$NAME"
else
    case "$mode" in
        auto|system) target="/usr/share/bash-completion/completions/$NAME" ;;
        user)        target="$HOME/.local/share/bash-completion/completions/$NAME" ;;
    esac
fi

if [[ $target == /usr/share/* && $EUID -ne 0 ]]; then
    sudo rm -f "$target"
else
    rm -f "$target"
fi

echo "Removed $target"
