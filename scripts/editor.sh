#!/usr/bin/env bash
# A script that opens nvim from lazygit, if it was opened from a tmux pane, checks
# if exists a nvim remote server for that pane

# "editor.sh {{editor}} {{filename}} {{line}}"

FILENAME=$1
LINE=${2:-0}

resolve_origin_pane() {
    local pane_from_option
    pane_from_option=$(tmux show-option -qv "@neolazygit_origin_pane" 2>/dev/null)

    if [ -n "$pane_from_option" ]; then
        echo "$pane_from_option"
        return
    fi

    if [ -n "$LAZYGIT_ORIGIN_PANE" ]; then
        echo "$LAZYGIT_ORIGIN_PANE"
    fi
}

ORIGIN_PANE="$(resolve_origin_pane)"

# Check if there's a nvim instance in the origin pane and 'returns' its server socket,
# otherwise returns 0
get_nvim_socket () {
    if [ -z "$ORIGIN_PANE" ]; then
        echo 0
        return
    fi

    local pid_of_origin
    pid_of_origin=$(tmux list-panes -sF "#{pane_pid}" \
                            -f "#{m:#{pane_id},${ORIGIN_PANE}}")

    if [ -z "$pid_of_origin" ]; then
        echo 0
        return
    fi

    # Gets all "nvim" processes running in the pane of origin
    NVIM_PIDS=$(pstree -paT "$pid_of_origin" | \
        grep -E .\+nvim, | \
        cut -d, -f2 | \
        cut -d" " -f1)

    # Find the first PID that has an nvim socket assigned
    for nvim_pid in $NVIM_PIDS; do
        if [ -z "$XDG_RUNTIME_DIR" ]; then
            break
        fi

        for nvim_socket in "${XDG_RUNTIME_DIR}"/nvim*; do
            [ -e "$nvim_socket" ] || continue

            case "$nvim_socket" in
                *"$nvim_pid"*)
                    echo "$nvim_socket"
                    return
                    ;;
            esac
        done
    done

    echo 0
}

focus_nvim() {
    if [ -z "$ORIGIN_PANE" ]; then
        return
    fi

    local origin_window_id
    origin_window_id=$(tmux list-panes -sF "#{window_id}" -f "#{m:#D,${ORIGIN_PANE}}")

    if [ -z "$origin_window_id" ]; then
        return
    fi

    tmux selectw -t "$origin_window_id"
    tmux selectp -t "$ORIGIN_PANE"
}


main() {
    local socket
    socket=$(get_nvim_socket)
    # If no socket, it means no nvim, so just open inside lazygit ;)
    if [[ $socket == 0 ]]; then
        nvim +"$LINE" "$FILENAME"
        exit 0
    fi

    focus_nvim

    # Opens the file remotely in the expected line
    nvim --server "$socket" --remote "$(realpath "$FILENAME")"
    nvim --server "$socket" --remote-send "<ESC>${LINE}gg"
}

main
