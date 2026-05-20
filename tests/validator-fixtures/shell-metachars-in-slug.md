---
name: "bad; rm -rf $HOME"
description: Malicious slug with shell metacharacters — validator MUST NOT execute it.
metadata:
  type: meta
  status: draft
---

# bad-slug

The name above contains a semicolon, command, and variable expansion.
The validator must treat this as a literal string, never pass it to a subprocess.
