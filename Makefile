PYTHON ?= python
BUMP_MY_VERSION ?= bump-my-version

.PHONY: release-bump-major release-bump-minor release-bump-patch release-check \
	release-plan release-prepare docs-diagrams docs-diagrams-check

release-bump-major:
	@$(MAKE) --no-print-directory release-bump PART=major

release-bump-minor:
	@$(MAKE) --no-print-directory release-bump PART=minor

release-bump-patch:
	@$(MAKE) --no-print-directory release-bump PART=patch

.PHONY: release-bump
release-bump:
	@case "$(PART)" in major|minor|patch) ;; *) \
		echo "PART must be major, minor, or patch." >&2; exit 2;; \
	esac
	@set -e; new_version="$$($(BUMP_MY_VERSION) show --increment $(PART) new_version)"; \
	$(MAKE) --no-print-directory release-bump-version VERSION="$$new_version"

.PHONY: release-bump-version
release-bump-version:
	@test -n "$(VERSION)" || { echo "VERSION is required." >&2; exit 2; }
	@set -e; bash .github/scripts/release-preflight.sh "$(VERSION)"; \
	$(BUMP_MY_VERSION) bump --new-version "$(VERSION)"

release-plan:
	@bash .github/scripts/release-version.sh

release-prepare:
	@set -e; \
	[[ "$$(git branch --show-current)" == "develop" ]] || \
		{ echo "Release preparation must start from develop." >&2; exit 1; }; \
	[[ -z "$$(git status --porcelain)" ]] || \
		{ echo "Release preparation requires a clean working tree." >&2; exit 1; }; \
	new_version="$$(bash .github/scripts/release-version.sh)"; \
	git flow release start "$$new_version"; \
	$(MAKE) --no-print-directory release-bump-version VERSION="$$new_version"; \
	$(MAKE) --no-print-directory release-check

release-check:
	$(PYTHON) -m pip install --disable-pip-version-check --editable ".[quality,test]"
	$(PYTHON) -m pylint src tests
	ruff format --check src tests
	$(PYTHON) -m mypy
	$(PYTHON) -m pytest --ignore=tests/integration --cov=src --cov-report=term-missing
	$(PYTHON) -m pytest tests/integration
	$(PYTHON) -m build
	$(PYTHON) -m twine check dist/*
	$(PYTHON) -m pip check
	docker build --check .
	docker build --tag hivebox:release-check .

docs-diagrams:
	$(PYTHON) docs/diagrams/src/render_all.py --output docs/diagrams/generated

docs-diagrams-check:
	@temporary_directory="$$(mktemp -d)"; \
	trap 'rm -rf "$$temporary_directory"' EXIT; \
	$(PYTHON) docs/diagrams/src/render_all.py --output "$$temporary_directory"; \
	cmp --silent docs/diagrams/generated/.source-sha256 \
		"$$temporary_directory/.source-sha256"; \
	for name in application cd ci gitflow kubernetes observability; do \
		test -s "docs/diagrams/generated/$$name.png"; \
		test -s "docs/diagrams/generated/$$name.svg"; \
	done
