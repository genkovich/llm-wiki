---
type: entity
tags: [claude-code, subagents]
sources: []
last_updated: 2026-05-11
confidence: low
---

# Subagents

Specialized Claude agents that receive an isolated context, execute a delegated task, and return a single result message back to the main context.

## Key characteristics

- Separate context — does not see the main conversation history
- The subagent prompt must be self-contained (briefed like a new colleague)
- Useful for: parallelization, protecting the main context, specialized tasks (review, search, planning)

## Relationships

- vs [[entities/skills]] — a skill is a behavior module, a subagent is a separate runtime with its own context
- Diff: [[comparisons/skills-vs-subagents]] (TBD)

## Open questions

- When is a subagent better than inline tool use
- How to write prompts so the subagent doesn't duplicate work

## Sources

_Stub._
