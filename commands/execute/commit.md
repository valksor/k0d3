---
name: commit
description: Create git commits for all uncommitted changes and land them on the project's mainline, matching the repo's existing commit style
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
- **Land on the project's mainline, never push**: commit locally on the current branch, then land the work where the project keeps it (see _Step 4_). **Never create a branch on your own initiative** — a branch you're only on because of the harness "branch first" default is _not_ the project's workflow; its commits get landed on the mainline and the branch deleted. **Never push** — the user pushes.
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

5. Note the planned **landing** (Step 4). Checkout/merge/branch-delete are write ops, blocked in plan mode — describe, don't run (the Step 4 heuristic reads — `@{upstream}`, file-existence checks — are read-only and permitted; only the checkout/merge/branch -d writes are blocked):
   - On the default branch → commits stay on it; nothing to land.
   - On a side branch with a feature/PR workflow → `leave on <cur>` for you to push/PR.
   - On any other side branch → `will merge <cur> into <default> and delete <cur>` (no push).
6. Inform the user:
   - Commits planned: N
   - Files staged: M
   - Where the work will land (per the line above)
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

## Step 4: Land the work on the project's mainline

Once Step 3 leaves a clean tree, get the commits where the project keeps them — don't strand
them on a side branch. **Never push** at any point; the user pushes. To choose the integration
strategy interactively (merge / PR / keep / discard) instead, use `/ship`; Step 4 is the
fire-and-forget path.

```bash
# Resolve the project's mainline — don't hardcode "master"; strip any remote prefix
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^[^/]*/##')
[ -z "$default" ] && { git show-ref -q --verify refs/heads/main && default=main || default=master; }
cur=$(git branch --show-current)
```

- **Detached HEAD** (`cur` is empty) → **STOP.** The commits are on a detached HEAD, not a branch;
  landing would orphan them. Tell the user: `HEAD is detached — commits are on the detached HEAD. Reattach ('git switch -c <name>' or 'git switch <branch>') before /commit again.`
- **Already on `$default`** (`cur` = `default`) → the commits are already on the mainline. Done.
- **On a side branch** (`cur` ≠ `default`) → decide: the project's workflow, or a fake branch?
  - **Feature / PR project → leave it.** Keep the commits on `cur`; do **not** merge or delete.
    Report: `Committed on '<cur>'. Project uses a feature/PR workflow — left for you to push/PR.`
    Treat the project as feature/PR if **any** of these hold (all cheap, no network):
    - the branch name looks like a feature branch — matches
      `^(feat|feature|fix|bugfix|hotfix|chore|release)/`;
    - the branch tracks a remote upstream — `git rev-parse --abbrev-ref @{upstream}` succeeds
      (a real, shared branch, not a throwaway);
    - PR infrastructure exists — `.github/PULL_REQUEST_TEMPLATE*`, a PR-gating
      `merge.sh` / `.githooks/pre-push`, or a `pr-validate*` workflow;
    - the project's `CLAUDE.md` documents a branch/PR workflow.
  - **Otherwise → land it on the mainline** (master-workflow project, or a fake harness
    branch — both want the commits on `$default`):
    ```bash
    # the mainline must exist locally before we can land on it
    git show-ref -q --verify "refs/heads/$default" && git checkout "$default"
    git merge "$cur"        # PLAIN merge — never --ff-only, never --squash, never rebase
    git branch -d "$cur"    # delete the merged side branch — don't leave it dangling
    ```
    Report: `Landed '<cur>' on '<default>' and deleted the branch. Not pushed.`
    - **If `$default` doesn't exist locally or `git checkout "$default"` fails** (real mainline
      is `trunk`/`develop`, or `origin/HEAD` is unset) → **STOP, do not merge.**
      Report: `Couldn't check out the mainline '<default>' — landing skipped; commits are safe on '<cur>'. Set origin/HEAD or land manually.`
    - **If `git branch -d "$cur"` refuses** (`not fully merged`) → **don't force.** The merge
      already succeeded, so the commits are safe on `$default`; report the error verbatim and
      tell the user to inspect, then `git branch -D "$cur"` manually if that's what they want.

**Conflict safety:** if `git merge` reports conflicts, **STOP** — leave the merge in progress,
tell the user exactly which files conflict, and add: `You are now on '<default>' with a merge in progress — resolve and 'git commit', or 'git merge --abort' to cancel.` Never auto-resolve, never
silently `git merge --abort`, never force.

## Restrictions

- In plan mode: only read-only git commands; write the plan to the plan file. The Step 4 landing (checkout / merge / branch -d) is a write op — describe it, never run it.
- NEVER `git -C` (operate from the repo's working directory)
- NEVER `git add -A` or `git add .` — always specify files
- NEVER `git push` — landing the work is a **local** merge; the user pushes
- NEVER create a branch on your own initiative — commit on the current branch and land per Step 4
- When landing on the mainline, use a PLAIN `git merge` — NEVER `--ff-only`, `--squash`, or rebase
- NEVER merge a feature/PR-workflow branch into the mainline or delete it — leave it for the user to push/PR (see Step 4)
- NEVER `git commit --amend` unless explicitly requested
- NEVER skip hooks (`--no-verify`) unless explicitly requested
- NEVER invent a commit style — match the repo's existing one
- NEVER leave a changed file uncommitted because you deemed it "unintended" or "unrelated" — commit it (its own commit if needed). Only genuine secrets/credentials or user-named files may be skipped, and you must say so.
- NEVER pause to ask the user whether to commit a file, and NEVER treat committing something as an "editorial call." The permitted stops are exactly two: (1) a clean working tree, (2) a detected secret/credential. **Every other reason to stop or ask is invalid** — "I didn't write it," "it's a separate feature," "it looks unrelated" all mean _commit it in its own commit_, not _ask first_.
