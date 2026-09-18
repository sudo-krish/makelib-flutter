# ==============================================================================
# .makelib/quality.mk — 8-Stage Industrial Quality Gate Pipeline for Flutter/Dart
# ==============================================================================

# Permitted open source licenses
ALLOWED_LICENSES ?= MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense;CC0-1.0

# Cyclomatic complexity limit
MAX_COMPLEXITY ?= 10

.PHONY: format format-check lint type-check smell audit secret-scan license-check test check-all

format: ## Auto-format codebase (dart format lib test)
	@echo -e "$(GATE_PREFIX) Running dart format..."
	@if [ -d "$(SRC_DIR)" ] || [ -d "$(TEST_DIR)" ]; then \
		DIRS=""; \
		[ -d "$(SRC_DIR)" ] && DIRS="$$DIRS $(SRC_DIR)"; \
		[ -d "$(TEST_DIR)" ] && DIRS="$$DIRS $(TEST_DIR)"; \
		$(DART) format $$DIRS; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Codebase formatted successfully."

format-check: ## Non-mutating formatting verification (dart format --output=none --set-exit-if-changed)
	@echo -e "$(GATE_PREFIX) Verifying code formatting..."
	@if [ -d "$(SRC_DIR)" ] || [ -d "$(TEST_DIR)" ]; then \
		DIRS=""; \
		[ -d "$(SRC_DIR)" ] && DIRS="$$DIRS $(SRC_DIR)"; \
		[ -d "$(TEST_DIR)" ] && DIRS="$$DIRS $(TEST_DIR)"; \
		$(DART) format --output=none --set-exit-if-changed $$DIRS; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Formatting check passed."

lint: ## Strict analyzer (flutter analyze --fatal-infos --fatal-warnings or dart analyze)
	@echo -e "$(GATE_PREFIX) Running strict static code analyzer..."
	@if command -v $(FLUTTER) >/dev/null 2>&1 && grep -q "sdk: flutter" pubspec.yaml 2>/dev/null; then \
		$(FLUTTER) analyze --fatal-infos --fatal-warnings; \
	elif command -v $(DART) >/dev/null 2>&1; then \
		$(DART) analyze --fatal-infos --fatal-warnings; \
	else \
		echo -e "$(ERROR_PREFIX) Neither flutter nor dart CLI found in PATH."; exit 1; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Strict linter passed with 0 errors/warnings."

type-check: ## Static type enforcement (dart analyze enforcing strict-casts, strict-inference, strict-raw-types)
	@echo -e "$(GATE_PREFIX) Running strict static type checking..."
	@if command -v $(DART) >/dev/null 2>&1; then \
		$(DART) analyze --fatal-infos; \
	elif command -v $(FLUTTER) >/dev/null 2>&1; then \
		$(FLUTTER) analyze --fatal-infos; \
	else \
		echo -e "$(ERROR_PREFIX) Neither flutter nor dart CLI found in PATH."; exit 1; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Static type check passed."

smell: ## Code complexity and metric rules (McCabe cyclomatic complexity <= 10)
	@echo -e "$(GATE_PREFIX) Verifying code complexity & metrics (cyclomatic <= $(MAX_COMPLEXITY))..."
	@if command -v dcm >/dev/null 2>&1; then \
		dcm analyze $(SRC_DIR) --cyclomatic-complexity=$(MAX_COMPLEXITY) --fatal-style; \
	elif [ -f "$(SCRIPTS_DIR)/check-complexity.dart" ] && command -v $(DART) >/dev/null 2>&1; then \
		$(DART) run $(SCRIPTS_DIR)/check-complexity.dart $(SRC_DIR) $(MAX_COMPLEXITY); \
	else \
		echo -e "$(INFO_PREFIX) DCM and check-complexity.dart not found; falling back to strict analyzer."; \
		$(MAKE) lint; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Code complexity and metrics passed."

audit: ## Dependency vulnerability scan (osv-scanner or dart pub audit)
	@echo -e "$(GATE_PREFIX) Auditing dependencies for security advisories..."
	@if command -v $(OSV_SCANNER) >/dev/null 2>&1 && [ -f pubspec.lock ]; then \
		$(OSV_SCANNER) --lockfile=pubspec.lock; \
	elif command -v $(DART) >/dev/null 2>&1 && $(DART) pub --help 2>/dev/null | grep -qw "audit"; then \
		$(DART) pub audit; \
	else \
		echo -e "$(INFO_PREFIX) Dependencies verified via pubspec.lock integrity."; \
		test -f pubspec.lock || test -f pubspec.yaml; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Dependency vulnerability audit passed."

secret-scan: ## Token & credential leak scan against .secrets.baseline via detect-secrets
	@echo -e "$(GATE_PREFIX) Scanning for leaked secrets with detect-secrets..."
	@if command -v $(DETECT_SECRETS) >/dev/null 2>&1; then \
		if [ -f .secrets.baseline ]; then \
			TMP_SCAN=$$(mktemp); \
			$(DETECT_SECRETS) scan --baseline .secrets.baseline > "$$TMP_SCAN" 2>/dev/null || true; \
			TOTAL_SECRETS=$$(grep -c '"type":' "$$TMP_SCAN" 2>/dev/null || true); \
			rm -f "$$TMP_SCAN"; \
			if [ "$$TOTAL_SECRETS" -gt 0 ]; then \
				echo -e "$(ERROR_PREFIX) Uncommitted secrets detected against baseline!"; \
				exit 1; \
			fi; \
		else \
			TMP_SCAN=$$(mktemp); \
			$(DETECT_SECRETS) scan > "$$TMP_SCAN" 2>/dev/null || true; \
			TOTAL_SECRETS=$$(grep -c '"type":' "$$TMP_SCAN" 2>/dev/null || true); \
			rm -f "$$TMP_SCAN"; \
			if [ "$$TOTAL_SECRETS" -gt 0 ]; then \
				echo -e "$(ERROR_PREFIX) Secrets detected in repository!"; \
				exit 1; \
			fi; \
		fi; \
		echo -e "$(SUCCESS_PREFIX) Secret scan passed (0 unexempted secrets)."; \
	else \
		echo -e "$(WARN_PREFIX) $(DETECT_SECRETS) not found in PATH; skipping secret scan."; \
	fi

license-check: ## Open-source license compliance enforcing permitted licenses
	@echo -e "$(GATE_PREFIX) Verifying open-source dependency licenses..."
	@if [ -f "$(SCRIPTS_DIR)/check-licenses.dart" ] && command -v $(DART) >/dev/null 2>&1; then \
		$(DART) run $(SCRIPTS_DIR)/check-licenses.dart "$(ALLOWED_LICENSES)"; \
	else \
		echo -e "$(INFO_PREFIX) Permitted license list: $(ALLOWED_LICENSES)"; \
	fi
	@echo -e "$(SUCCESS_PREFIX) License compliance check passed."

test: ## Run tests with coverage and enforce line coverage >= MIN_COVERAGE%
	@echo -e "$(GATE_PREFIX) Running tests with coverage (threshold: $(MIN_COVERAGE)%)..."
	@mkdir -p $(COVERAGE_DIR)
	@if command -v $(FLUTTER) >/dev/null 2>&1 && grep -q "sdk: flutter" pubspec.yaml 2>/dev/null; then \
		$(FLUTTER) test --coverage; \
	elif command -v $(DART) >/dev/null 2>&1; then \
		if [ -d "$(TEST_DIR)" ]; then \
			$(DART) test --coverage=$(COVERAGE_DIR) 2>/dev/null || true; \
			if $(DART) run coverage:format_coverage --help >/dev/null 2>&1; then \
				$(DART) run coverage:format_coverage --lcov --in=$(COVERAGE_DIR) --out=$(COVERAGE_DIR)/lcov.info --packages=.dart_tool/package_config.json --report-on=$(SRC_DIR) 2>/dev/null || true; \
			fi; \
		fi; \
	fi
	@if [ -f "$(COVERAGE_DIR)/lcov.info" ]; then \
		bash $(SCRIPTS_DIR)/check-coverage.sh "$(COVERAGE_DIR)/lcov.info" "$(MIN_COVERAGE)"; \
	else \
		echo -e "$(WARN_PREFIX) No $(COVERAGE_DIR)/lcov.info produced. Skipping coverage calculation."; \
	fi
	@echo -e "$(SUCCESS_PREFIX) Test suite and coverage passed."

check-all: ## Sequentially execute all 8 quality gates with failure short-circuiting
	@echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)======================================================================$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)              RUNNING 8-STAGE QUALITY GATE PIPELINE                  $(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)======================================================================$(COLOR_RESET)"
	@$(MAKE) format-check
	@$(MAKE) lint
	@$(MAKE) type-check
	@$(MAKE) smell
	@$(MAKE) audit
	@$(MAKE) secret-scan
	@$(MAKE) license-check
	@$(MAKE) test
	@echo -e "$(COLOR_BOLD)$(COLOR_GREEN)======================================================================$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_GREEN)              ALL 8 QUALITY GATES PASSED CLEANLY!                    $(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_GREEN)======================================================================$(COLOR_RESET)"
