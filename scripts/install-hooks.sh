#!/usr/bin/env bash
# ==============================================================================
# scripts/install-hooks.sh — Shift-Left Git Hook Installer for makelib-flutter
# ==============================================================================
set -euo pipefail

COLOR_CYAN="\033[36m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

# Ensure we are in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${COLOR_RED}[ERROR] Not inside a git repository. Cannot install hooks.${COLOR_RESET}"
  exit 1
fi

GIT_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="${GIT_ROOT}/.git/hooks"
mkdir -p "$HOOKS_DIR"

# Try installing via Lefthook if available
if command -v lefthook >/dev/null 2>&1; then
  echo -e "${COLOR_CYAN}[INFO] Installing hooks via Lefthook...${COLOR_RESET}"
  lefthook install
  echo -e "${COLOR_GREEN}[SUCCESS] Lefthook hooks installed.${COLOR_RESET}"
else
  echo -e "${COLOR_YELLOW}[WARN] 'lefthook' binary not found. Installing native Git hooks as reliable fallback.${COLOR_RESET}"
fi

# Always install native pre-commit hook as robust fallback
PRE_COMMIT_HOOK="${HOOKS_DIR}/pre-commit"
cat << 'EOF' > "$PRE_COMMIT_HOOK"
#!/usr/bin/env bash
set -euo pipefail

# 1. Enforce shift-left branch policy
if [ -f scripts/check-branch.sh ]; then
  bash scripts/check-branch.sh
fi

# 2. Enforce code formatting
if command -v make >/dev/null 2>&1; then
  make format-check
elif command -v dart >/dev/null 2>&1; then
  dart format --output=none --set-exit-if-changed lib test 2>/dev/null || true
fi

# 3. Strict linter verification
if command -v make >/dev/null 2>&1; then
  make lint
fi
EOF
chmod +x "$PRE_COMMIT_HOOK"
echo -e "${COLOR_GREEN}[SUCCESS] Installed native pre-commit hook: ${PRE_COMMIT_HOOK}${COLOR_RESET}"

# Install native commit-msg hook enforcing conventional commits
COMMIT_MSG_HOOK="${HOOKS_DIR}/commit-msg"
cat << 'EOF' > "$COMMIT_MSG_HOOK"
#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="$1"
FIRST_LINE=$(head -n 1 "$COMMIT_MSG_FILE")

# Allow merge commits
if [[ "$FIRST_LINE" =~ ^Merge ]]; then
  exit 0
fi

# Allow release commits
if [[ "$FIRST_LINE" =~ ^chore\(release\): ]]; then
  exit 0
fi

CONVENTIONAL_REGEX="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._-]+\))?: .+"

if [[ ! "$FIRST_LINE" =~ $CONVENTIONAL_REGEX ]]; then
  echo -e "\033[31m\033[1m[ERROR] Commit message does not follow Conventional Commits standard!\033[0m"
  echo -e "\033[31mMessage received: '${FIRST_LINE}'\033[0m"
  echo -e ""
  echo -e "Expected format: \033[36m<type>(<optional-scope>): <description>\033[0m"
  echo -e "Valid types: \033[36mfeat, fix, docs, style, refactor, perf, test, build, ci, chore, revert\033[0m"
  echo -e "Example: \033[32mfeat(auth): implement token refresh logic\033[0m"
  exit 1
fi
EOF
chmod +x "$COMMIT_MSG_HOOK"
echo -e "${COLOR_GREEN}[SUCCESS] Installed native commit-msg hook: ${COMMIT_MSG_HOOK}${COLOR_RESET}"
echo -e "${COLOR_GREEN}${COLOR_BOLD}[SUCCESS] Shift-left Git hook installation completed.${COLOR_RESET}"
