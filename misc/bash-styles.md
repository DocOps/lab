# Bash Coding for Agents

This document is intended for AI agents operating within a DocOps Lab environment.

## File and Script Structure

### Bash Version (4.0)

Use Bash 4.0 or later to take advantage of modern features like associative arrays and improved string manipulation.

### Shebang

Always start scripts with this canonical shebang.

```bash
#!/usr/bin/env bash
```

### Script Header

Follow the shebang with a brief inline comment block covering the script’s purpose and dependencies. Keep it compact: one line per thought, no visual padding.

```bash
#!/usr/bin/env bash
# script-name: brief description of what the script does.
# Depends on: curl, jq
```

### Indentation

Indent with 2 spaces anywhere indentation is called for.

Do not use 4 spaces or tabs.

### Code Organization

Structure your script into logical sections to improve readability.

```bash
#!/usr/bin/env bash
# script-name: brief description.
# Depends on: curl, jq
set -euo pipefail

# CONSTANTS
readonly SCRIPT_VERSION="1.0.0"

# HELPERS
_validate_input() {
  # ...
}

# OPERATIONS
process_data() {
  # ...
}

# COMMANDS
cmd_run() {
  _validate_input "$1"
  process_data "$1"
}

# DISPATCH
case "${1:-}" in
  run) shift; cmd_run "$@" ;;
  *) printf 'Usage: script-name run\n' >&2; exit 1 ;;
esac
```

### Comment Style

Avoid em dashes or en dashes in comments.

Use a colon (`:`) to separate a name from its description.

Use a semicolon (`;`) to combine phrases into a single line when they are closely related.

Example comment styles

```bash
# clobber.sh: A script to overwrite files; use with caution.

# Write config file (first run only; do not clobber user edits)

# path set by init --local; sync uses it instead of git pull
```

### Section Comments

Mark major sections with plain uppercase `#` labels. No decorative dashes or borders needed; the label is sufficient.

```bash
# CONSTANTS
# HELPERS
# COMMANDS
# DISPATCH
```

In longer scripts (several hundred lines or more), a horizontal rule comment may precede a major section label to add visual weight. Use these sparingly.

```bash
# ---------------------------------------------------------------------------
# COMMANDS
# ---------------------------------------------------------------------------
```

## Naming Conventions

### Variables

<dl>
<dt class="hdlist1">Global variables and constants</dt>
<dd>
Use `SCREAMING_SNAKE_CASE`. Use `readonly` for constants.

- `readonly MAX_RETRIES=5`

- `APP_CONFIG_PATH=".env"`
</dd>
<dt class="hdlist1">Local variables</dt>
<dd>
Use `snake_case` and `local` declaration.

- `local user_name="$1"`
</dd>
</dl>

### Functions

<dl>
<dt class="hdlist1">Operation functions</dt>
<dd>
The substantive work of a script; what `cmd_` functions orchestrate, and what sourced libraries export as their callable API. Use unprefixed `snake_case`.

- `evaluate_system()`, `build_docker_image()`, `get_current_version()`
</dd>
<dt class="hdlist1">Helper functions</dt>
<dd>
Prefix internal utility functions with ``. This applies in both standalone scripts and sourced library files. In a sourced library, the `` prefix signals that these functions are implementation details and reduces the risk of collisions in the calling script’s namespace.

- `_bold()`, `_check_help()`, `_resolve_slug()`, `_check_project_root()`
</dd>
<dt class="hdlist1">Subcommand handlers</dt>
<dd>
Prefix functions that implement top-level subcommands with `cmd_`. The dispatch `case` at the bottom of the script maps argument strings to these functions unambiguously.

- `cmd_init()`, `cmd_run()`, `cmd_check()`
</dd>
</dl>

## Variables and Data

### Declaration and Scoping

Always use `local` to declare variables inside functions. This prevents polluting the global scope and avoids unintended side effects.

```bash
_some_action() {
  local file_path="$1" # Good: variable is local to the function
  count=0 # Avoid: variable is global by default
}
```

### Quoting

Always quote variable expansions (`"$variable"`) and command substitutions (`"$(command)"`) to prevent issues with word splitting and unexpected filename expansion (globbing).

```bash
# Good: handles spaces and special characters in filenames
echo "$file_name"
touch "$new_file"

# Avoid: will fail if file_name contains spaces
echo $file_name
touch $new_file
```

> **NOTE:** Names of files created by DocOps Lab should never include spaces, but this habit is important for dealing with user input or external data. Always remember that many of our users come from Windows, where spaces in filenames are common.

### Arrays

Use standard indexed arrays for lists of items.

Use associative arrays (`declare -A`) for key-value pairs (i.e., maps).

```bash
# Indexed array
local -a packages=("git" "curl" "jq")
echo "First package is: ${packages[0]}"

# Associative array
declare -A user_details
user_details["name"]="John Doe"
user_details["email"]="john.doe@example.com"
echo "User email: ${user_details["email"]}"
```

## Functions

### Syntax

Use the `name() { }` syntax. Do not use the `function` keyword; it is redundant in Bash and creates visual inconsistency when mixed with bare definitions.

```bash
# Good
some_action() {
  local arg="$1"
  # ...
}

# Avoid
function some_action() {
  local arg="$1"
  # ...
}
```

Single-line form is acceptable for very short utility functions:

```bash
_bold() { printf '\033[1m%s\033[0m' "$*"; }
```

### Arguments

Access arguments using positional parameters (`$1`, `$2`, etc.). Use `"$@"` to forward all arguments.

```bash
_log_message() {
  local level="$1"
  local message="$2"
  echo "[$level] $message"
}

_log_message "INFO" "Process complete."
```

### Returning Values

**To return a string or data** , use `echo` or `printf` and capture the output using command substitution.

```bash
_get_user_home() {
  local user="$1"
  # ... logic to find home directory ...
  echo "/home/$user" # Returns string via stdout
}
```

**To return a status** , use `return` with a numeric code. `0` means success, and any non-zero value (`1-255`) indicates failure.

```bash
_check_file_exists() {
  if [[-f "$1"]]; then
    return 0 # Success
  else
    return 1 # Failure
  fi
}
```

## Conditionals

Use `[[…​]]` for conditional tests. It is more powerful, prevents many common errors, and is easier to use than the older `[…​]` or `test` builtins.

```bash
# Good
if [["$name" == "admin" && -f "$config_file"]]; then
  # ...
fi

# Avoid
if ["$name" = "admin" -a -f "$config_file"]; then
  # ...
fi
```

For dispatching based on a command or option, `case` statements are often cleaner than long `if/elif/else` chains.

```bash
case "$command" in
  build) cmd_build
    ;;
  run) cmd_run
    ;;
  *)
    printf 'Error: unknown command: %s\n' "$command" >&2
    exit 1
    ;;
esac
```

## Error Handling

Use `set -euo pipefail` at the top of every script.

<dl>
<dt class="hdlist1">`e`</dt>
<dd>
Exit immediately when any command returns a non-zero status.
</dd>
<dt class="hdlist1">`u`</dt>
<dd>
Treat unset variables as an error, catching silent bugs from empty references.
</dd>
<dt class="hdlist1">`o pipefail`</dt>
<dd>
Fail a pipeline if any command within it fails, not just the last one.
</dd>
</dl>

Print error messages to standard error (`stderr`) and exit with a non-zero status.

```bash
#!/usr/bin/env bash
set -euo pipefail

printf 'Error: something went wrong.\n' >&2
exit 1
```

> **NOTE:** Some scripts warrant more selective error handling. A container entrypoint running as PID 1, or a script that sources untrusted config, may use `set -e` alone. Document any deviations and the reason for them.

### Cleanup Traps

For scripts that create temporary resources or modify system state, register a cleanup function with `trap` so those resources are removed whether the script exits normally, fails under `set -e`, or is interrupted.

```bash
_cleanup() {
  [[-n "${tmp_file:-}"]] && rm -f "$tmp_file"
}
trap _cleanup EXIT INT TERM

tmp_file="$(mktemp)"
# ... work with $tmp_file ...
```

> **TIP:** The `EXIT` pseudo-signal fires on both normal exit and on `set -e` termination. Adding `INT` and `TERM` ensures cleanup even when the user presses Ctrl+C or the process is sent SIGTERM.

### Sourced Libraries

Do not place `set -euo pipefail` inside a sourced library file. The calling script owns the error mode. The library’s functions will execute under whatever error mode the caller established.

```bash
#!/usr/bin/env bash
# my-lib.sh; shared helpers sourced by build scripts.
# Do NOT add set -euo pipefail here.

_do_something() {
  # ...
}
```

For file-level variables that a sourced library exports for its callers to read, ShellCheck will emit `SC2034` ("variable appears unused"). Suppress it inline on those specific declarations rather than disabling the check globally.

```bash
# shellcheck disable=SC2034 # exported; read by callers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### Intentional Word-splitting

When a variable genuinely needs to be word-split (ex: an options string passed to a command), suppress the ShellCheck warning inline on that specific line. Add a comment explaining the intent.

```bash
# shellcheck disable=SC2086 # intentional: $docker_args may contain multiple flags
docker build ${docker_args} -t "${image}" .
```

## Output

Prefer `printf` over `echo` for all script output.

- `printf` is predictable, portable across Bash scripts, and supports format strings.

- `echo` behaviour varies across shells and platforms, particularly with `-e` and `-n`.

- Never use `echo -e`.

- Use `printf` with `\n`, or a heredoc.

```bash
# Good
printf 'Error: %s not found.\n' "$name" >&2

# Capture heredoc as a local var
read -r -d '' error_message <<'ERRMSG'
Error: Something went wrong.
Please check your configuration and try again.
ERRMSG
printf '%s\n' "$error_message"

# Avoid
echo -e "Error: $name not found.\n"
```

> **TIP:** Note the use of semantic heredoc delimiters (`ERRMSG`) instead of generic `EOF` or `HEREDOC`.

For output intended for the user (status ticks, warnings, separators), use the shared style helpers from the centrally maintained [`universals.sh`](https://github.com/DocOps/lab/blob/main/gems/docopslab-dev/assets/templates/universals.sh) rather than writing raw ANSI codes inline. See the `universal-style-helpers` tagged segment for the canonical set.

Universal style helpers common to all DocOps Lab scripts

```bash
_bold() { printf '\033[1m%s\033[0m' "$*"; }
_green() { printf '\033[32m%s\033[0m' "$*"; }
_yellow() { printf '\033[33m%s\033[0m' "$*"; }
_red() { printf '\033[31m%s\033[0m' "$*"; }
_tick() { printf '%s %s\n' "$(_green '✓')" "$*"; }
_warn() { printf '%s %s\n' "$(_yellow '⚠')" "$*"; }
_fail() { printf '%s %s\n' "$(_red '✗')" "$*"; }
_info() { printf ' %s\n' "$*"; }
_sep() { printf '%s\n' "────────────────────────────────────────────────"; }
_run_echo() { printf '\n%s %s\n\n' "$(_bold '▶')" "$(_bold "$*")"; }
```

## Practices to Avoid

### Avoid Emojis in Output

Do not use emojis in script output. Use the symbol helpers from `universal-style-helpers` (`_tick`, `_warn`, `_fail`, `_info`) which provide consistent Unicode characters (`✓`, `⚠`, `✗`).

Let’s keep it classy.

```bash
# Good
_tick "Gem built: $gem_file"
_fail "Docker not found."

# Avoid
echo -e "\U2705 Gem built: $gem_file"
echo "❌ Docker not found."
```

### Avoid `eval`

The `eval` command can execute arbitrary code and poses a significant security risk if used with external or user-provided data.

It also makes code difficult to debug.

Avoid it whenever possible. Modern Bash versions provide safer alternatives like namerefs (`declare -n`) for indirect variable/array manipulation.

### Avoid Backticks

Use `$(...)` for command substitution instead of backticks (``...``). It is easier to read and can be nested.

```bash
# Good
current_dir="$(pwd)"

# Avoid
current_dir=`pwd`
```

### Avoid `which`

Use `command -v` to test whether a command is available on the `PATH`.`which` is an external binary whose behavior varies across systems and is not available everywhere.`command -v` is a Bash builtin and the POSIX-portable alternative.

```bash
# Good
if command -v docker &>/dev/null; then
  # ...
fi

# Avoid
if which docker > /dev/null 2>&1; then
  # ...
fi
```

