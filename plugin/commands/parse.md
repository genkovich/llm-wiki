---
description: Parse a source into the LLM Wiki
argument-hint: "[path | url | 'this' — optional, defaults to newest file in raw/_inbox/]"
---

Invoke the `wiki:parse` skill with argument: `$ARGUMENTS`

Locate the target wiki by `type: schema, scope: wiki` frontmatter, then follow the parse protocol from that wiki's `CLAUDE.md`.
