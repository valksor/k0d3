#!/usr/bin/env python3
"""trigger-test.sh helper. Measures skill trigger rates by firing corpus prompts at a
headless `claude -p` session and watching stream-json for Skill() tool calls.

Corpus: skills/<slug>/trigger-prompts.txt — one prompt per line.
  - plain line      = should trigger Skill(<slug>)
  - leading "!"     = should NOT trigger Skill(<slug>) (other skills are fine)
  - leading "#" / blank = ignored

Each prompt is a real (billed) headless Claude session, so this is an opt-in tool,
not part of validate/smoke. The run is capped per prompt by --budget-usd and killed
early as soon as the target skill fires. Measures against the installed k0d3 plugin —
run /update-k0d3 (or a local install) first so the working tree is what's measured.

Probes run from a throwaway minimal git repo with one staged file, NOT an empty dir:
the model checks project state before reaching for workflow skills, and a barren cwd
derails the probe ("you have no staged changes") without the skill ever loading.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO / "skills"
CORPUS_NAME = "trigger-prompts.txt"


def parse_corpus(path: pathlib.Path) -> tuple[list[str], list[str]]:
    """Return (should_trigger, should_not_trigger) prompt lists."""
    should, should_not = [], []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("!"):
            should_not.append(line[1:].strip())
        else:
            should.append(line)
    return should, should_not


def skill_calls(line: str) -> list[str]:
    """Extract Skill() arguments from one stream-json event line."""
    if '"name":"Skill"' not in line:
        return []
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        return []
    out: list[str] = []
    content = (event.get("message") or {}).get("content") or []
    if isinstance(content, list):
        for block in content:
            if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") == "Skill":
                arg = (block.get("input") or {}).get("skill")
                if arg:
                    out.append(str(arg))
    return out


def matches(arg: str, slug: str) -> bool:
    return arg == slug or arg.endswith(f":{slug}")


def run_prompt(prompt: str, slug: str, model: str, budget: float, timeout: int, cwd: pathlib.Path) -> tuple[bool, bool]:
    """Fire one headless session; returns (triggered, budget_hit). Kills the session
    as soon as the target skill fires so unrelated work doesn't burn budget.

    cwd must be a NEUTRAL empty directory: probing from inside a real project loads
    its CLAUDE.md and tool surface, and the session burns the budget cap on project
    context before skill selection happens — every probe then misreports as a miss.
    """
    cmd = [
        "claude",
        "-p",
        prompt,
        "--output-format",
        "stream-json",
        "--verbose",
        "--allowedTools",
        "Skill",
        "--max-budget-usd",
        str(budget),
    ]
    if model:
        cmd += ["--model", model]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL,
        text=True,
        cwd=cwd,
    )
    triggered = budget_hit = False
    try:
        assert proc.stdout is not None
        # iter(readline) over plain iteration: no read-ahead buffering, so the kill
        # fires on the exact line that triggered instead of a buffer boundary later.
        for line in iter(proc.stdout.readline, ""):
            if any(matches(arg, slug) for arg in skill_calls(line)):
                triggered = True
                proc.kill()
                break
            if '"subtype":"error_max_budget_usd"' in line:
                budget_hit = True
        proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
    finally:
        if proc.poll() is None:
            proc.kill()
    return triggered, budget_hit


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument(
        "--skill", action="append", default=[], help="slug to test (repeatable); default: every skill with a corpus"
    )
    ap.add_argument(
        "--model",
        default="",
        help="model for the probe sessions (default: your session default — what users actually "
        "trigger with; pass e.g. 'haiku' to cheapen probes, knowing smaller models under-trigger "
        "and will undercount)",
    )
    ap.add_argument(
        "--bar",
        type=float,
        default=0.9,
        help="minimum should-trigger activation rate (default: 0.9, per Anthropic's skill guide)",
    )
    ap.add_argument(
        "--budget-usd",
        type=float,
        default=0.50,
        help="per-prompt API spend cap (default: 0.50 — a capped probe reports as inconclusive, "
        "so too-low caps undercount activation)",
    )
    ap.add_argument("--timeout", type=int, default=180, help="per-prompt wall-clock cap in seconds (default: 180)")
    args = ap.parse_args()

    if shutil.which("claude") is None:
        print("FAIL: `claude` CLI not on PATH", file=sys.stderr)
        return 1

    if args.skill:
        corpora = [(s, SKILLS_DIR / s / CORPUS_NAME) for s in args.skill]
        missing = [s for s, p in corpora if not p.exists()]
        if missing:
            print(f"FAIL: no {CORPUS_NAME} for: {', '.join(missing)}", file=sys.stderr)
            return 1
    else:
        corpora = sorted((p.parent.name, p) for p in SKILLS_DIR.glob(f"*/{CORPUS_NAME}"))
        if not corpora:
            print(f"FAIL: no skills/*/{CORPUS_NAME} corpora found", file=sys.stderr)
            return 1

    failed = False
    probe_dir = pathlib.Path(tempfile.mkdtemp(prefix="k0d3-trigger-probe-"))
    (probe_dir / "calc.py").write_text("def add(a, b):\n    return a + b\n", encoding="utf-8")
    if shutil.which("git"):  # best-effort plausibility; probes still run without git
        subprocess.run(["git", "init", "-q"], cwd=probe_dir, check=False)
        subprocess.run(["git", "add", "calc.py"], cwd=probe_dir, check=False)
    for slug, path in corpora:
        should, should_not = parse_corpus(path)
        hits, false_pos = 0, 0
        for prompt in should:
            ok, capped = run_prompt(prompt, slug, args.model, args.budget_usd, args.timeout, probe_dir)
            hits += ok
            mark = "✓" if ok else ("✗ MISS (budget cap hit — inconclusive)" if capped else "✗ MISS")
            print(f"  {mark}  {prompt[:90]}", file=sys.stderr)
        for prompt in should_not:
            fp, _ = run_prompt(prompt, slug, args.model, args.budget_usd, args.timeout, probe_dir)
            false_pos += fp
            print(f"  {'✗ FALSE-TRIGGER' if fp else '✓'}  !{prompt[:88]}", file=sys.stderr)
        rate = hits / len(should) if should else 1.0
        verdict = "PASS" if rate >= args.bar and false_pos == 0 else "FAIL"
        if verdict == "FAIL":
            failed = True
        print(
            f"{verdict}: {slug} — {hits}/{len(should)} should-trigger ({rate:.0%}, bar {args.bar:.0%}), "
            f"{false_pos}/{len(should_not)} false-triggers",
            file=sys.stderr,
        )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
