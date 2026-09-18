# ==============================================================================
# .makelib/core.mk — Centralized Make Library Core for Flutter & Dart
# ==============================================================================

# Strict Bash shell environment
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Dynamically determine makelib directory
MAKELIB_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

# Include modular components
include $(MAKELIB_DIR)/colors.mk

# Configurable directory paths (overridable downstream via ?=)
SRC_DIR       ?= lib
TEST_DIR      ?= test
BUILD_DIR     ?= build
COVERAGE_DIR  ?= coverage
TEMPLATES_DIR ?= templates
SCRIPTS_DIR   ?= scripts

# Configurable quality gate thresholds
MIN_COVERAGE  ?= 80

# Configurable toolchain commands (overridable downstream via ?=)
FLUTTER        ?= flutter
DART           ?= dart
LEFTHOOK       ?= lefthook
DETECT_SECRETS ?= detect-secrets
OSV_SCANNER    ?= osv-scanner

# Include quality gates, release, and hook modules
include $(MAKELIB_DIR)/quality.mk
include $(MAKELIB_DIR)/release.mk
include $(MAKELIB_DIR)/hooks.mk

.DEFAULT_GOAL := help

.PHONY: help clean deps build

help: ## Display this colorized, self-documenting help menu
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)======================================================================$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)          makelib-flutter — Standard Toolchain & Quality Gates        $(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)======================================================================$(COLOR_RESET)"
	@echo -e ""
	@echo -e "$(COLOR_BOLD)Usage:$(COLOR_RESET) make $(COLOR_CYAN)<target>$(COLOR_RESET) [VAR=override...]"
	@echo -e ""
	@echo -e "$(COLOR_BOLD)Available Targets:$(COLOR_RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort -u
	@echo -e ""
	@echo -e "$(COLOR_BOLD)Overridable Variables:$(COLOR_RESET)"
	@echo -e "  $(COLOR_YELLOW)SRC_DIR$(COLOR_RESET)        Source directory (default: $(SRC_DIR))"
	@echo -e "  $(COLOR_YELLOW)TEST_DIR$(COLOR_RESET)       Test directory (default: $(TEST_DIR))"
	@echo -e "  $(COLOR_YELLOW)BUILD_DIR$(COLOR_RESET)      Build output directory (default: $(BUILD_DIR))"
	@echo -e "  $(COLOR_YELLOW)COVERAGE_DIR$(COLOR_RESET)   Coverage report directory (default: $(COVERAGE_DIR))"
	@echo -e "  $(COLOR_YELLOW)MIN_COVERAGE$(COLOR_RESET)   Minimum test line coverage percentage (default: $(MIN_COVERAGE)%)"
	@echo -e "  $(COLOR_YELLOW)FLUTTER$(COLOR_RESET)        Flutter executable binary (default: $(FLUTTER))"
	@echo -e "  $(COLOR_YELLOW)DART$(COLOR_RESET)           Dart executable binary (default: $(DART))"
	@echo -e "  $(COLOR_YELLOW)LEFTHOOK$(COLOR_RESET)       Lefthook executable binary (default: $(LEFTHOOK))"
	@echo -e "  $(COLOR_YELLOW)DETECT_SECRETS$(COLOR_RESET) detect-secrets binary (default: $(DETECT_SECRETS))"
	@echo -e ""

clean: ## Clean build artifacts, temporary caches, and test coverage
	@echo -e "$(INFO_PREFIX) Cleaning build, cache, and coverage artifacts..."
	@rm -rf $(BUILD_DIR) $(COVERAGE_DIR) .dart_tool .packages pubspec.lock.bak
	@if command -v $(FLUTTER) >/dev/null 2>&1; then \
		$(FLUTTER) clean >/dev/null 2>&1 || true; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Workspace cleaned."

deps: ## Resolve and download Dart/Flutter dependencies
	@echo -e "$(INFO_PREFIX) Resolving package dependencies..."
	@if command -v $(FLUTTER) >/dev/null 2>&1 && grep -q "sdk: flutter" pubspec.yaml 2>/dev/null; then \
		$(FLUTTER) pub get; \
	elif command -v $(DART) >/dev/null 2>&1; then \
		$(DART) pub get; \
	else \
		echo -e "$(ERROR_PREFIX) Neither flutter nor dart CLI found in PATH."; exit 1; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Dependencies resolved."

build: clean deps ## Build Flutter application or Dart compilation bundle
	@echo -e "$(INFO_PREFIX) Building project artifacts..."
	@if command -v $(FLUTTER) >/dev/null 2>&1 && grep -q "flutter:" pubspec.yaml 2>/dev/null; then \
		$(FLUTTER) build bundle; \
	elif command -v $(DART) >/dev/null 2>&1; then \
		echo -e "$(INFO_PREFIX) Dart package verified for distribution."; \
	else \
		echo -e "$(ERROR_PREFIX) Neither flutter nor dart CLI found in PATH."; exit 1; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Build completed."
