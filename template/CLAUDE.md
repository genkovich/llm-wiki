---
type: schema
scope: wiki
last_updated: 2026-01-01
---

# LLM Wiki — Schema & Workflows

<!-- Replace <DOMAIN> with a 1-2 sentence description of your domain -->

This is a **personal LLM-curated wiki** for **`<DOMAIN>`**. Pattern: LLM Memex — a structured markdown KB that the LLM grows incrementally instead of re-deriving knowledge each time through RAG.

## Purpose

<!-- Replace <DOMAIN_DESCRIPTION> — why this wiki exists, which kinds of knowledge it stores -->

`<DOMAIN_DESCRIPTION>`. A second brain for the domain: entities, source summaries, contradictions, an evolving thesis. On a query the wiki returns a synthesis instead of dozens of re-reads.

## Three layers

### 1. `raw/` — immutable sources
The LLM **never edits** these. Read-only.

- `raw/anthropic-docs/` — clipped/fetched pages (via the `defuddle` skill or a Web Clipper)
- `raw/articles/` — articles, blog posts, threads
- `raw/transcripts/` — YouTube / podcast transcripts
- `raw/feedback/` — feedback, customer interviews
- `raw/assets/` — images
- `raw/_inbox/` — unprocessed new sources

### 2. Wiki body — LLM-owned

- `index.md` — page catalog (Dataview)
- `log.md` — chronological append-only: `## [YYYY-MM-DD] ingest|query|lint | Title`
- `overview.md` — high-level thesis of the domain
- `entities/` — concrete entities (snake_case slugs)
- `concepts/` — patterns and meta-ideas
- `sources/` — 1:1 summary per file in `raw/`, with backlinks
- `comparisons/` — comparative analyses
- `questions/` — open questions, hypotheses, lint findings

### 3. This file — schema / conventions

## Frontmatter (required)

```yaml
---
type: entity | concept | source | comparison | question | overview
tags: [list]
sources:                       # array of wikilinks to raw/ or sources/
  - "[[sources/<slug>]]"
last_updated: YYYY-MM-DD
confidence: high | medium | low
---
```

For `sources/` — additionally:
```yaml
raw: "[[raw/<path>]]"
url: https://...
fetched: YYYY-MM-DD
```

## Conventions

- **Wikilinks:** `[[entities/<slug>]]`, embeds `![[sources/<slug>#Summary]]`
- **Sources section** at the end of every entity/concept/comparison: a bullet list of `[[wikilink]]` items with citation context
- **Snake_case slugs:** `my-entity.md`
- **Dates:** ISO `YYYY-MM-DD`
- **Every claim → a source:** no unbacked statements in entities/concepts. If a claim comes from memory or guesswork — set `confidence: low` and open a `questions/` entry

## Workflows

### Ingest (`raw → sources → entities/concepts`)

Trigger: the user says "ingest this source" or drops a file into `raw/_inbox/`.

1. Read the raw file in full
2. Discuss takeaways with the user (1-2 sentences each)
3. Create `sources/<slug>.md` with frontmatter (`type: source`, `raw: [[...]]`, `url`, `fetched`) plus sections: Summary / Key claims / Quotes / Backlinks
4. Touch 10-15 entities/concepts: add a new claim with citation `[[sources/<slug>]]`, refresh `last_updated`. Create new ones when warranted
5. Sync `index.md` (Dataview blocks auto-refresh, but any manual sections need sync)
6. Append `log.md`: `## [YYYY-MM-DD] ingest | <Source title>` + 3-5 bullets describing what changed

### Query

Trigger: "wiki: <question>".

1. Read `index.md` (sense of what exists)
2. **Preferred:** MCP `mcp__plugin_qmd_qmd__query` (lex+vec sub-queries, intent, collection=`<COLLECTION>`). Fallback: `qmd query "<q>" -c <COLLECTION>` via Bash, or Grep
3. Read the relevant pages
4. Synthesize an answer with inline citations `[[wikilink]]`
5. Ask: filer-back into `comparisons/` or `questions/`?
6. If yes — create the file and append `log.md`: `## [YYYY-MM-DD] query | <question>`

### Lint

Trigger: "wiki: lint".

1. Read every file under `entities/`, `concepts/`, `comparisons/`
2. Find:
   - **Contradictions:** claims that cannot both be true
   - **Stale:** `last_updated` >30 days AND `confidence: low`
   - **Orphans:** pages with no inbound wikilinks
   - **Missing cross-refs:** an entity is mentioned by name but not wikilinked
   - **Data gaps:** entity without a Sources section, or `confidence: low` without a matching `questions/` entry
3. Write findings into `questions/lint-YYYY-MM-DD.md`
4. Append `log.md`

## Hard rules

- Wiki pages **always** have frontmatter + a Sources section (except `log.md`, `index.md`, and this file)
- The LLM **never** writes into `raw/`
- Every ingest → log entry. Every query with filer-back → log entry. Every lint → log entry
- If `confidence: low` → also create `questions/<topic>.md` with the open question

## Tooling

- **qmd** ([github.com/tobi/qmd](https://github.com/tobi/qmd)) — on-device search engine for agentic flows. BM25 + vector + LLM rerank, local via node-llama-cpp + GGUF. Commands:
  - `qmd search "<q>" -c <COLLECTION>` — keyword (BM25)
  - `qmd vsearch "<q>" -c <COLLECTION>` — semantic (vector)
  - `qmd query "<q>" -c <COLLECTION>` — hybrid + rerank (best)
  - `qmd get <path|#docid>`, `qmd multi-get '<glob>'`
  - After new/changed files: `qmd embed` (incremental)
- **Dataview** (Obsidian): dynamic tables in `index.md`
- **defuddle** skill: clip URLs into `raw/anthropic-docs/`
