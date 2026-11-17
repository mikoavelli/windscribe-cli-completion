# bash completion for windscribe-cli, the Windscribe VPN command line client.
#
# Completions are static where the CLI's interface is fixed (subcommands,
# on/off arguments, protocols) and dynamic where it depends on the account
# or server state (locations, ports, favourite IPs), by querying the
# windscribe-cli binary itself, the same way tools like kubectl and git
# complete from live state.
#
# Install: copy this file to ~/.local/share/bash-completion/completions/windscribe-cli
# (or /usr/share/bash-completion/completions/windscribe-cli for all users),
# or run ./install.sh from the repository root.

# Guard against repeated sourcing and non-bash shells.
[[ -n ${BASH_VERSION:-} ]] || return 0

_windscribe_cli_commands=(
    connect disconnect status firewall locations ports amneziawg
    ip login logout update logs keylimit ignoresslerrors version help
)
_windscribe_cli_protocols=(wireguard udp tcp stealth wstunnel)

# Emit one candidate per line: regions, cities and nicknames from
# `windscribe-cli locations`, with "(Pro)"/"(Disabled)"/"(10 Gbps)" suffixes
# stripped. Multi-word entries are returned raw; escaping happens in the
# caller.
_windscribe_cli_location_list() {
    command windscribe-cli locations 2>/dev/null |
        sed -E 's/ \([^)]*\)//g' |
        awk -F ' - ' 'NF >= 2 { for (i = 1; i <= NF; i++) { gsub(/^[ \t]+|[ \t]+$/, "", $i); if ($i != "") print $i } }' |
        sort -u
}

# Emit the cities and IPs from `windscribe-cli locations static`.
_windscribe_cli_static_list() {
    command windscribe-cli locations static 2>/dev/null |
        awk -F ' - ' 'NF == 2 && $1 !~ /^No locations/ { gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); print $1; print $2 }'
}

# Emit pinned favourite IPs from `windscribe-cli locations fav`.
_windscribe_cli_fav_ips() {
    command windscribe-cli locations fav 2>/dev/null |
        grep -oE '\[([0-9]{1,3}\.){3}[0-9]{1,3}\]|\[[0-9a-fA-F:]+\]' |
        tr -d '[]'
}

# Emit ports for a protocol, one per line.
_windscribe_cli_ports() {
    command windscribe-cli ports "$1" 2>/dev/null | tr ',' '\n' | tr -d ' '
}

# compgen wrapper that tolerates multi-word candidates: the candidate list is
# newline-separated (compgen splits -W on IFS) and spaces in candidates are
# backslash-escaped for readline.
_windscribe_cli_compgen() {
    local cur="$1"
    shift
    local candidates=("$@")
    local escaped=()
    local word
    for word in "${candidates[@]}"; do
        escaped+=("${word// /\\ }")
    done
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "$(printf '%s\n' "${escaped[@]}")" -- "$cur") )
    # If any candidate contains a space, ask readline to quote it on insertion
    # (otherwise the raw space breaks the argument into two).
    local c
    for c in "${COMPREPLY[@]}"; do
        if [[ $c == *" "* ]]; then
            compopt -o filenames 2>/dev/null
            break
        fi
    done
}

# protocol or protocol:port candidates, e.g. "wireguard", "stealth:443".
_windscribe_cli_protocol_candidates() {
    local cur="$1"
    if [[ $cur == *:* ]]; then
        local proto="${cur%%:*}" port_prefix="${cur#*:}" p
        local candidates=()
        for p in "${_windscribe_cli_protocols[@]}"; do
            [[ $p == "$proto" ]] || continue
            while IFS= read -r p; do
                [[ -n $p ]] && candidates+=("$proto:$p")
            done < <(_windscribe_cli_ports "$proto")
        done
        _windscribe_cli_compgen "$cur" "${candidates[@]}"
    else
        _windscribe_cli_compgen "$cur" "${_windscribe_cli_protocols[@]}"
    fi
}

_windscribe_cli() {
    local cur prev cword
    local -a words=()
    if declare -F _init_completion >/dev/null; then
        _init_completion -n ':' || return
    else
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi

    # Split the line into the command and its non-flag arguments.
    local -a positional=()
    local i word
    for ((i = 1; i < ${#words[@]}; i++)); do
        word="${words[i]}"
        [[ -z $word || $word == -* ]] && continue
        positional+=("$word")
    done

    # Flag completion, wherever the command accepts them. Every command
    # supports -h/--help; connect and disconnect also take -n; the top level
    # exposes -h/--help/--version globally.
    if [[ $cur == -* ]]; then
        local flags=(-h --help)
        if ((${#positional[@]} == 0)); then
            flags+=(--version)
        else
            case "${positional[0]}" in
                connect|disconnect) flags+=(-n) ;;
            esac
        fi
        _windscribe_cli_compgen "$cur" "${flags[@]}"
        return
    fi

    # No command yet: complete the command itself.
    if ((${#positional[@]} == 0)); then
        _windscribe_cli_compgen "$cur" "${_windscribe_cli_commands[@]}"
        return
    fi

    local cmd="${positional[0]}"
    # Number of completed arguments after the command. When the current word
    # is non-empty it is an in-progress argument being typed, not a completed
    # one, so don't count it.
    local ncompleted=$(( ${#positional[@]} - 1 ))
    if [[ -n $cur && $ncompleted -gt 0 ]]; then
        ((ncompleted--))
    fi

    case "$cmd" in
        connect)
            # windscribe-cli connect [-n] [best|<location>|static <city|ip>] [protocol[:port]]
            if ((ncompleted == 0)); then
                if [[ $cur == *:* ]]; then
                    _windscribe_cli_protocol_candidates "$cur"
                else
                    local candidates=(best static "${_windscribe_cli_protocols[@]}")
                    while IFS= read -r word; do
                        [[ -n $word ]] && candidates+=("$word")
                    done < <(_windscribe_cli_location_list)
                    _windscribe_cli_compgen "$cur" "${candidates[@]}"
                fi
            elif ((ncompleted == 1)); then
                if [[ ${positional[1]} == static ]]; then
                    local candidates=()
                    while IFS= read -r word; do
                        [[ -n $word ]] && candidates+=("$word")
                    done < <(_windscribe_cli_static_list)
                    _windscribe_cli_compgen "$cur" "${candidates[@]}"
                else
                    _windscribe_cli_protocol_candidates "$cur"
                fi
            elif ((ncompleted == 2)); then
                _windscribe_cli_protocol_candidates "$cur"
            else
                COMPREPLY=()
            fi
            ;;
        disconnect|status|update|version|amneziawg)
            COMPREPLY=()
            ;;
        firewall)
            if ((ncompleted == 0)); then _windscribe_cli_compgen "$cur" on off; else COMPREPLY=(); fi
            ;;
        locations)
            if ((ncompleted == 0)); then
                _windscribe_cli_compgen "$cur" fav static
            else
                COMPREPLY=()
            fi
            ;;
        ports)
            if ((ncompleted == 0)); then
                _windscribe_cli_compgen "$cur" "${_windscribe_cli_protocols[@]}"
            else
                COMPREPLY=()
            fi
            ;;
        ip)
            if ((ncompleted == 0)); then
                _windscribe_cli_compgen "$cur" rotate fav unfav
            elif ((ncompleted == 1)) && [[ ${positional[1]} == unfav ]]; then
                local candidates=()
                while IFS= read -r word; do
                    [[ -n $word ]] && candidates+=("$word")
                done < <(_windscribe_cli_fav_ips)
                _windscribe_cli_compgen "$cur" "${candidates[@]}"
            else
                COMPREPLY=()
            fi
            ;;
        login)
            # username is free-form; nothing sensible to complete.
            COMPREPLY=()
            ;;
        logout)
            if ((ncompleted == 0)); then _windscribe_cli_compgen "$cur" on off; else COMPREPLY=(); fi
            ;;
        logs)
            if ((ncompleted == 0)); then _windscribe_cli_compgen "$cur" send; else COMPREPLY=(); fi
            ;;
        keylimit)
            if ((ncompleted == 0)); then _windscribe_cli_compgen "$cur" keep delete; else COMPREPLY=(); fi
            ;;
        ignoresslerrors)
            if ((ncompleted == 0)); then _windscribe_cli_compgen "$cur" on off; else COMPREPLY=(); fi
            ;;
        help)
            if ((ncompleted == 0)); then _windscribe_cli_compgen "$cur" "${_windscribe_cli_commands[@]}"; else COMPREPLY=(); fi
            ;;
        *)
            _windscribe_cli_compgen "$cur" "${_windscribe_cli_commands[@]}"
            ;;
    esac
}

complete -F _windscribe_cli windscribe-cli
