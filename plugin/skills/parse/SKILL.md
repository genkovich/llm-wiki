---
name: parse
description: >
  Use when the user invokes LLM Wiki parse workflow — explicitly via "wiki:parse",
  "parse this", "parse this folder", "wiki: parse <path|url>", drops a YouTube
  link, or when a new file is dropped into a wiki's raw/_inbox/. Handles four input
  kinds: single file, folder (batch), generic URL (defuddle clip), or YouTube URL
  (yt-dlp transcript + optional whisper). Processes each source into the wiki:
  creates sources/<slug>.md summary, updates 10-15 entities/concepts with
  citations, appends a log entry. Recognizes the target wiki by a CLAUDE.md with
  `type: schema, scope: wiki` frontmatter. Reads that CLAUDE.md for the
  authoritative ingest protocol before acting.
---

# wiki:parse — ingest a source into the wiki

You are the ingest workflow for an LLM Wiki. The authoritative procedure lives in the target wiki's `CLAUDE.md` — read it before acting.

## Step 1 — Locate the wiki

Find `CLAUDE.md` with frontmatter `type: schema` and `scope: wiki`:

1. Project-local: `pwd` and walk up — look for `wiki/CLAUDE.md`
2. Vault root (if Obsidian): `$VAULT_ROOT/**/wiki/CLAUDE.md`
3. Memory: if exactly one wiki is known from prior memory, use it
4. Multiple candidates: ask the user

## Step 2 — Classify the input

Argument can be a file path, folder path, URL, YouTube URL, the literal `this`, or empty. Detect kind:

| Input | How to detect | Action |
|---|---|---|
| **YouTube URL** | matches `youtube.com/watch`, `youtu.be/`, `youtube.com/shorts/` | go to **Step 2a** |
| **Generic URL** | starts with `http(s)://`, not YouTube | call `obsidian:defuddle` → `raw/anthropic-docs/<slug>.md` |
| **Folder** | `[ -d "$path" ]` | go to **Step 2b** (batch) |
| **File** | `[ -f "$path" ]` and lives under `raw/` | use as-is. If outside `raw/` — ask user where it belongs |
| **`this` / empty** | no arg | pick the most recently modified file in `raw/_inbox/`; if empty, ask user |

### Step 2a — YouTube transcript

1. Make target dir: `mkdir -p wiki/raw/transcripts`
2. Try existing captions first (no transcription needed):
   ```bash
   yt-dlp --skip-download --write-auto-sub --write-sub \
     --sub-lang "en,uk,en-orig" --sub-format vtt \
     -o "wiki/raw/transcripts/%(id)s.%(ext)s" "<URL>"
   ```
3. If no captions produced (`.vtt` missing), fall back to whisper:
   ```bash
   yt-dlp -x --audio-format mp3 -o "wiki/raw/transcripts/%(id)s.%(ext)s" "<URL>"
   whisper "wiki/raw/transcripts/<id>.mp3" --model small --output_format txt \
     --output_dir wiki/raw/transcripts
   ```
4. Convert `.vtt`/`.txt` into a clean markdown at `wiki/raw/transcripts/<slug>.md` with metadata header (video title via `yt-dlp --get-title`, URL, duration, channel, fetched date)
5. Treat that markdown as the raw source going into Step 3

### Step 2b — Folder batch

1. List all `.md`, `.txt`, and other text files in the folder (skip binaries)
2. Count `N` files. Pick mode:
   - **N ≤ 5:** sequential, full protocol per file (Steps 3-4), pause for user confirmation between files
   - **5 < N ≤ 20:** sequential, full protocol per file, no inter-file pauses; rollup log entry at end
   - **N > 20:** **parallel-split mode** (Step 2c)
3. **If the folder is `raw/_inbox/`:** after Step 4 succeeds for each file, **move** the source out of `_inbox/` into its permanent home:
   - `.url` / `.txt` containing a URL → already processed via defuddle/yt-dlp, original moves to `raw/_inbox/_processed/<filename>`
   - YouTube source → `raw/transcripts/<id>.md` (already there from Step 2a)
   - Generic article (defuddle output) → already in `raw/anthropic-docs/` (from Step 2a)
   - Plain markdown/text dropped manually → `raw/articles/<filename>` (or `raw/_inbox/_processed/` if unclear)
   - This guarantees idempotency: cron re-runs see an empty inbox and exit immediately

### Step 2c — Parallel-split mode (large batches)

Use this when N > 20. Splits work between subagents to avoid sequential bottleneck and write conflicts.

**Phase A — sources/ (parallel, idempotent writes):**

1. Group files into chunks of ~10. Dispatch one Agent (subagent_type: general-purpose) per chunk in a single message with multiple Agent tool calls (true parallel)
2. Each agent's prompt: "Read each raw file in this list. For each, write `sources/<slug>.md` in <wiki path> with frontmatter (`type: source`, `raw: [[...]]`, `url`, `fetched`, `tags`, `confidence`) and sections Summary / Key claims / Quotes / Backlinks. Do NOT touch entities/ or concepts/ — that's a later pass. Return list of slugs created."
3. Wait for all agents to finish

**Phase B — entities/concepts sweep (single thread, after Phase A):**

4. Read all newly created `sources/*.md`
5. Identify recurring topics → cluster into existing or new entities/concepts
6. For each touched entity: append claim with `[[sources/<slug>]]` citation, refresh `last_updated`
7. Create new entities/concepts where needed (10-30 typical for 80+ sources)

**Phase C — finalize:**

8. Single rollup log entry summarizing the batch
9. `qmd update && qmd embed`

## Step 3 — Read wiki/CLAUDE.md

Read the schema in full. Do not paraphrase or shortcut steps.

## Step 4 — Execute the ingest workflow (per source)

Per `wiki/CLAUDE.md`:

1. Read the raw file completely
2. Discuss takeaways with the user (1-2 sentences each) before writing — in batch mode, summarize per file but skip the back-and-forth
3. Create `sources/<slug>.md` with frontmatter (`type: source`, `raw: [[...]]`, `url`, `fetched: YYYY-MM-DD`, `tags`, `confidence`) and sections: **Summary** / **Key claims** / **Quotes** / **Backlinks**. For YouTube sources add `video_id`, `channel`, `duration` fields
4. Touch 10-15 `entities/` and `concepts/`: add new claims with citation `[[sources/<slug>]]`, refresh `last_updated`. Create new entities/concepts if warranted
5. Sync `index.md` if it contains manual sections (Dataview blocks auto-refresh)
6. Append `log.md`:

   ```markdown
   ## [YYYY-MM-DD] ingest | <Source title>

   - bullet 1 — what changed
   - bullet 2
   - bullet 3
   ```

   For batch ingests: one log entry per source, OR one rollup entry with sub-bullets listing each source — your choice based on scale.

## Step 5 — Reindex qmd

After all sources written:

```bash
qmd update && qmd embed
```

Mention this in the final summary so the user knows the search index is fresh.

## Hard rules

- Never write into `raw/` after Step 2 — read-only from Step 3 onward
- Every claim in entities/concepts must cite a source; otherwise `confidence: low` + matching `questions/<topic>.md`
- Ingest must produce a log entry — no exceptions
- For YouTube: prefer existing captions over whisper transcription (faster, accurate, no GPU needed). Only fall back to whisper if captions truly absent
- In folder batch mode: stop at 5 files and check in with the user. Don't run autonomously on 100+ files
- Record the canonical URL in `url:` frontmatter for any web/YouTube source
