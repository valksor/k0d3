# Watermarks Remover Upstream Integration Implementation Plan

> **Execution skill:** Use `Skill(subagent-driven-development)` (recommended) or inline execution. Steps use `- [ ]` checkbox syntax.

**Goal:** Make the upstream Watermarks Remover Claude Code plugin discoverable through k0d3 while requiring a separate explicit installation.
**Architecture:** Add a GitHub-backed entry to k0d3's Claude marketplace without declaring it as a k0d3 dependency. Protect that boundary with a repository-local regression test and document the opt-in command and Claude-only scope.
**Tech Stack:** Claude Code marketplace JSON, Bash, jq, Markdown, GitHub Actions

---

### Task 1: Lock the upstream-only marketplace contract

**Files:**

- Create: `scripts/test-third-party-marketplace.sh`
- Modify: `.github/workflows/skills-guard.yml`

**Done when:** `bash scripts/test-third-party-marketplace.sh` passes and proves the entry is upstream-backed, optional, and not vendored.

**Out of scope:** Installing the upstream plugin into a real user profile or running its watermark-removal service.

- [x] **Step 1: Write the regression test**
- [x] **Step 2: Run it against the current marketplace and confirm it fails because the entry is absent**
- [x] **Step 3: Add the test to the existing skills guard workflow**

### Task 2: Publish the optional upstream entry

**Files:**

- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Done when:** `bash scripts/test-third-party-marketplace.sh` and `claude plugin validate . --strict` pass.

**Out of scope:** Adding a `dependencies` field, copying upstream skills, or advertising Codex support upstream does not provide.

- [x] **Step 1: Add the GitHub source entry with upstream ownership and license metadata**
- [x] **Step 2: Document the separate install command, service boundary, and Claude-only scope**
- [x] **Step 3: Run the targeted regression test and strict Claude validator**
- [x] **Step 4: Run repository quality and test gates**

## Self-review

- Spec coverage: Task 1 enforces every boundary; Task 2 publishes and documents the integration.
- Placeholder scan: no deferred or ambiguous implementation placeholders.
- DRY/YAGNI: one marketplace entry and one focused test; no wrapper or copied upstream content.
- Decision provenance: upstream-only behavior and explicit installation come from the approved correction in `docs/specs/2026-09-08-watermarks-remover-upstream-integration-design.md`.
