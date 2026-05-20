---
name: test
description: Run the project's tests with sensible defaults for the detected stack.
argument-hint: "[filter]"
allowed-tools: [Bash, Read]
---

# /test

Auto-detects the project's test runner and executes it. Optional filter passed through:

| Detected                         | Command                                                   |
| -------------------------------- | --------------------------------------------------------- |
| `package.json` + `"test"` script | `pnpm test` (if pnpm), else `bun test`, else `npm test`   |
| `Cargo.toml`                     | `cargo test [filter]`                                     |
| `pytest` / `pyproject.toml`      | `pytest [filter] -v`                                      |
| `go.mod`                         | `go test ./... [filter]`                                  |
| Multi-language                   | reads `.k0d3.toml` (if present) for the canonical command |

Argument `[filter]`: passed through to the test runner.
