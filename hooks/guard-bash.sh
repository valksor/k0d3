#!/usr/bin/env bash
# PreToolUse hook for Bash commands.
# Uses structured JSON output for blocks (exit 0 + JSON stdout).
# Falls through with plain exit 0 for allowed commands.
#
# Three tiers:
#   HARD BLOCK  — always blocked, no override (permissionDecision: deny)
#   SOFT BLOCK  — blocked with explanation, user can re-request (permissionDecision: deny)
#   LOG WARNING — allowed but logged to incident log (exit 0, no JSON)
#
# Note: regex-on-shell-text is fundamentally fragile. This hook is a best-effort
# tripwire, not a sandbox. Catastrophic-rm and secret-exfil checks use token-scan
# (whitespace split) for better coverage than position-anchored regex.

# Guard against unset project dir (silently no-op rather than write to /)
[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
INCIDENT_LOG="$LOG_DIR/incident-log.md"

mkdir -p "$LOG_DIR"

log_incident() {
  local SEVERITY="$1"
  local MSG="$2"
  # Fence user-controlled MSG to prevent markdown injection in the log file
  local SAFE_MSG
  SAFE_MSG="$(printf '%s' "$MSG" | tr '\n' ' ' | sed 's/`/'"'"'/g')"
  echo "- \`$TIMESTAMP\` | GUARD | $SEVERITY | $SAFE_MSG" >> "$INCIDENT_LOG"
}

deny() {
  local REASON="$1"
  local CONTEXT="$2"
  jq -n \
    --arg reason "$REASON" \
    --arg context "$CONTEXT" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason,
        additionalContext: $context
      }
    }'
  exit 0
}

# ═══════════════════════════════════════════════════════
# HARD BLOCK — never allowed, no exceptions
# ═══════════════════════════════════════════════════════

# Catastrophic rm: clause-aware token-scan for system paths (Pass 1 B1, Pass 2
# Sr Dev B1 + Security B1). Split on &&/||/;/| and scan ONLY the tokens of
# clauses that actually invoke `rm`, so a system path in a SIBLING clause
# (`cd /Users/me/proj && rm localfile`) is never mistaken for an rm target.
# Within an rm clause this still catches: rm -r /, rm /etc, rm / -rf
# (flag-after-path), reorderings, and quoted paths like `rm -rf "/etc"`.
#
# Quote-stripping: word-splitting does NOT strip quotes from already-expanded
# scalars. We strip leading/trailing single + double quotes from each token
# before the case match so `"/etc"` matches the `/etc` pattern.
if echo "$COMMAND" | grep -qE '\brm\b'; then
  RM_CLAUSES="$(echo "$COMMAND" | tr ';|&' '\n' | tr -s '\n')"
  while IFS= read -r rm_clause; do
    [ -z "$rm_clause" ] && continue
    echo "$rm_clause" | grep -qE '\brm\b' || continue
    for raw_token in $rm_clause; do
      # Strip up to one layer of surrounding quotes (handles "x", 'x', `x`)
      token="${raw_token#[\"\'\`]}"
      token="${token%[\"\'\`]}"
      # shellcheck disable=SC2016  # '$HOME'/'${HOME}' are literal patterns — the scan matches the unexpanded text of a command like `rm -rf $HOME`
      case "$token" in
        / | ~ | '$HOME' | '${HOME}' | \
          /etc | /etc/* | /usr | /usr/* | /var | /var/* | /bin | /bin/* | /sbin | /sbin/* | \
          /lib | /lib/* | /lib64 | /lib64/* | /boot | /boot/* | /sys | /sys/* | /proc | /proc/* | \
          /dev | /dev/* | /opt | /opt/* | /root | /root/* | /home | /home/* | ~/ | ~/* | \
          /Users | /Users/* | /System | /System/* | /Library | /Library/* | \
          /Applications | /Applications/* | /Volumes | /Volumes/* | /private | /private/*)
          log_incident "CRITICAL" "BLOCKED: rm targeting system path '$token' in: $COMMAND"
          deny "HARD BLOCK: rm targets system or home path ($token). Catastrophic." "Use a project-relative path under \$CLAUDE_PROJECT_DIR. Never delete system or home directories."
          ;;
      esac
    done
  done <<< "$RM_CLAUSES"
fi

# Shell indirection bypass (B2): eval, sh -c, bash -c — these wrap commands in
# a way that defeats every other regex below. Soft-block so legitimate uses
# (build scripts, oneliners) can be re-requested.
if echo "$COMMAND" | grep -qE '\b(eval|bash[[:space:]]+-c|sh[[:space:]]+-c|zsh[[:space:]]+-c|ksh[[:space:]]+-c|dash[[:space:]]+-c)\b'; then
  log_incident "HIGH" "SOFT BLOCKED: shell indirection: $COMMAND"
  deny "SOFT BLOCK: shell indirection (eval, sh -c, bash -c, etc.) bypasses safety checks." "Run the underlying command directly so guard-bash.sh can inspect it. If indirection is genuinely required, ask the user to confirm."
fi

# git push --force / -f (also matches --force-with-lease via --force prefix)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+push[[:space:]]+.*--force|git[[:space:]]+push[[:space:]]+-f\b'; then
  log_incident "CRITICAL" "BLOCKED: force push: $COMMAND"
  deny "HARD BLOCK: Force push rewrites shared history." "Command blocked: force push detected. Ask the user to confirm the specific branch if intentional. Note: --force-with-lease is also blocked under this rule."
fi

# git reset --hard (destroys uncommitted work)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
  log_incident "HIGH" "BLOCKED: git reset --hard: $COMMAND"
  deny "HARD BLOCK: git reset --hard destroys uncommitted changes." "Command blocked: git reset --hard. Suggest using git stash or git commit first."
fi

# git clean -f (deletes untracked files permanently)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+clean[[:space:]]+(-[a-zA-Z]*f|-f)'; then
  log_incident "HIGH" "BLOCKED: git clean -f: $COMMAND"
  deny "HARD BLOCK: git clean -f permanently deletes untracked files." "Command blocked: git clean -f. Suggest using git stash instead."
fi

# chmod 777 (security risk)
if echo "$COMMAND" | grep -qE 'chmod[[:space:]]+777'; then
  log_incident "HIGH" "BLOCKED: chmod 777: $COMMAND"
  deny "HARD BLOCK: chmod 777 grants full access to all users." "Command blocked: chmod 777. Use more restrictive permissions like 755 or 644."
fi

# ═══════════════════════════════════════════════════════
# SECRET EXPOSURE — block commands that leak credentials
# ═══════════════════════════════════════════════════════

# Token-scan: any tool that prints/streams .env* file contents (Pass 1 B3,
# Pass 2 quote-bypass fix). Local file-movers (cp/mv/ln) are NOT in the list —
# they relocate bytes without exposing a value to stdout/log; rsync/scp stay
# because they move over the network. Secret-free templates (.env.example and
# friends) are exempt. Allow `grep -c KEY .env` / `grep --count` existence
# checks (no value leak). Same quote-stripping as the rm token-scan above.
if echo "$COMMAND" | grep -qE '\b(cat|head|tail|less|more|bat|grep|awk|sed|xxd|od|strings|sort|uniq|wc|tee|rsync|scp)\b'; then
  for raw_token in $COMMAND; do
    token="${raw_token#[\"\'\`]}"
    token="${token%[\"\'\`]}"
    case "$token" in
      *.env.example | *.env.sample | *.env.template | *.env.dist)
        continue ;; # secret-free templates — safe to read/inspect
      *.env | *.env.*)
        if echo "$COMMAND" | grep -qE '\bgrep[[:space:]]+(-[a-zA-Z]*c[a-zA-Z]*|--count)([[:space:]]|=)'; then
          continue
        fi
        log_incident "HIGH" "BLOCKED: .env read via shell: $COMMAND"
        deny "HARD BLOCK: Reading .env* files via shell exposes credentials." "Use the variable name in your code; never read the file via shell. Use 'grep -c KEY .env' or 'grep --count KEY .env' for existence checks."
        ;;
    esac
  done
fi

# printenv with an explicit variable name prints its value (A7). Allow a
# safelist of well-known non-secret vars (PATH, HOME, …); block the rest, since
# any other var could hold a credential. (sed uses no \b — BSD/macOS sed lacks it.)
if echo "$COMMAND" | grep -qE '\bprintenv[[:space:]]+[A-Za-z_]'; then
  PRINTENV_VAR="$(echo "$COMMAND" | sed -nE 's/.*printenv[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/p')"
  case "$PRINTENV_VAR" in
    PATH | HOME | USER | LOGNAME | PWD | OLDPWD | SHELL | SHLVL | LANG | LANGUAGE | \
      TERM | TERM_PROGRAM | COLORTERM | HOSTNAME | TMPDIR | TZ | EDITOR | VISUAL | \
      PAGER | DISPLAY | COLUMNS | LINES | GOPATH | GOROOT | GOBIN | VIRTUAL_ENV | \
      CONDA_DEFAULT_ENV | LC_*)
      : ;; # benign environment var — reading it exposes nothing sensitive
    *)
      log_incident "HIGH" "BLOCKED: printenv with arg: $COMMAND"
      deny "HARD BLOCK: printenv <var> prints the credential value to output." "Reference secrets by variable name only. Never print their values. Benign vars (PATH, HOME, …) are allowed."
      ;;
  esac
fi

# Block echo/printf of environment variables whose name marks them as a secret
# (covers ${VAR} brace form via [{]? optional brace, and $VAR bare form). The
# names are specific, not broad prefixes: a bare `AWS_`/`DATABASE_`/`TOKEN`
# prefix wrongly caught `$AWS_REGION`, `$DATABASE_NAME`, `$TOKEN_COUNT`, so the
# list now requires the actual secret-bearing var names.
if echo "$COMMAND" | grep -qE '(echo|printf)[[:space:]]+.*\$[{]?(STRIPE_|OPENAI_|ANTHROPIC_|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN|DATABASE_URL|DATABASE_PASSWORD|DB_PASSWORD|AUTH_SECRET|NEXTAUTH_SECRET|SESSION_SECRET|JWT_SECRET|CLIENT_SECRET|API_KEY|SECRET_KEY|SECRET_ACCESS_KEY|PRIVATE_KEY|ENCRYPTION_KEY|SIGNING_KEY|PASSWORD|PASSWD|GITHUB_TOKEN|GH_TOKEN|GITLAB_TOKEN|SLACK_TOKEN|NPM_TOKEN|AUTH_TOKEN|ACCESS_TOKEN|REFRESH_TOKEN|API_TOKEN)'; then
  log_incident "HIGH" "BLOCKED: secret echo: $COMMAND"
  deny "HARD BLOCK: Echoing secret environment variables exposes credentials." "Reference secrets by variable name only. Never echo their values."
fi

# Block piping credential files to network commands
if echo "$COMMAND" | grep -qE '\.env.*\|[[:space:]]*(curl|wget|nc|ncat|http|httpie)'; then
  log_incident "CRITICAL" "BLOCKED: credential file piped to network: $COMMAND"
  deny "HARD BLOCK: Piping credential files to network commands would exfiltrate secrets." "Never pipe .env files to network commands."
fi

# Block git add of credential files. Token-scan (not a single regex) so
# secret-free templates (.env.example and friends) can still be staged.
if echo "$COMMAND" | grep -qE '\bgit[[:space:]]+add\b'; then
  for raw_token in $COMMAND; do
    token="${raw_token#[\"\'\`]}"
    token="${token%[\"\'\`]}"
    case "$token" in
      *.env.example | *.env.sample | *.env.template | *.env.dist)
        continue ;; # templates carry no secrets — fine to commit
      *.env | *.env.*)
        log_incident "CRITICAL" "BLOCKED: git add of credential file: $COMMAND"
        deny "HARD BLOCK: Staging credential files (.env) for git commit would expose secrets publicly." "These files must stay in .gitignore. Never commit credentials to git. Templates like .env.example are allowed."
        ;;
    esac
  done
fi

# ═══════════════════════════════════════════════════════
# SOFT BLOCK — blocked, but user can re-request
# ═══════════════════════════════════════════════════════

# rm with a recursive flag (-r / -R / --recursive) deletes a whole tree.
# Force-only rm (`rm -f <named files>`, no -r) is NOT soft-blocked — it drops
# to the LOW warn tier below, since forcing named files is low-risk and the
# catastrophic-path scan above still hard-blocks system targets.
# Clause-aware: split on &&/||/;/| and require EVERY recursive-rm clause to be
# on the allowlist, so `rm -rf .claude/backups/x && rm -rf foo` can't slip
# through the allowlist check (C7).
RECURSIVE_RM='(^|[[:space:]])(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)([[:space:]]|$)'
if echo "$COMMAND" | grep -qE '\brm\b' && echo "$COMMAND" | grep -qE "$RECURSIVE_RM"; then
  CLAUSE_FAILED=false
  # tr replaces all clause separators with newline; tr -s collapses repeats
  CLAUSES="$(echo "$COMMAND" | tr ';|&' '\n' | tr -s '\n')"
  while IFS= read -r clause; do
    [ -z "$clause" ] && continue
    if echo "$clause" | grep -qE '\brm\b' && echo "$clause" | grep -qE "$RECURSIVE_RM"; then
      if ! echo "$clause" | grep -qE '\.claude/(backups|logs/\.(quality-gate-active|session-blocks|tool-call-count|compaction-occurred))'; then
        CLAUSE_FAILED=true
        break
      fi
    fi
  done <<< "$CLAUSES"

  if [ "$CLAUSE_FAILED" = "true" ]; then
    log_incident "MEDIUM" "SOFT BLOCKED: recursive rm (or in compound): $COMMAND"
    deny "SOFT BLOCK: rm -r/-R deletes a directory tree permanently." "Command blocked: recursive delete. If intentional, ask the user to confirm with the specific paths listed. Compound commands are checked clause-by-clause; an allowlisted clause does not exempt other clauses. (Force-only 'rm -f <file>' is allowed.)"
  fi
fi

# Overwriting system/config files
if echo "$COMMAND" | grep -qE '>[[:space:]]*(~\/\.|\/etc\/|\.env|\.ssh|\.claude\/settings)'; then
  log_incident "HIGH" "SOFT BLOCKED: config/system file overwrite: $COMMAND"
  deny "SOFT BLOCK: Writing to a sensitive config/system file." "Command blocked: system file overwrite detected. Verify this is intentional with the user."
fi

# curl/wget piped to shell (arbitrary code execution)
if echo "$COMMAND" | grep -qE '(curl|wget)[[:space:]].*\|[[:space:]]*(bash|sh|zsh|ksh|dash)'; then
  log_incident "HIGH" "SOFT BLOCKED: curl pipe to shell: $COMMAND"
  deny "SOFT BLOCK: Piping curl/wget to a shell executes arbitrary remote code." "Command blocked: pipe to shell. Download the file first, inspect it, then run it."
fi

# ═══════════════════════════════════════════════════════
# LOG WARNING — allowed but recorded
# ═══════════════════════════════════════════════════════

# Any rm command (non-recursive, non-force)
if echo "$COMMAND" | grep -qE '\brm\b'; then
  log_incident "LOW" "WARNING: rm command allowed: $COMMAND"
fi

# Any mv command (could lose data if target exists)
if echo "$COMMAND" | grep -qE '\bmv\b'; then
  log_incident "LOW" "WARNING: mv command allowed: $COMMAND"
fi

# Any git checkout that discards changes
if echo "$COMMAND" | grep -qE 'git[[:space:]]+checkout[[:space:]]+\.'; then
  log_incident "MEDIUM" "WARNING: git checkout . discards changes: $COMMAND"
fi

# Writing to files outside project directory (covers > and >>).
# Two-step check avoids the consumed-stdin bug from the previous pipe form.
if echo "$COMMAND" | grep -qE '>>?[[:space:]]*/'; then
  if ! echo "$COMMAND" | grep -qE ">>?[[:space:]]*${CLAUDE_PROJECT_DIR:-/dev/null/never-matches}"; then
    log_incident "MEDIUM" "WARNING: write outside project dir: $COMMAND"
  fi
fi

exit 0
