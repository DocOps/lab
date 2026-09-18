#!/usr/bin/env bash
# universals-smoke.sh: test the tagged blocks in assets/templates/universals.sh
# Requires: python3 for the pseudo-terminal cases; they are skipped when it is unavailable
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UNIVERSALS="${UNIVERSALS_FILE:-$ROOT_DIR/assets/templates/universals.sh}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT INT TERM

pass=0
fail=0
skipped=0

_ok() { pass=$((pass + 1)); }
_bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail + 1)); }

# Usage: _assert_true DESCRIPTION COMMAND [ARGS...]
_assert_true() {
  local desc="$1"
  shift
  if "$@"; then _ok; else _bad "$desc"; fi
}

# Print one tagged block from universals.sh
# Usage: _block NAME
_block() {
  sed -n "/tag::$1\\[\\]/,/end::$1\\[\\]/p" "$UNIVERSALS"
}

_block universal-style-helpers > "$WORK_DIR/style.sh"

# Run a snippet with the style helpers loaded; stdout and stderr go to separate files
# Usage: _run SNIPPET  (results in RUN_OUT and RUN_ERR)
_run() {
  bash -c "source '$WORK_DIR/style.sh'; $1" > "$WORK_DIR/out" 2> "$WORK_DIR/err" || true
  RUN_OUT="$(cat "$WORK_DIR/out")"
  RUN_ERR="$(cat "$WORK_DIR/err")"
}

# STREAM ROUTING (output is captured, so there is no terminal and no color)
_run "_tick ok; _info note; _sep"
_assert_true "tick, info, and sep use stdout" test -n "$RUN_OUT" -a -z "$RUN_ERR"
_run "_warn careful"
_assert_true "warn uses stderr only" test -z "$RUN_OUT" -a "$RUN_ERR" = "⚠ careful"
_run "_fail broken"
_assert_true "fail uses stderr only" test -z "$RUN_OUT" -a "$RUN_ERR" = "✗ broken"
_run "_hint try this"
_assert_true "hint uses stderr only" test -z "$RUN_OUT" -a "$RUN_ERR" = "  try this"
_run "_run_echo docker ps"
_assert_true "run_echo uses stderr only" test -z "$RUN_OUT" -a -n "$RUN_ERR"

# COLOR IS OFF WHEN NOT A TERMINAL
_run "_tick ok; _warn careful; _fail broken; _run_echo cmd; _bold b; _green g"
_assert_true "no escape codes on pipes" bash -c "[[ \"\$1\$2\" != *\$'\\033'* ]]" _ "$RUN_OUT" "$RUN_ERR"

# TOGGLES
_run "DOCOPS_SHOW_WARNINGS=false; _warn hidden"
_assert_true "warnings can be silenced" test -z "$RUN_ERR"
_run "DOCOPS_SHOW_COMMANDS=false; _run_echo hidden"
_assert_true "command echo can be silenced" test -z "$RUN_ERR"
_run "DOCOPS_SHOW_WARNINGS=false; _fail still"
_assert_true "silencing warnings keeps failures" test -n "$RUN_ERR"

# COLOR ON A TERMINAL
if command -v python3 &>/dev/null; then
  # Run a snippet with the style helpers loaded on a pseudo-terminal; print the terminal output
  # Usage: _tty SNIPPET [ENV_ASSIGNMENT...]
  _tty() {
    local snippet="$1"
    shift
    # shellcheck disable=SC2016 # Python source, not a shell expansion
    python3 -c 'import pty, sys; pty.spawn(sys.argv[1:])' \
      env "$@" bash -c "source '$WORK_DIR/style.sh'; $snippet" < /dev/null
  }
  out="$(_tty "_tick ok; _warn careful" TERM=xterm)"
  _assert_true "color appears on a terminal" bash -c "[[ \"\$1\" == *\$'\\033[32m'* && \"\$1\" == *\$'\\033[33m'* ]]" _ "$out"
  out="$(_tty "_tick ok; _warn careful" TERM=xterm NO_COLOR=1)"
  _assert_true "NO_COLOR disables color on a terminal" bash -c "[[ \"\$1\" != *\$'\\033'* ]]" _ "$out"
  out="$(_tty "_tick ok; _warn careful" TERM=dumb)"
  _assert_true "TERM=dumb disables color on a terminal" bash -c "[[ \"\$1\" != *\$'\\033'* ]]" _ "$out"
  # A script whose stdout is piped while stderr stays on the terminal: stdout plain, stderr colored
  # shellcheck disable=SC2016 # Python source, not a shell expansion
  out="$(python3 -c 'import pty, sys; pty.spawn(sys.argv[1:])' env TERM=xterm bash -c \
    "bash -c \"source '$WORK_DIR/style.sh'; _tick ok; _warn careful\" | cat" < /dev/null)"
  _assert_true "piped stdout stays plain" bash -c "[[ \"\$1\" != *\$'\\033[32m'* ]]" _ "$out"
  _assert_true "terminal stderr stays colored" bash -c "[[ \"\$1\" == *\$'\\033[33m'* ]]" _ "$out"
else
  printf 'SKIP: python3 not available; terminal color cases not run\n'
  skipped=1
fi

# SCRIPT DIRECTORY RESOLUTION
mkdir -p "$WORK_DIR/real" "$WORK_DIR/link"
{
  printf '#!/usr/bin/env bash\n'
  _block universal-resolve-script-dir
  # shellcheck disable=SC2016 # the generated script must contain the literal variable names
  printf 'printf "%%s|%%s\\n" "$SCRIPT_DIR" "$SCRIPT_PATH"\n'
} > "$WORK_DIR/real/tool.sh"
chmod +x "$WORK_DIR/real/tool.sh"
ln -s "$WORK_DIR/real/tool.sh" "$WORK_DIR/link/tool"
real_dir="$(cd "$WORK_DIR/real" && pwd -P)"
_assert_true "SCRIPT_DIR from a direct run" test "$("$WORK_DIR/real/tool.sh")" = "$real_dir|$real_dir/tool.sh"
_assert_true "SCRIPT_DIR follows a symlink" test "$("$WORK_DIR/link/tool")" = "$real_dir|$real_dir/tool.sh"

# PACKAGE MANAGER DETECTION (fake managers on a minimal PATH)
mkdir -p "$WORK_DIR/bin"
printf '#!/bin/sh\n' > "$WORK_DIR/bin/apt"
chmod +x "$WORK_DIR/bin/apt"
_block universal-package-managers > "$WORK_DIR/pm.sh"
pm_out="$(PATH="$WORK_DIR/bin" "$BASH" -c "source '$WORK_DIR/pm.sh'; _package_managers cli" 2>&1 || true)"
_assert_true "package manager detection, cli format" test "$pm_out" = "apt"
pm_out="$(PATH="$WORK_DIR/bin" "$BASH" -c "source '$WORK_DIR/pm.sh'; _package_managers name" 2>&1 || true)"
_assert_true "package manager detection, name format" test "$pm_out" = "APT"
pm_out="$(PATH="$WORK_DIR/bin" "$BASH" -c "source '$WORK_DIR/pm.sh'; _package_managers bogus" 2>&1 || true)"
_assert_true "unknown format is rejected" test "$pm_out" = "Error: unknown format: bogus"

printf 'Universals smoke tests: %d passed, %d failed' "$pass" "$fail"
if [[ "$skipped" -eq 1 ]]; then printf ' (terminal cases skipped)'; fi
printf '\n'
[[ "$fail" -eq 0 ]]
