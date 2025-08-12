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

  local WINDOW_NAME
  WINDOW_NAME="LG-${ORIGIN_PANE//%/}"

  # check exist window
  if tmux list-windows -F "#{window_name}" | grep -Fxq "$WINDOW_NAME"; then
    # switch to window
    tmux select-window -t "$WINDOW_NAME"
  else
    # else create new window
    tmux neww -n "$WINDOW_NAME" -c "$CURRENT_PATH" \
      -e LAZYGIT_EDITOR="$LAZYGIT_EDITOR" \
      -e LAZYGIT_ORIGIN_PANE="$ORIGIN_PANE" \
      lazygit \
      -ucf "$LAZYGIT_CONFIG,$CUSTOM_LAZYGIT_CONFIG"
  fi
}

openLazygit
