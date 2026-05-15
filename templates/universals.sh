#!/usr/bin/env bash
# universals.sh: canonical source for tagged universal code blocks.
# This file is never executed directly.
# Each tag::universal-<slug>[] block is synced verbatim into scripts that:
# (1) declare the identical tag lines AND
# (2) are registered in their project's docopslab-dev.yml manifest.
# Edit only here, then run the sync tooling to propagate changes.

# tag::universal-style-helpers[]
# Respects NO_COLOR standard: https://no-color.org
_bold() { [[ -n "${NO_COLOR:-}" ]] && printf '%s' "$*" || printf '\033[1m%s\033[0m' "$*"; }
_green() { [[ -n "${NO_COLOR:-}" ]] && printf '%s' "$*" || printf '\033[32m%s\033[0m' "$*"; }
_yellow() { [[ -n "${NO_COLOR:-}" ]] && printf '%s' "$*" || printf '\033[33m%s\033[0m' "$*"; }
_red() { [[ -n "${NO_COLOR:-}" ]] && printf '%s' "$*" || printf '\033[31m%s\033[0m' "$*"; }
_tick()     { printf '%s %s\n' "$(_green '✓')" "$*"; }
_warn()     { printf '%s %s\n' "$(_yellow '⚠')" "$*"; }
_fail()     { printf '%s %s\n' "$(_red '✗')" "$*"; }
_info()     { printf '  %s\n' "$*"; }
_sep()      { printf '%s\n' "────────────────────────────────────────────────"; }
_run_echo() { printf '\n%s %s\n\n' "$(_bold '▶')" "$(_bold "$*")"; }
# end::universal-style-helpers[]

# tag::universal-resolve-script-dir[]
# shellcheck disable=SC2034 # exported; read by callers that source this block
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# end::universal-resolve-script-dir[]

# tag::universal-package-managers[]
# Detect all available package managers and print results to stdout.
# Returns non-zero if none are found.
#
# Usage: _package_managers [FORMAT]
#   FORMAT  cli   (default) — print the binary name: apt, brew, nix
#           name            — print the display name: APT, Homebrew, Nix
#           both            — print tab-separated cli<TAB>Name pairs
#
# Output is in priority order (native system managers before cross-platform).
# With two or more managers found, all are printed; callers decide what to do.
#
# Parse 'both' output at a call site:
#   while IFS=$'\t' read -r cli name; do ...; done < <(_package_managers both)
_package_managers() {
  local format="${1:-cli}"
  # Ordered by priority: native system managers first, cross-platform last.
  local -a priority=(apt dnf pacman zypper dpkg rpm brew nix)
  declare -A display_names=(
    [apt]="APT" [dnf]="DNF" [pacman]="Pacman" [zypper]="Zypper"
    [dpkg]="dpkg" [rpm]="RPM" [brew]="Homebrew" [nix]="Nix"
  )
  local found=()
  for cli in "${priority[@]}"; do
    command -v "$cli" &>/dev/null && found+=("$cli")
  done
  [[ ${#found[@]} -eq 0 ]] && return 1
  for cli in "${found[@]}"; do
    case "$format" in
      cli)  printf '%s\n' "$cli" ;;
      name) printf '%s\n' "${display_names[$cli]}" ;;
      both) printf '%s\t%s\n' "$cli" "${display_names[$cli]}" ;;
    esac
  done
}

# Select the primary package manager for install operations.
# Prints the CLI name of the highest-priority detected manager.
# Returns non-zero if no supported manager is found.
# Use _package_managers to get the full list.
_package_manager() {
  _package_managers cli | head -n1 || {
    printf 'Error: no supported package manager found.\n' >&2
    return 1
  }
}
# end::universal-package-managers[]

# tag::universal-run-as-root[]
_run_as_root() {
  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    printf 'Error: not root and sudo unavailable. Cannot run: %s\n' "$*" >&2
    return 1
  fi
}
# end::universal-run-as-root[]

# tag::universal-fetch[]
_fetch() {
  if command -v curl &>/dev/null; then
    curl -fsSL "$1"
  elif command -v wget &>/dev/null; then
    wget -qO- "$1"
  else
    _fail "Neither curl nor wget found. Install one and try again."
    exit 1
  fi
}
# end::universal-fetch[]