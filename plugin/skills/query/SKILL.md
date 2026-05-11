---
name: query
description: >
  Use when the user invokes LLM Wiki query workflow — explicitly via "wiki:query",
  "wiki: <question>", "що каже wiki про X", "знайди в wiki", "ask the wiki", or
  similar retrieve-and-synthesize requests against an LLM Wiki. Performs MCP qmd
  search across the wiki collection, reads the top-N results, and returns a synthesis
  with inline wikilink citations. Optionally proposes a filer-back into comparisons/
  or questions/. Recognizes the wiki by a CLAUDE.md with `type: schema, scope: wiki`
  frontmatter and follows the query protocol from that file.
---

# wiki:query — answer a question from the wiki

You are the query workflow for an LLM Wiki. The authoritative procedure lives in the wiki's `CLAUDE.md`.

## Step 1 — Locate the wiki

Find `CLAUDE.md` with frontmatter `type: schema` and `scope: wiki`:

1. Project-local: walk up from `pwd`
2. Vault root (Obsidian): `$VAULT_ROOT/**/wiki/CLAUDE.md`
3. Memory: single known wiki → use it
4. Multiple candidates: ask the user

Determine the qmd collection name (usually the wiki folder slug; if `CLAUDE.md` mentions one explicitly, prefer that).

## Step 2 — Run the search

**Preferred:** `mcp__plugin_qmd_qmd__query` with:

- `searches`: at least one `{type:'lex', query:'<keywords>'}` and one `{type:'vec', query:'<semantic rephrase>'}`. Add `{type:'hyde', query:'<hypothetical answer>'}` for hard questions
- `intent`: one sentence describing what the user actually wants — improves rerank
- `collection`: the wiki collection name
- `minScore: 0.5` to cut noise

**Fallback chain** if MCP missing: `qmd query "<q>" -c <collection>` via Bash → Grep over `entities/ concepts/ comparisons/ sources/`.

## Step 3 — Read and synthesize

1. Read `index.md` for shape of the wiki
2. Read the top hits in full (use `mcp__plugin_qmd_qmd__multi_get` if multiple)
3. Produce a synthesis grounded in those pages — every claim gets an inline citation `[[entities/foo]]` or `[[sources/bar]]`. No unbacked assertions
4. Note any contradictions or gaps you spot

## Step 4 — Offer filer-back

After answering, ask the user:

> Worth saving this as `comparisons/<slug>.md` or an open `questions/<slug>.md`?

If yes:

- Create the file with proper frontmatter (`type: comparison` or `type: question`, `tags`, `sources`, `last_updated`, `confidence`)
- Append `log.md`: `## [YYYY-MM-DD] query | <question>` + 2-3 bullets

If no, skip the log entry — pure read-only queries don't get logged.

## Hard rules

- Never invent wikilinks; only cite pages you actually read
- Never write to `raw/`
- If the wiki has no relevant content, say so plainly and suggest a `wiki:parse` to fill the gap
