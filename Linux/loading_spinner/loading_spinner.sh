#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Spinner Section (TTY-safe, drop into any script)
# ============================================================
# Put your commands between:
#   #### start user commands ####
#   #### end user commands ####
#
# Behavior:
# - Commands run in order.
# - Spinner runs while the whole block is executing.
# - All stdout/stderr from the user command block is captured to an output file.
# - Spinner renders to /dev/tty when available (so it stays visible even with redirection).
#
# Notes:
# - The command extractor intentionally stops at the FIRST end marker so your
#   commands won't run twice if a stray second block gets added later.

SPINNER_FD=2
SPINNER_HAS_TTY=0

_spinner_init_fd() {
  # Prefer drawing to the user's terminal even if stdout/stderr are redirected.
  if [[ -w /dev/tty ]]; then
    exec 3>/dev/tty
    SPINNER_FD=3
    SPINNER_HAS_TTY=1
  else
    SPINNER_FD=2
    [[ -t 2 ]] && SPINNER_HAS_TTY=1 || SPINNER_HAS_TTY=0
  fi
}

spinner_start() {
  local pid="$1"
  local msg="${2:-Working...}"
  local delay="${SPINNER_DELAY:-0.10}"
  local frames=( '|' '/' '-' '\' )
  local i=0

  (( SPINNER_HAS_TTY )) || return 0

  tput civis >&"$SPINNER_FD" 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r[%s] %s" "${frames[i]}" "$msg" >&"$SPINNER_FD"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep "$delay"
  done
  printf "\r\033[K" >&"$SPINNER_FD"
  tput cnorm >&"$SPINNER_FD" 2>/dev/null || true
}

run_with_spinner() {
  local msg="$1"
  shift
  [[ "${1:-}" == "--" ]] && shift

  _spinner_init_fd

  "$@" &
  local cmd_pid=$!

  local old_trap
  old_trap="$(trap -p INT || true)"
  trap 'tput cnorm >&'"$SPINNER_FD"' 2>/dev/null || true; printf "\n" >&'"$SPINNER_FD"'; kill -TERM '"$cmd_pid"' 2>/dev/null || true; exit 130' INT

  spinner_start "$cmd_pid" "$msg"
  wait "$cmd_pid"
  local rc=$?

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
  #   ./script_template_fixed.sh [output_file]
  #
  # Example:
  #   ./script_template_fixed.sh
  #   ./script_template_fixed.sh my_results.out

  local outfile="${1:-script_results.out}"
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

  # Debug (uncomment if you ever suspect double-runs)
   #echo "----- Extracted commands (what will run) -----" >&2
   #printf "%s\n" "$user_cmds" | nl -ba >&2
   #echo "--------------------------------------------" >&2

  # Run the extracted commands under the spinner, capture output to file
  run_with_spinner "Executing Script..." -- bash -euo pipefail -c "$user_cmds" >"$outfile" 2>&1
  local rc=$?

  echo "Script finished (exit $rc). Output saved to: $outfile"
  echo "----------------------------------------"

  return "$rc"
}

main "$@"

#### start user commands ####
echo "starting"

for i in {1..20}; do
  echo "$i"
  sleep 0.5
done

echo "finished"
#### end user commands ####
