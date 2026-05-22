# Review finding disposition

Shared protocol for `/k0d3:review-code`, `/k0d3:review-impl`, `/k0d3:review-plan`,
`/k0d3:review`, and `/k0d3:security-audit`. It defines what the orchestrator does **after**
a review has printed its categorized findings — regardless of which severity scheme the
calling command uses (Blockers / Concerns / Advisories, or Critical / High / Medium / Low /
Info).

This is the orchestrator's half of a contract the reviewer agents already state: _"the
orchestrator validates and dispositions every finding."_ Reviewers find and classify at true
severity; **dispositioning is your job, and it is not optional.**

## The protocol

Once the findings are printed, **do not stop and do not ask permission.** Disposition every
finding:

1. **Validate.** For each finding, open the cited `file:line` and read the **whole enclosing
   function or block** — not just the one line. Confirm the described problem is actually
   present in that context. Reviewers run without full repo context and produce false
   positives; **if you cannot reproduce the described problem from the code (or plan) itself,
   treat it as a false positive** and skip it (step 3). A finding is _valid_ only when you can
   see the problem in the real code.

2. **Fix every valid finding — all tiers.** Apply the remediation directly: edit the source
   (for `/review-plan`, revise the plan document). Fix Blockers, Concerns, and Advisories
   alike — and the equivalent Critical/High/Medium/Low/Info tiers. **Severity sets order, not
   whether to fix:** do blockers first, advisories last; never skip a tier just because it is
   low.

3. **Skip false positives.** If validation shows a finding is wrong, out of scope, or already
   handled, drop it — but say so in one line. Never silently discard a finding.

4. **Never ask for permission.** Do not write _"Want me to fix…?"_, _"Want me to add…?"_, or
   wait for approval. The user ran a review command to get the code fixed, not to receive a
   to-do list. Asking is the failure mode this protocol exists to prevent.

5. **Report the disposition.** After fixing, print a report: for each **fixed** finding, its
   tier, `file:line`, and a one-line description of the change you made; for each **skipped**
   finding, the one-line reason. These commands do **not** run the test suite or build — close
   the report by reminding the user to inspect the changes (`git diff`) and run their tests to
   confirm nothing regressed, and that they can re-run the command for a fresh pass.

**Never stage, commit, or push the fixes.** They land in the working tree only — leave them
there for the user to review.

## Guard clauses

**Local working tree only.** You can only fix what is in the local working tree. If the review
target is a remote PR or a ref that is not checked out locally, you cannot edit it — present
the validated findings with concrete, copy-pasteable remediations instead, and say why. (If
the user has checked the PR out locally, the fixes apply to that working tree like any other —
and, per above, you never push them.)

**Plan mode.** If Claude Code plan mode is active, _source_ edits are disallowed. Instead of
editing source, append the validated findings and their intended fixes to the active plan file
(path from system context) under a "Review findings" section, and say so. (`/review-plan` is
the exception: revising a plan document is prose editing, not a source edit, so `/review-plan`
always edits the reviewed plan document directly — even in plan mode.)

## What this is NOT

- **Not a re-classification pass.** The consolidated severities stand — you validate whether a
  finding is _true_, not whether its tier is _right_.
- **Not an automatic review loop.** Fix once and report. The user re-runs the command if they
  want another pass; you do not re-dispatch reviewers on your own.
