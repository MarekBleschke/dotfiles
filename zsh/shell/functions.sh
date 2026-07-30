# Create a Tmux Dev Layout with editor, ai, and terminal
# Usage: tdl <ai harness>
tdl() {
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tdl."
    return 1
  }

  local current_dir="${PWD}"
  local editor_pane ai_pane terminal_pane
  local ai="${*:-opencode}"

  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  editor_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  # Split window vertically - top 85%, bottom 15% (target editor pane explicitly)
  terminal_pane=$(tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir")

  # Split editor pane horizontally - AI on right 30% (capture new pane ID directly)
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  # Run ai in the right pane
  tmux send-keys -t "$ai_pane" -l "$ai"
  tmux send-keys -t "$ai_pane" C-m

  # Run nvim in the left pane
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
}

# Create a Tmux Dev Square layout with editor, diff watch, terminal, and opencode
# Usage: tds <ai harness>
tds() {
  [[ -z $TMUX ]] && {
    echo "You must start tmux to use tds."
    return 1
  }

  local current_dir="${PWD}"
  local editor_pane diff_pane terminal_pane ai_pane
  local ai="${*:-opencode}"

  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  terminal_pane=$(tmux split-window -v -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  diff_pane=$(tmux split-window -h -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  ai_pane=$(tmux split-window -h -p 50 -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}')

  tmux send-keys -t "$editor_pane" -l "nvim ."
  tmux send-keys -t "$editor_pane" C-m
  tmux send-keys -t "$diff_pane" -l "hunk diff --watch"
  tmux send-keys -t "$diff_pane" C-m
  tmux send-keys -t "$ai_pane" -l "$ai"
  tmux send-keys -t "$ai_pane" C-m
}
