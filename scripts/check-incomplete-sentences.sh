#!/usr/bin/env bash
# check-incomplete-sentences.sh
#
# Scans AsciiDoc files for potentially incomplete sentences and errant hard returns.
#
# Usage:
#   ./scripts/check-incomplete-sentences.sh [paths...]
#
# If no paths provided, scans common documentation locations.

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default paths to scan if none provided
DEFAULT_PATHS=(
  "_docs/"
  "_blog/"
  "_metablog/"
  "README.adoc"
  "gems/"
  "scripts/"
  "assets/"
)

# Use provided paths or defaults
SCAN_PATHS=("${@:-${DEFAULT_PATHS[@]}}")

echo -e "${BLUE}=== AsciiDoc Incomplete Sentence Checker ===${NC}"
echo ""
echo "Scanning paths: ${SCAN_PATHS[*]}"
echo ""

# Track findings
TOTAL_FINDINGS=0

# Function to scan and report
scan_pattern() {
  local pattern="$1"
  local description="$2"
  local exclude_pattern="${3:-}"
  
  echo -e "${YELLOW}Checking: ${description}${NC}"
  
  # Use a temp file for results to avoid subshell issues
  local temp_results
  temp_results=$(mktemp)
  
  # Build and execute grep command
  if [[ -n "$exclude_pattern" ]]; then
    grep -rn -E "$pattern" "${SCAN_PATHS[@]}" --include='*.adoc' 2>/dev/null | \
      grep -v -E "$exclude_pattern" > "$temp_results" || true
  else
    grep -rn -E "$pattern" "${SCAN_PATHS[@]}" --include='*.adoc' 2>/dev/null > "$temp_results" || true
  fi
  
  # Check if we have results
  if [[ -s "$temp_results" ]]; then
    local count=0
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        echo -e "  ${RED}*${NC} $line"
        count=$((count + 1))
      fi
    done < "$temp_results"
    TOTAL_FINDINGS=$((TOTAL_FINDINGS + count))
  else
    echo -e "  ${GREEN}OK${NC} No issues found"
  fi
  
  rm -f "$temp_results"
  echo ""
}

# Pattern 1: Lines ending with conjunctions
scan_pattern \
  '\s+(and|or|but|yet|so)\s*$' \
  "Lines ending with conjunctions (and, or, but, yet, so)" \
  '(code::|^\s*\*|^\s*\.|^\s*[0-9]+\.)'

# Pattern 2: Lines ending with prepositions  
scan_pattern \
  '\s+(to|of|in|for|with|on|at|by|from|about|as|into|through|during|including|until|against|among|throughout|despite|towards?|upon|concerning|regarding)\s*$' \
  "Lines ending with prepositions" \
  '(code::|^\s*\*|^\s*\.|^\s*[0-9]+\.)'

# Pattern 3: Lines ending with articles
scan_pattern \
  '\s+(a|an|the)\s*$' \
  "Lines ending with articles (a, an, the)" \
  '(code::|^\s*\*|^\s*\.|^\s*[0-9]+\.)'

# Pattern 4: Lines with TODO/FIXME markers
scan_pattern \
  '(\.\.\.|\.\.\.|TODO|FIXME|XXX|TBD|WIP)$' \
  "Lines ending with incomplete markers (TODO, FIXME, etc.)" \
  '(^\s*//|^\s*#|code::|\.\.\.\.)'

# Pattern 5: Lines with mid-sentence placeholders
scan_pattern \
  '(\[TODO\]|\[FIXME\]|\[XXX\]|\[TBD\]|\[INCOMPLETE\])' \
  "Lines with placeholder markers" \
  '(code::|^\s*//|^\s*#)'

echo -e "${BLUE}=== Scan Complete ===${NC}"
echo ""

if [[ $TOTAL_FINDINGS -eq 0 ]]; then
  echo -e "${GREEN}OK - No incomplete sentences found!${NC}"
  exit 0
else
  echo -e "${YELLOW}WARNING: Found $TOTAL_FINDINGS potential issues${NC}"
  echo ""
  echo "Note: Review each finding - some may be intentional (e.g., list"
  echo "continuations, code examples, or stylistic choices)."
  exit 1
fi
