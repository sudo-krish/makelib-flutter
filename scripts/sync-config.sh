#!/usr/bin/env bash
# ==============================================================================
# scripts/sync-config.sh — Downstream Toolchain Config Synchronizer
# ==============================================================================
set -euo pipefail

COLOR_CYAN="\033[36m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

MAKELIB_REPO="${MAKELIB_REPO:-sudo-krish/makelib-flutter}"
MAKELIB_REF="${MAKELIB_REF:-main}"
MAKELIB_URL="${MAKELIB_URL:-https://raw.githubusercontent.com/${MAKELIB_REPO}/${MAKELIB_REF}}"
TEMPLATES_DIR="${TEMPLATES_DIR:-templates}"

MODE="${1:-sync}"

# Helper to sync an individual configuration file
sync_file() {
  local src_path="$1"
  local dest_path="$2"
  local skip_if_exists="${3:-false}"

  if [ -f "$dest_path" ]; then
    # Respect downstream override protection markers
    if grep -qE "(NO-OVERRIDE|DO NOT OVERWRITE)" "$dest_path" 2>/dev/null; then
      echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} '${dest_path}' contains NO-OVERRIDE marker. Preserving."
      return 0
    fi
    if [ "$skip_if_exists" = "true" ]; then
      echo -e "${COLOR_CYAN}[EXISTS]${COLOR_RESET} '${dest_path}' already present. Skipping init."
      return 0
    fi
  fi

  mkdir -p "$(dirname "$dest_path")"

  if [ -f "${TEMPLATES_DIR}/${src_path}" ]; then
    cp "${TEMPLATES_DIR}/${src_path}" "$dest_path"
    echo -e "${COLOR_GREEN}[SYNCED]${COLOR_RESET} '${dest_path}' updated from local templates."
  else
    # Fetch from upstream GitHub repository
    local remote_url="${MAKELIB_URL}/templates/${src_path}"
    if curl -fsSL "$remote_url" -o "$dest_path" 2>/dev/null; then
      echo -e "${COLOR_GREEN}[FETCHED]${COLOR_RESET} '${dest_path}' downloaded from ${MAKELIB_REPO}."
    else
      echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} Could not retrieve template '${src_path}'. Skipping."
    fi
  fi
}

echo -e "${COLOR_CYAN}${COLOR_BOLD}[CONFIG SYNC] Synchronizing golden toolchain configurations...${COLOR_RESET}"

# Standard configurations
sync_file "analysis_options.yaml" "analysis_options.yaml"
sync_file ".gitignore" ".gitignore"
sync_file "lefthook.yml" "lefthook.yml"
sync_file ".secrets.baseline" ".secrets.baseline"

# GitHub Actions workflows
sync_file ".github/workflows/ci.yml" ".github/workflows/ci.yml"
sync_file ".github/workflows/release.yml" ".github/workflows/release.yml"
sync_file ".github/workflows/sync-template.yml" ".github/workflows/sync-template.yml"

# Project manifest (only created during init if not already present)
if [ "$MODE" = "--init" ]; then
  sync_file "pubspec.yaml" "pubspec.yaml" "true"
fi

echo -e "${COLOR_GREEN}${COLOR_BOLD}[SUCCESS] Toolchain synchronization complete.${COLOR_RESET}"
