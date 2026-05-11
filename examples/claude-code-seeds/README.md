# Claude Code seed entities

4 stub entities from a real wiki instance for the domain "Claude Code course":

- `claude-code.md` — the Claude Code CLI
- `skills.md` — the Skills system
- `subagents.md` — Subagents
- `plan-mode.md` — Plan mode

## How to use

If your wiki is about Claude Code / agentic engineering — copy them into your `entities/`:

```bash
cp claude-code.md skills.md subagents.md plan-mode.md /path/to/wiki/entities/
```

These are stubs with `confidence: low` and empty `sources: []` — they fill in during the first ingests.

For other domains — ignore; this is only a format example.
