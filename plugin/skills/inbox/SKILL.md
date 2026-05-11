---
name: inbox
description: >
  Use when the user wants to drop a source into the LLM Wiki inbox WITHOUT parsing
  it yet. Trigger phrases: "wiki:inbox <url|path>", "inbox this", "drop in inbox",
  "save to wiki later", "wiki: queue <url>", or when the user pastes a URL/file
  and says "for later". Stages the input in raw/_inbox/ so the wiki:parse skill
  (or the cron-ingest launchd job) can process it asynchronously. This skill does
  NOT call defuddle/yt-dlp/whisper — it only stages. Heavy parsing happens later.
---

# wiki:inbox — stage a source for later processing

Lightweight skill. Stages a source in `raw/_inbox/` without touching `sources/`, `entities/`, or `concepts/`. The `wiki:parse` skill (manual) or `cron-ingest.sh` launchd job (every 10 min) does the actual work later.

## Step 1 — Locate the wiki

Find `CLAUDE.md` with frontmatter `type: schema` and `scope: wiki`:

1. Project-local: walk up from `pwd`
2. Vault root (Obsidian): `$VAULT_ROOT/**/wiki/CLAUDE.md`
3. Memory: single known wiki → use it
4. Multiple candidates: ask the user

Confirm by reading frontmatter.

## Step 2 — Classify the input

| Input | How to stage |
|---|---|
| **URL** (any web link, YouTube, etc.) | Write a `.url` file inside `raw/_inbox/` with the URL on its own line and slug-derived filename |
| **Local file path** | Copy (do not move — leave original) into `raw/_inbox/<basename>` |
| **Paste of raw text/markdown** | Save as `raw/_inbox/<slug>-<YYYY-MM-DD>.md` with the text body |
| **Multiple URLs in one message** | One `.url` file per link |

### Filename slug rules

- kebab-case, lowercase
- For URLs: derive from the URL path (e.g., `youtube.com/watch?v=ABC` → `abc.url`, `anthropic.com/news/foo-bar` → `foo-bar.url`)
- For YouTube: use the video ID where possible (`<video-id>.url` or `<title-slug>.url`) — easier for `yt-dlp` lookup later
- If a slug collision exists, append `-2`, `-3` etc.

## Step 3 — Stage and confirm

1. Create `raw/_inbox/<slug>.<ext>` with the content
2. Print a short confirmation: filename, kind, queue size (`ls raw/_inbox/ | wc -l`)
3. Tell the user when it will be processed:
   - "launchd `com.wiki-parse` runs every 10 min — will pick this up on next tick"
   - If they want it parsed now: "say `wiki:parse raw/_inbox/` to run immediately"

## Step 4 — Log (optional, lightweight)

Do NOT append to `log.md` here. The `wiki:parse` skill writes the proper ingest log entry after processing. An inbox-only entry would just create noise.

## Hard rules

- Never call defuddle, yt-dlp, whisper, or any heavy network/CPU work in this skill
- Never write to `sources/`, `entities/`, `concepts/`, `comparisons/`, or `questions/`
- Never edit `log.md` from this skill
- Never delete or move existing files out of `_inbox/` — only add new ones
- If the same filename already exists in `_inbox/`, ask the user before overwriting

## Why this exists

Parsing is expensive (LLM context, whisper minutes, defuddle network). The user often wants to *capture now, process later* — like browser bookmarks or read-later apps. This skill is the wiki equivalent: 5-second drop-off, nothing more. Heavy lifting is async via launchd.
