#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_LAZYGIT_CONFIG="$CURRENT_DIR/../lazygit/config.yml"
LAZYGIT_EDITOR="$CURRENT_DIR/editor.sh"
LAZYGIT_CONFIG="$(lazygit -cd)/config.yml"

openLazygit() {
  local ORIGIN_PANE
  ORIGIN_PANE="$(tmux display-message -p "#D")"

  local CURRENT_PATH
  CURRENT_PATH="$(tmux display-message -p -t "$ORIGIN_PANE" "#{pane_current_path}")"

  local SESSION_NAME
  SESSION_NAME="$(tmux display-message -p "#S")"

  local WINDOW_NAME
  WINDOW_NAME="LG"

  tmux set-option -q @neolazygit_origin_pane "$ORIGIN_PANE"

  local EXISTING_WINDOW
  EXISTING_WINDOW="$(tmux list-windows -t "$SESSION_NAME" -F "#{window_name}" | grep -m1 -E "^${WINDOW_NAME}(-.*)?$" || true)"

  if [ -n "$EXISTING_WINDOW" ]; then
    local TARGET_WINDOW="$EXISTING_WINDOW"

    if [ "$EXISTING_WINDOW" != "$WINDOW_NAME" ]; then
      if tmux rename-window -t "${SESSION_NAME}:${EXISTING_WINDOW}" "$WINDOW_NAME" 2>/dev/null; then
        TARGET_WINDOW="$WINDOW_NAME"
      fi
    fi

    local PANE_STATES
    PANE_STATES="$(tmux list-panes -t "${SESSION_NAME}:${TARGET_WINDOW}" -F "#{pane_dead}" | tr -d '\n')"

    if [ -n "$PANE_STATES" ] && [[ "$PANE_STATES" =~ ^1+$ ]]; then
      tmux kill-window -t "${SESSION_NAME}:${TARGET_WINDOW}"
      tmux neww -t "${SESSION_NAME}:" -n "$WINDOW_NAME" -c "$CURRENT_PATH" \
        -e LAZYGIT_EDITOR="$LAZYGIT_EDITOR" \
        -e LAZYGIT_ORIGIN_PANE="$ORIGIN_PANE" \
        lazygit \
        -ucf "$LAZYGIT_CONFIG,$CUSTOM_LAZYGIT_CONFIG"
    else
      tmux select-window -t "${SESSION_NAME}:${TARGET_WINDOW}"
    fi
  else
    tmux neww -t "${SESSION_NAME}:" -n "$WINDOW_NAME" -c "$CURRENT_PATH" \
      -e LAZYGIT_EDITOR="$LAZYGIT_EDITOR" \
      -e LAZYGIT_ORIGIN_PANE="$ORIGIN_PANE" \
      lazygit \
      -ucf "$LAZYGIT_CONFIG,$CUSTOM_LAZYGIT_CONFIG"
  fi
}

openLazygit
