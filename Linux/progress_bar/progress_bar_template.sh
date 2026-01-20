#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Progress Bar Section (TTY-safe, drop into any script)
# ============================================================
# Put your commands between:
#   #### start user commands ####
#   #### end user commands ####
#
# Behavior:
# - Commands run in order.
# - Progress bar updates based on line count from the command block.
# - All stdout/stderr from the user command block is captured to an output file.
# - Progress bar renders to /dev/tty when available (so it stays visible even with redirection).
#
# Notes:
# - The command extractor intentionally stops at the FIRST end marker so your
#   commands won't run twice if a stray second block gets added later.
# - Progress is estimated by counting output lines vs expected total.

PROGRESS_FD=2
PROGRESS_HAS_TTY=0
BAR_WIDTH=40

_progress_init_fd() {
  # Prefer drawing to the user's terminal even if stdout/stderr are redirected.
  if [[ -w /dev/tty ]]; then
    exec 3>/dev/tty
    PROGRESS_FD=3
    PROGRESS_HAS_TTY=1
  else
    PROGRESS_FD=2
    [[ -t 2 ]] && PROGRESS_HAS_TTY=1 || PROGRESS_HAS_TTY=0
  fi
}

draw_progress_bar() {
  local current="$1"
  local total="$2"
  local msg="${3:-Processing...}"

  (( PROGRESS_HAS_TTY )) || return 0

  local percent=0
  if (( total > 0 )); then
    percent=$(( (current * 100) / total ))
  fi
  (( percent > 100 )) && percent=100

  local filled=$(( (percent * BAR_WIDTH) / 100 ))
  local empty=$(( BAR_WIDTH - filled ))

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  printf "\r%s [%s] %3d%% (%d/%d)" "$msg" "$bar" "$percent" "$current" "$total" >&"$PROGRESS_FD"
}

run_with_progress() {
  local msg="$1"
  local total_lines="$2"
  shift 2
  [[ "${1:-}" == "--" ]] && shift

  _progress_init_fd

  local outfile
  outfile=$(mktemp)

  # Hide cursor
  (( PROGRESS_HAS_TTY )) && tput civis >&"$PROGRESS_FD" 2>/dev/null || true

  # Run command, tee output to temp file while counting lines
  local line_count=0

  # Set up trap for cleanup
  local old_trap
  old_trap="$(trap -p INT || true)"
  trap 'tput cnorm >&'"$PROGRESS_FD"' 2>/dev/null || true; printf "\n" >&'"$PROGRESS_FD"'; rm -f '"$outfile"'; exit 130' INT

  # Execute and track progress
  while IFS= read -r line || [[ -n "$line" ]]; do
    echo "$line" >> "$outfile"
    ((line_count++)) || true
    draw_progress_bar "$line_count" "$total_lines" "$msg"
  done < <("$@" 2>&1)

  local rc=${PIPESTATUS[0]:-0}

  # Complete the bar at 100%
  draw_progress_bar "$total_lines" "$total_lines" "$msg"
  printf "\n" >&"$PROGRESS_FD"

  # Show cursor
  (( PROGRESS_HAS_TTY )) && tput cnorm >&"$PROGRESS_FD" 2>/dev/null || true

  # Output the captured content
  cat "$outfile"
  rm -f "$outfile"

  # Restore previous INT trap (if any)
  if [[ -n "$old_trap" ]]; then
    eval "$old_trap"
  else
    trap - INT
  fi

  return "$rc"
}

# ============================================================
# Main Script (user command block)
# ============================================================
main() {
  # Usage:
  #   ./progress_bar_template.sh [output_file] [expected_lines]
  #
  # Example:
  #   ./progress_bar_template.sh
  #   ./progress_bar_template.sh my_results.out 100

  local outfile="${1:-script_results.out}"
  local expected_lines="${2:-}"
  local script_file="${BASH_SOURCE[0]}"

  # Extract ONLY the first user command block (stop at first end marker).
  local user_cmds
  user_cmds="$(
    awk '
      /^#### start user commands ####/ {inside=1; next}
      inside && /^#### end user commands ####/ {exit}
      inside {print}
    ' "$script_file"
  )"

  # Sanity check
  if [[ -z "${user_cmds//$'\n'/}" ]]; then
    echo "Error: No commands found between the user command markers." >&2
    exit 2
  fi

  # If no expected lines provided, try to estimate from the command block
  # (count echo statements, or default to 100)
  if [[ -z "$expected_lines" ]]; then
    # Try to detect loop ranges like {1..100} or simple echo counts
    local loop_match
    loop_match=$(echo "$user_cmds" | grep -oP '\{1\.\.(\d+)\}' | head -1 | grep -oP '\d+' | tail -1 || true)
    if [[ -n "$loop_match" ]]; then
      expected_lines="$loop_match"
    else
      # Count non-comment, non-empty lines as rough estimate
      expected_lines=$(echo "$user_cmds" | grep -cv '^\s*#\|^\s*$' || echo "10")
    fi
  fi

  # Debug (uncomment if you ever suspect issues)
  # echo "----- Extracted commands (what will run) -----" >&2
  # printf "%s\n" "$user_cmds" | nl -ba >&2
  # echo "--------------------------------------------" >&2
  # echo "Expected lines: $expected_lines" >&2

  # Run the extracted commands with progress bar, capture output to file
  run_with_progress "Executing Script..." "$expected_lines" -- bash -euo pipefail -c "$user_cmds" >"$outfile" 2>&1
  local rc=$?

  echo "Script finished (exit $rc). Output saved to: $outfile"
  echo "----------------------------------------"
  cat "$outfile"

  return "$rc"
}

main "$@"

#### start user commands ####
echo "starting"
for i in {1..100}; do
  echo "$i"
  sleep 0.05
done
echo "finished"
#### end user commands ####
