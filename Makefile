SHELL := /usr/bin/env bash

SH_FILES := $(shell git ls-files --cached --others --exclude-standard '*.sh')
PY_FILES := scripts

.PHONY: format format-check format-md format-sh format-py lint lint-sh help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

lint: lint-sh ## Run all linters

lint-sh: ## Lint shell scripts via shellcheck
	shellcheck $(SH_FILES)

format: format-md format-sh format-py ## Format everything in place

format-check: ## Verify formatting; exits non-zero if anything is unformatted
	bunx prettier --check .
	shfmt -d -i 2 -ci -sr $(SH_FILES)
	uvx ruff format --check $(PY_FILES)

format-md: ## Format Markdown + JSON via Prettier
	bunx prettier --write .

format-sh: ## Format shell scripts via shfmt
	shfmt -w -i 2 -ci -sr $(SH_FILES)

format-py: ## Format Python via ruff
	uvx ruff format $(PY_FILES)
