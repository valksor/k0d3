---
name: commit
description: Create git commits for all uncommitted changes, matching the repo's existing commit style
argument-hint: "[optional message hint]"
allowed-tools:
  - Bash
  - Read
  - Skill
---

# /commit

Create well-structured git commits for all uncommitted changes in the current repository. **Match the repo's existing commit style exactly** — never introduce a new convention.

## Requirements

- **Commit everything**: "all uncommitted changes" means ALL — every modified, staged, and untracked path in `git status`. Never leave a file out, **and never pause to ask whether to commit one**, because you judge it incidental, tooling-generated, "not part of my change," **a separate feature, or code you didn't write** — none of those is a reason to skip _or to ask_. If it doesn't belong with the main commit, give it its own commit. Invoking `/commit` IS the authorization to commit everything; there is no further confirmation step. The only files you may skip are (a) genuine secrets/credentials or (b) files the user explicitly named — and you must say which you skipped and why. Done = a clean working tree.
- **File-based commits**: commit whole files only, never partial files or line hunks
- **Gradual commits**: limit each commit to **20–25 files maximum**. Split larger changesets into multiple focused commits. Improves reviewability, makes `git bisect` effective, keeps history readable.
- **No push**: only commit locally, never push to remote
- **No `git -C`**: operate from the repo's working directory
- **Enumerate paths, don't bulk-add**: stage with explicit `git add <path> …`, never `git add -A` / `git add .`. This is a safety mechanism so a stray credential file can't be swept in silently — **not** license to leave files out. Every uncommitted change still gets committed (see _Commit everything_ above).
- **No amend**: create new commits; only amend if the user explicitly asks
- **Co-author**: match existing style. Include a `Co-Authored-By` line only if recent commits include one. Do not introduce it on a solo project that has never used it.

## Mode detection (do this first)

Before any other action, check for plan mode:

- System instructions include "Plan mode is active"
- An active plan file path exists (e.g., `~/.claude/plans/<name>.md`)

### If plan mode IS active → plan the commits

> Read-only git commands (`git status`, `git diff`, `git log`) are permitted in plan mode. Write operations (`add`, `commit`, `push`) are blocked.

1. Gather:
   - `git status` — see uncommitted changes
   - `git diff` — understand what changed
   - `git log -5 | cat` — match existing commit style
2. Extract style dimensions from `git log` (see Step 1 below).
3. Group related files logically — every uncommitted file lands in some commit; grouping distributes them across commits, it never drops any.
4. Append a Commit Plan to the active plan file:

```
## Commit Plan

### Commit 1: <short summary>
**Files:**
- path/to/file1
- path/to/file2

**Message:**
~~~
<draft message using extracted style — do NOT use placeholder text>
~~~

### Commit 2: <short summary>
...
```

5. Inform the user:
   - Commits planned: N
   - Files staged: M
   - Review the plan; after exiting plan mode, run `/commit` again to execute.

### If plan mode is NOT active → execute commits

Proceed to Step 1.

## Step 1: Extract commit style (REQUIRED)

```bash
git log -5 | cat
```

Extract from the output:

- **Verb form**: imperative ("Add"), imperative-with-s ("Adds"), past tense ("Added"), or prefix ("feat:")
- **Subject length**: typical chars; some repos run shorter
- **Subject capitalization**: sentence case, all-lowercase, or mixed
- **Body format**: prose paragraphs, bullet points, or no body at all
- **Body width**: ~72 or ~80 chars
- **Co-author line**: exact format used, or absent
- **Footers**: `Refs:`, `Closes:`, `BREAKING CHANGE:` — only if the repo uses them

You MUST use the extracted style. Do not invent. Do not copy an example from this command or from `Skill(commit-writer)` — those are illustrative, not prescriptive.

For deeper guidance on writing the message body itself, invoke `Skill(commit-writer)`.

## Step 2: Fallback — only if the repo has zero commits

If `git log -5 | cat` returns nothing (truly empty repo), default to: imperative-with-s subject ("Adds X"), prose body explaining what + why. Do **not** introduce conventional commits (`feat:`, `fix:`) as a default — that is a project-wide editorial decision, not a sensible default.

## Step 3: Execute

1. `git status` — see all uncommitted changes. **If the working tree is clean** (no untracked, no modified, no staged), STOP and tell the user "Nothing to commit, working tree clean." Do NOT proceed; do NOT invent files to stage; do NOT create an empty commit.
2. `git diff` — understand what changed
3. Group related files logically per commit (20–25 file cap) — this distributes ALL uncommitted files across commits; it never excludes any.
4. `git add <specific-files>` (never `-A` or `.`)
5. Create the commit using HEREDOC format for proper message formatting:

```bash
git commit -m "$(cat <<'EOF'
<subject>

<body>
EOF
)"
```

6. Repeat for remaining changes
7. Final `git status` — the tree MUST be clean. Anything still uncommitted is a bug unless it is an allowed exclusion (secret/credential or user-named); name any skipped file and the reason. "Done" means a clean tree, not "the files I judged relevant are committed."

## Restrictions

- In plan mode: only read-only git commands; write the plan to the plan file
- NEVER `git -C` (operate from the repo's working directory)
- NEVER `git add -A` or `git add .` — always specify files
- NEVER `git push`
- NEVER `git commit --amend` unless explicitly requested
- NEVER skip hooks (`--no-verify`) unless explicitly requested
- NEVER invent a commit style — match the repo's existing one
- NEVER leave a changed file uncommitted because you deemed it "unintended" or "unrelated" — commit it (its own commit if needed). Only genuine secrets/credentials or user-named files may be skipped, and you must say so.
- NEVER pause to ask the user whether to commit a file, and NEVER treat committing something as an "editorial call." The permitted stops are exactly two: (1) a clean working tree, (2) a detected secret/credential. **Every other reason to stop or ask is invalid** — "I didn't write it," "it's a separate feature," "it looks unrelated" all mean _commit it in its own commit_, not _ask first_.
