# LLM Wiki — Operator Guide

Cheat-sheet: what to say so the LLM runs the right workflow. Not a tutorial — just a list of triggers and a daily cadence. Schema and procedures live in `CLAUDE.md`.

## What to say

Workflows are provided by the `wiki` plugin — four skills in the `wiki:` namespace.

| Phrase / skill | What happens | Expect |
|---|---|---|
| `inbox this` / `wiki: inbox <url>` → **`wiki:inbox`** | Stages a URL/file into `raw/_inbox/` without parsing | Confirmation + queue size |
| `parse this` / `wiki: parse <path>` → **`wiki:parse`** | LLM reads the raw file, creates `sources/<slug>.md`, updates 10-15 entities/concepts, adds a log entry | Diff over 5-15 files + a new source summary |
| `wiki: <question>` / `що каже wiki про X` → **`wiki:query`** | MCP `qmd query` → synthesis with inline citations `[[wikilink]]` | Answer + offer to filer-back into `comparisons/` or `questions/` |
| `wiki: lint` / `перевір wiki` → **`wiki:lint`** | Scans for contradictions / orphans / stale / data gaps | `questions/lint-YYYY-MM-DD.md` with findings |
| `wiki: rebuild index` | Regenerate `index.md` via Dataview | Updated catalog |
| New file in `raw/_inbox/` | `wiki:parse` processes it as ingest | Same result as `parse this` |

For explicit invocation use the fully qualified skill name (e.g., "run wiki:lint" or "wiki:parse <path>").

## Daily cadence

**Found a source (article / transcript / doc):**
1. Drop it into `raw/_inbox/` (or pass a URL — the `defuddle` skill clips it into `raw/anthropic-docs/`)
2. Say: `ingest this`
3. Review the diff — especially that `confidence` is realistic and `questions/` was created for low-confidence claims

**Writing a lecture / doc / post:**
1. `wiki: what do we have on <topic>?` — get a synthesis
2. If the topic spans 2+ entities — ask `wiki: compare X and Y` and save it as a comparison
3. If you find an unbacked claim — `wiki: add a question about <topic>`

**Once a week (or before a big writing sprint):**
1. `wiki: lint`
2. Walk through `questions/lint-*.md` together — close the data gaps by ingesting new sources

## What NOT to do

- ❌ Do not edit `raw/` by hand. These are immutable sources — any manual edit breaks traceability
- ❌ Do not write entities without `sources:` in frontmatter. An unbacked claim → `confidence: low` + an entry in `questions/`
- ❌ Do not skip the `log.md` entry. Every ingest / query-with-filer-back / lint must leave a trace — without it the wiki loses its memex property
- ❌ Do not confuse entities (concrete things) with concepts (patterns / meta-ideas). When in doubt — ask the LLM before creating

## When the wiki does NOT help

- Fewer than 10 entities — `grep` over `raw/` or Google is faster. The wiki starts paying off around ~20-30 sources
- A question about a single known source — just `qmd get sources/<slug>`
- Fast-moving information (current bug, API status) — the wiki is long-term memory, not realtime
