#!/usr/bin/env bash
set -euo pipefail

CONFIG="${TMUX_CONFIG:-/root/tartan_rgbt_ws/docker/tmux_config.yaml}"


# helper: run a list of commands in the targeted tmux pane
run_cmds() {
  local target="$1"; shift
  # join commands with ' && ' so failures stop the chain
  local joined; joined=$(printf ' && %s' "$@"); joined="${joined#' && '}"
  tmux send-keys -t "$target" "$joined" C-m
}

if command -v tmux >/dev/null 2>&1 && command -v yq >/dev/null 2>&1 && [[ -f "$CONFIG" ]]; then
  set +e

  SESSION=$(yq e '.session_name // "session"' "$CONFIG")
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    # windows array length
    COUNT=$(yq e '.windows | length // 0' "$CONFIG")

    if [[ "$COUNT" -eq 0 ]]; then
      echo "WARN: No windows in $CONFIG; starting empty tmux session."
      tmux new-session -d -s "$SESSION" -n "shell"
    else
      # Create first window
      W0_NAME=$(yq e '.windows[0].window_name // "win-0"' "$CONFIG")
      tmux new-session -d -s "$SESSION" -n "$W0_NAME"

      # panes for first window
      PCOUNT=$(yq e '.windows[0].panes | length // 0' "$CONFIG")
      if [[ "$PCOUNT" -gt 0 ]]; then
        # create remaining panes
        for ((p=1; p<PCOUNT; p++)); do
          tmux split-window -t "${SESSION}:0" -h
        done
        tmux select-layout -t "${SESSION}:0" tiled >/dev/null 2>&1 || true

        # run pane commands
        for ((p=0; p<PCOUNT; p++)); do
          # collect the shell_command array for pane p
          mapfile -t CMDS < <(yq e ".windows[0].panes[$p].shell_command[]" "$CONFIG" 2>/dev/null)
          # default to a login shell if empty
          if [[ "${#CMDS[@]}" -eq 0 ]]; then CMDS=("bash -lc 'exec bash'"); fi
          run_cmds "${SESSION}:0.$p" "${CMDS[@]}"
        done
      fi

      # Remaining windows
      for ((i=1; i<COUNT; i++)); do
        WNAME=$(yq e ".windows[$i].window_name // \"win-$i\"" "$CONFIG")
        tmux new-window -t "$SESSION" -n "$WNAME"
        PCOUNT=$(yq e ".windows[$i].panes | length // 0" "$CONFIG")

        if [[ "$PCOUNT" -gt 0 ]]; then
          for ((p=1; p<PCOUNT; p++)); do
            tmux split-window -t "${SESSION}:$i" -h
          done
          # layout
          LAYOUT=$(yq e ".windows[$i].layout // \"\"" "$CONFIG")
          if [[ -n "$LAYOUT" ]]; then
            tmux select-layout -t "${SESSION}:$i" "$LAYOUT" >/dev/null 2>&1 || true
          else
            tmux select-layout -t "${SESSION}:$i" tiled >/dev/null 2>&1 || true
          fi

          for ((p=0; p<PCOUNT; p++)); do
            mapfile -t CMDS < <(yq e ".windows[$i].panes[$p].shell_command[]" "$CONFIG" 2>/dev/null)
            if [[ "${#CMDS[@]}" -eq 0 ]]; then CMDS=("bash -lc 'exec bash'"); fi
            run_cmds "${SESSION}:$i.$p" "${CMDS[@]}"
          done
        fi
      done
    fi
  fi

  set -e
else
  echo "INFO: Skipping tmux bootstrap (missing tmux/yq or $CONFIG)."
fi
tmux set -g mouse on

# Handle shutdown
trap 'tmux kill-server >/dev/null 2>&1 || true; exit 0' SIGTERM SIGINT

# Keep PID 1 alive
exec tail -f /dev/null
