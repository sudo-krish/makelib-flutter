#!/usr/bin/env bash
# ==============================================================================
# scripts/check-coverage.sh — LCOV Line Coverage Parser & Threshold Gate
# ==============================================================================
set -euo pipefail

COLOR_CYAN="\033[36m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

COVERAGE_FILE="${1:-coverage/lcov.info}"
MIN_COVERAGE="${2:-${MIN_COVERAGE:-80}}"

if [ ! -f "$COVERAGE_FILE" ]; then
  echo -e "${COLOR_RED}${COLOR_BOLD}[ERROR] Coverage report not found:${COLOR_RESET} '${COVERAGE_FILE}'"
  echo -e "${COLOR_YELLOW}Run tests with coverage first (e.g., 'make test').${COLOR_RESET}"
  exit 1
fi

# Extract total lines found (LF) and lines hit (LH) across all records
TOTAL_LF=$(grep '^LF:' "$COVERAGE_FILE" | awk -F: '{sum += $2} END {print sum+0}')
TOTAL_LH=$(grep '^LH:' "$COVERAGE_FILE" | awk -F: '{sum += $2} END {print sum+0}')

if [ "$TOTAL_LF" -eq 0 ]; then
  echo -e "${COLOR_YELLOW}${COLOR_BOLD}[WARN] No executable lines found in coverage report (${COVERAGE_FILE}).${COLOR_RESET}"
  exit 0
fi

# Calculate coverage percentage with 2 decimal precision
COVERAGE_PCT=$(awk -v lh="$TOTAL_LH" -v lf="$TOTAL_LF" 'BEGIN {printf "%.2f", (lh / lf) * 100}')

# Check threshold
IS_PASS=$(awk -v cov="$COVERAGE_PCT" -v min="$MIN_COVERAGE" 'BEGIN {print (cov >= min) ? "1" : "0"}')

echo -e "${COLOR_CYAN}[COVERAGE] Total Lines Found (LF):${COLOR_RESET} ${TOTAL_LF}"
echo -e "${COLOR_CYAN}[COVERAGE] Total Lines Hit   (LH):${COLOR_RESET} ${TOTAL_LH}"
echo -e "${COLOR_CYAN}[COVERAGE] Line Coverage Result  :${COLOR_RESET} ${COLOR_BOLD}${COVERAGE_PCT}%${COLOR_RESET} (Required: ${MIN_COVERAGE}%)"

if [ "$IS_PASS" -eq 1 ]; then
  echo -e "${COLOR_GREEN}${COLOR_BOLD}[SUCCESS] Coverage gate passed (${COVERAGE_PCT}% >= ${MIN_COVERAGE}%).${COLOR_RESET}"
  exit 0
else
  echo -e "${COLOR_RED}${COLOR_BOLD}[ERROR] Coverage gate failed!${COLOR_RESET}"
  echo -e "${COLOR_RED}Achieved line coverage (${COVERAGE_PCT}%) is below required threshold (${MIN_COVERAGE}%).${COLOR_RESET}"
  exit 1
fi
