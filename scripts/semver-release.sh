#!/usr/bin/env bash
# ==============================================================================
# scripts/semver-release.sh — SemVer Release Automation for pubspec.yaml
# ==============================================================================
set -euo pipefail

COLOR_CYAN="\033[36m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

PUBSPEC_FILE="${PUBSPEC_FILE:-pubspec.yaml}"

get_current_version() {
  if [ ! -f "$PUBSPEC_FILE" ]; then
    echo -e "${COLOR_RED}[ERROR] File not found: ${PUBSPEC_FILE}${COLOR_RESET}" >&2
    exit 1
  fi
  grep '^version:' "$PUBSPEC_FILE" | head -n 1 | awk '{print $2}' | tr -d '\r"'
}

get_current_branch() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
  else
    echo ""
  fi
}

classify_branch() {
  local branch="${1:-$(get_current_branch)}"
  case "$branch" in
    major/*|breaking/*)
      echo "major"
      ;;
    feat/*|feature/*)
      echo "minor"
      ;;
    fix/*|patch/*|docs/*|chore/*|refactor/*|ci/*)
      echo "patch"
      ;;
    *)
      echo "patch"
      ;;
  esac
}

calculate_bump() {
  local cur_ver="$1"
  local bump_type="$2"

  local semver=""
  local build_num=""

  if [[ "$cur_ver" == *"+"* ]]; then
    semver="${cur_ver%%+*}"
    build_num="${cur_ver##*+}"
  else
    semver="$cur_ver"
    build_num=""
  fi

  local major minor patch
  IFS='.' read -r major minor patch <<< "$semver"

  case "$bump_type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      echo -e "${COLOR_RED}[ERROR] Invalid bump level: ${bump_type}. Expected major, minor, or patch.${COLOR_RESET}" >&2
      exit 1
      ;;
  esac

  if [ -n "$build_num" ]; then
    build_num=$((build_num + 1))
    echo "${major}.${minor}.${patch}+${build_num}"
  else
    echo "${major}.${minor}.${patch}"
  fi
}

apply_bump() {
  local bump_type="$1"
  local cur_ver
  cur_ver=$(get_current_version)
  local new_ver
  new_ver=$(calculate_bump "$cur_ver" "$bump_type")

  # Replace version in pubspec.yaml safely
  sed -i "s/^version: .*/version: ${new_ver}/" "$PUBSPEC_FILE"
  echo "$new_ver"
}

# CLI Argument Router
COMMAND="${1:---help}"

case "$COMMAND" in
  --current)
    get_current_version
    ;;
  --level)
    classify_branch "${2:-}"
    ;;
  --classify)
    BRANCH="${2:-$(get_current_branch)}"
    LEVEL=$(classify_branch "$BRANCH")
    echo -e "${COLOR_CYAN}[RELEASE CLASSIFICATION]${COLOR_RESET}"
    echo -e "  Branch: ${COLOR_BOLD}${BRANCH}${COLOR_RESET}"
    echo -e "  SemVer Level: ${COLOR_BOLD}${COLOR_GREEN}${LEVEL^^}${COLOR_RESET}"
    case "$LEVEL" in
      major) echo -e "  Impact: Breaking changes (increments X.0.0)" ;;
      minor) echo -e "  Impact: New features (increments x.Y.0)" ;;
      patch) echo -e "  Impact: Bug fixes, docs, chores (increments x.y.Z)" ;;
    esac
    ;;
  --bump)
    LEVEL="${2:-$(classify_branch)}"
    apply_bump "$LEVEL"
    ;;
  *)
    echo "Usage: $0 {--current|--level|--classify [branch]|--bump <major|minor|patch>}"
    exit 1
    ;;
esac
