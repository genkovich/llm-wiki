---
type: entity
tags: [claude-code, skills]
sources: []
last_updated: 2026-05-11
confidence: low
---

# Skills

Behavior modules for Claude Code: markdown files with YAML frontmatter (`name`, `description`) that trigger semantically through their description. A skill loads only when relevant — keeping context budget tight.

## Location

- User-level: `~/.claude/skills/<name>/SKILL.md`
- Plugin-level: `<plugin>/skills/<name>/SKILL.md`

## Relationship with other entities

- vs [[entities/subagents]] — a skill lives in the main context, a subagent gets its own. See [[comparisons/skills-vs-subagents]] (TBD).
- Triggered by description, not by explicit call

## Open questions

- Best practices for writing descriptions that trigger accurately
- Progressive disclosure: when should a skill link to references vs. include content inline

## Sources

_Stub. Canonical source: docs.claude.com/en/docs/claude-code/skills (ingest pending)._
