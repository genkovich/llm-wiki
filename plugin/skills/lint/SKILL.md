---
name: lint
description: >
  Use when the user invokes LLM Wiki lint workflow — explicitly via "wiki:lint",
  "wiki: lint", "перевір wiki", "audit the wiki", or similar consistency-check
  requests. Scans entities/, concepts/, and comparisons/ for contradictions, stale
  pages, orphans, missing cross-references, and data gaps. Writes findings into a
  fresh questions/lint-YYYY-MM-DD.md and appends a log entry. Recognizes the wiki
  by a CLAUDE.md with `type: schema, scope: wiki` and follows the lint protocol
  from there.
---

# wiki:lint — audit wiki consistency

You are the lint workflow for an LLM Wiki. The authoritative procedure lives in the wiki's `CLAUDE.md`.

## Step 1 — Locate the wiki

Find `CLAUDE.md` with frontmatter `type: schema` and `scope: wiki`:

1. Project-local: walk up from `pwd`
2. Vault root (Obsidian): `$VAULT_ROOT/**/wiki/CLAUDE.md`
3. Memory: single known wiki → use it
4. Multiple candidates: ask the user

## Step 2 — Read the corpus

Read every file under `entities/`, `concepts/`, `comparisons/`. Use `mcp__plugin_qmd_qmd__multi_get` with globs (`entities/*.md`, etc.) for efficiency when the qmd MCP is available.

## Step 3 — Detect issues

Per `wiki/CLAUDE.md`, find:

| Category | Definition |
|---|---|
| **Contradictions** | Two pages assert claims that cannot both be true |
| **Stale** | `last_updated` older than 30 days AND `confidence: low` |
| **Orphans** | Page has no inbound wikilinks from any other wiki body file |
| **Missing cross-refs** | Page mentions an entity by name but doesn't wikilink it |
| **Data gaps** | Entity/concept without a `Sources` section, or with `confidence: low` and no matching open `questions/<topic>.md` |

## Step 4 — Write findings

Create `questions/lint-YYYY-MM-DD.md` with frontmatter:

```yaml
---
type: question
tags: [lint]
last_updated: YYYY-MM-DD
confidence: high
---
```

Body: one `## <Category>` heading per non-empty bucket; under each, a bullet list of specific findings with `[[wikilinks]]` and one-line rationale.

## Step 5 — Log

Append `log.md`:

```markdown
## [YYYY-MM-DD] lint | <N findings across M categories>

- contradictions: X
- stale: Y
- orphans: Z
- missing cross-refs: W
- data gaps: V
```

## Hard rules

- Never auto-fix during lint — surface only, let the user triage
- Never write to `raw/`
- Lint always produces a log entry, even with zero findings (record the clean state)
