.PHONY: dry_run_dart dry_run_flutter dry_run publish_dart publish_flutter publish

# Reusable function for confirmation
define confirm
	@read -p "Are you sure you want to continue? [y/N] " ans; \
	if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
		echo "Aborted."; \
		exit 1; \
	fi
endef

# Run test
test_dart:
	dart test packages/essential_dart

test_flutter:
	dart test packages/essential_flutter

test:
	@$(MAKE) test_dart
	@$(MAKE) test_flutter

# Dry-run targets
dry_run_dart:
	dart pub -C packages/essential_dart publish --dry-run

dry_run_flutter:
	dart pub -C packages/essential_flutter publish --dry-run

dry_run: dry_run_dart dry_run_flutter

# Actual publish targets
publish_dart:
	dart test packages/essential_dart && dart pub -C packages/essential_dart publish

publish_flutter:
	flutter test packages/essential_flutter && dart pub -C packages/essential_flutter publish

publish:
	$(confirm)
	@$(MAKE) publish_dart
	@$(MAKE) publish_flutter


# Apply dart fix to targets
fix_dart:
	dart fix packages/essential_dart --apply

fix_flutter:
	dart fix packages/essential_flutter --apply

fix:
	$(confirm)
	@$(MAKE) fix_dart
	@$(MAKE) fix_flutter
