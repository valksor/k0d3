# Watermarks Remover Upstream Integration Implementation Plan

> **Execution skill:** Use `Skill(subagent-driven-development)` (recommended) or inline execution. Steps use `- [ ]` checkbox syntax.

**Goal:** Install the upstream Watermarks Remover Claude Code plugin automatically with k0d3 without vendoring it.
**Architecture:** Add a GitHub-backed entry to k0d3's Claude marketplace and declare it as k0d3's sole plugin dependency. Protect the upstream-only boundary with a repository-local regression test and document automatic installation and Claude-only scope.
**Tech Stack:** Claude Code marketplace JSON, Bash, jq, Markdown, GitHub Actions

---

### Task 1: Lock the upstream dependency contract

**Files:**

- Create: `scripts/test-third-party-marketplace.sh`
- Modify: `.github/workflows/skills-guard.yml`

**Done when:** `bash scripts/test-third-party-marketplace.sh` passes and proves the dependency is upstream-backed, automatic, and not vendored.

**Out of scope:** Installing the upstream plugin into a real user profile or running its watermark-removal service.

- [x] **Step 1: Write the regression test**
- [x] **Step 2: Run it against the current marketplace and confirm it fails because the entry is absent**
- [x] **Step 3: Add the test to the existing skills guard workflow**

### Task 2: Publish the upstream dependency

**Files:**

- Modify: `.claude-plugin/marketplace.json`
- Modify: `.claude-plugin/plugin.json`
- Modify: `README.md`

**Done when:** `bash scripts/test-third-party-marketplace.sh` and `claude plugin validate . --strict` pass.

**Out of scope:** Copying upstream skills or advertising Codex support upstream does not provide.

- [x] **Step 1: Add the GitHub source entry with upstream ownership and license metadata**
- [x] **Step 2: Declare Watermarks Remover as k0d3's sole plugin dependency**
- [x] **Step 3: Document automatic installation, the service boundary, and Claude-only scope**
- [x] **Step 4: Run the targeted regression test and strict Claude validator**
- [x] **Step 5: Run repository quality and test gates**

## Self-review

- Spec coverage: Task 1 enforces every boundary; Task 2 publishes, installs, and documents the integration.
- Placeholder scan: no deferred or ambiguous implementation placeholders.
- DRY/YAGNI: one marketplace entry and one focused test; no wrapper or copied upstream content.
- Decision provenance: upstream-only behavior and automatic installation come from the user decisions recorded in `docs/specs/2026-09-08-watermarks-remover-upstream-integration-design.md`.
