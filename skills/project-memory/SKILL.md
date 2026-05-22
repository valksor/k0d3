---
name: project-memory
description: Use when you need persistent, cross-session memory of project FACTS — decisions, conventions, named entities and their relationships — to query later. Backed by k0d3's bundled local knowledge-graph MCP server (mcp__memory__*); stored project-local in .claude/memory.jsonl, no external service. NOT for within-session scratch or human-readable narrative (those go to .claude/memory.md via /start, /sync, /wrap-up).
metadata:
  added: 2026-05-22
  last_reviewed: 2026-05-22
  type: core
  status: active
  invokes_shell: false
  shell_reviewed: "valksor 2026-05-22"
  related: [agent-design, using-k0d3]
  keywords: [memory, remember, recall, persist, knowledge graph, cross-session, mcp memory, entities, observations]
---

# Project memory

NEVER write secrets, tokens, credentials, or personal data into the store — it is a **plaintext
knowledge graph (JSONL)** on disk. Persist a durable fact the moment it is final; **recall (search the
graph) before you assume.** It is not a scratchpad for transient chatter.

This is k0d3's bundled local memory server: the official, Anthropic-maintained
`@modelcontextprotocol/server-memory` (stdio, zero network at runtime, zero embeddings). Tools surface
as `mcp__memory__*`. One store per project at `${CLAUDE_PROJECT_DIR}/.claude/memory.jsonl`.

## Storage, safety & setup — read before first use

- **It's plaintext on disk.** See the iron rule. Record _that_ a secret exists and where it is
  configured — never its value.
- **Gitignored automatically.** k0d3's `ensure-memory-gitignore` SessionStart hook adds `memory.jsonl`
  to `.claude/.gitignore` in any git project, so the store can't be committed by accident. Running the
  server without k0d3's hooks? Gitignore `.claude/memory.jsonl` yourself.
- **The server does not create its parent dir.** A write to a missing `.claude/` returns `ENOENT`;
  k0d3's SessionStart hook guarantees `.claude/` exists first.
- **First use needs Node + network.** `npx` fetches the package once (cached after). If Node is absent
  or the first run is offline, the server simply does not start — **memory features are disabled** and
  the rest of k0d3 keeps working. There are no network calls once cached.
- **Where is my store?** Run `/mcp` (a Claude Code session command) to confirm the `memory` server is
  connected, then look for `.claude/memory.jsonl` in the project root.

## Two memory systems — know which one

Putting a fact in the wrong store is the most common mistake.

| Store                                                                   | Holds                                                         | Read/written by               | Shape            |
| ----------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------- | ---------------- |
| **Knowledge graph (JSONL)** — `.claude/memory.jsonl` (`mcp__memory__*`) | Durable, queryable facts: entities + observations + relations | **You**, via MCP tools        | Structured graph |
| **Markdown memory** — `.claude/memory.md`, `knowledge-base.md`          | Human-readable session narrative, confirmed rules             | `/start`, `/sync`, `/wrap-up` | Prose            |

Rule of thumb: if a human reads it as a story, it's markdown. If _you_ will query it later by name or
keyword, it's the graph. Don't write the same fact into both — they drift.

## Data model

- **Entity** — a named thing with an `entityType` and a list of `observations`. The name is a unique
  key. Example: `{ name: "auth-service", entityType: "service", observations: ["Go + chi", "owns /login"] }`.
- **Observation** — one discrete fact on one entity. Append with `add_observations`; do not spawn a
  second entity for the same thing.
- **Relation** — a directed, active-voice edge: `auth-service` —`depends_on`→ `postgres`.

## When to store

The moment a fact becomes durable — don't wait for end of session:

- A **decision** ("chose X over Y because Z") → an entity (`entityType: decision`) + observations.
- A **convention or constraint** ("migrations run before deploy", "no personal data in logs").
- A **key entity** named (service, module, person, external system) and how it relates to others.

## When to recall

- **Starting work on a project** — `search_nodes "<topic>"` (or `read_graph` if small) before you
  assume anything about architecture, ownership, or past decisions.
- **Before re-deciding** something — search first; the answer may already be stored.
- After recall, act on what you find. If a stored fact is now wrong, correct it (below).

## Tool reference

| Tool                  | Use                                                                            |
| --------------------- | ------------------------------------------------------------------------------ |
| `create_entities`     | Add new named things (keyed by name)                                           |
| `add_observations`    | Append facts to an existing entity — the workhorse                             |
| `create_relations`    | Link two entities with a directed verb                                         |
| `search_nodes`        | Keyword/substring lookup across names, types, observations                     |
| `open_nodes`          | Fetch specific entities by name                                                |
| `read_graph`          | Dump the whole graph — only when small (≲50 entities); else use `search_nodes` |
| `delete_observations` | Remove a fact that is no longer true                                           |
| `delete_relations`    | Remove a stale edge                                                            |
| `delete_entities`     | Remove a thing entirely (cascades its relations)                               |

Correcting a fact = `delete_observations` the wrong one, then `add_observations` the right one. Keep
the entity; replace the observation.

## Anti-patterns

- **Secrets or personal data in the graph.** Plaintext JSONL on disk. Never key material, tokens,
  passwords, or real user data. Record that a secret exists and where, not its value.
- **Transient chatter as observations.** "User asked me to run the tests" is not durable. Store
  conclusions and decisions, not the play-by-play.
- **Duplicate entities.** Two `auth-service` entities fragment recall. Search first; `add_observations`
  to the existing one.
- **Treating it as semantic search.** Matching is keyword/substring only — no embeddings, no fuzzy
  recall. Phrase entities so the words you will search for are present.
- **Letting it rot.** A graph of stale "facts" is worse than none. Delete what is no longer true.
