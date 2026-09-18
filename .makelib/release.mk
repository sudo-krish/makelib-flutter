# ==============================================================================
# .makelib/release.mk — SemVer Release Automation for Flutter/Dart
# ==============================================================================

.PHONY: bump-patch bump-minor bump-major release-classify release-bump release

bump-patch: ## Increment patch version (x.y.Z) in pubspec.yaml
	@echo -e "$(INFO_PREFIX) Bumping patch version in pubspec.yaml..."
	@NEW_VER=$$(bash $(SCRIPTS_DIR)/semver-release.sh --bump patch); \
	echo -e "$(SUCCESS_PREFIX) Version bumped to: $$NEW_VER"

bump-minor: ## Increment minor version (x.Y.0) in pubspec.yaml
	@echo -e "$(INFO_PREFIX) Bumping minor version in pubspec.yaml..."
	@NEW_VER=$$(bash $(SCRIPTS_DIR)/semver-release.sh --bump minor); \
	echo -e "$(SUCCESS_PREFIX) Version bumped to: $$NEW_VER"

bump-major: ## Increment major version (X.0.0) in pubspec.yaml
	@echo -e "$(INFO_PREFIX) Bumping major version in pubspec.yaml..."
	@NEW_VER=$$(bash $(SCRIPTS_DIR)/semver-release.sh --bump major); \
	echo -e "$(SUCCESS_PREFIX) Version bumped to: $$NEW_VER"

release-classify: ## Classify SemVer release level from current branch
	@bash $(SCRIPTS_DIR)/semver-release.sh --classify

release-bump: ## Increment SemVer based on current branch classification
	@BUMP_LEVEL=$$(bash $(SCRIPTS_DIR)/semver-release.sh --level); \
	case "$$BUMP_LEVEL" in \
		major) $(MAKE) bump-major ;; \
		minor) $(MAKE) bump-minor ;; \
		patch) $(MAKE) bump-patch ;; \
		*) echo -e "$(ERROR_PREFIX) Unknown bump level: $$BUMP_LEVEL"; exit 1 ;; \
	esac

release: check-all ## Run check-all, bump version from branch, commit pubspec and tag vX.Y.Z
	@echo -e "$(INFO_PREFIX) Initiating automated release pipeline..."
	@$(MAKE) release-bump
	@NEW_VERSION=$$(bash $(SCRIPTS_DIR)/semver-release.sh --current); \
	TAG_NAME="v$${NEW_VERSION%%+*}"; \
	echo -e "$(INFO_PREFIX) Creating release commit and git tag for $${TAG_NAME} ($${NEW_VERSION})..."; \
	git add pubspec.yaml pubspec.lock 2>/dev/null || git add pubspec.yaml; \
	git commit -m "chore(release): $${TAG_NAME}" --no-verify; \
	git tag -a "$${TAG_NAME}" -m "Release $${TAG_NAME}"; \
	echo -e "$(SUCCESS_PREFIX) Release $${TAG_NAME} successfully tagged."
