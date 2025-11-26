.PHONY: dry_run_dart dry_run_flutter dry_run publish_dart publish_flutter publish

# Reusable function for confirmation
define confirm
	@read -p "Are you sure you want to continue? [y/N] " ans; \
	if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
		echo "Aborted."; \
		exit 1; \
	fi
endef

# Dry-run targets
dry_run_dart:
	dart pub -C packages/essential_dart publish --dry-run

dry_run_flutter:
	dart pub -C packages/essential_flutter publish --dry-run

dry_run: dry_run_dart dry_run_flutter

# Actual publish targets
publish_dart:
	dart pub -C packages/essential_dart publish

publish_flutter:
	dart pub -C packages/essential_flutter publish

publish:
	$(confirm)
	@$(MAKE) publish_dart
	@$(MAKE) publish_flutter