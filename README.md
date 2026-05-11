# LLM Wiki — portable scaffold

Personal **LLM-curated wiki**: a structured markdown KB that an LLM grows incrementally (ingest → sources → entities/concepts) instead of re-deriving knowledge each time through RAG. Local search via [qmd](https://github.com/tobi/qmd) + MCP integration with Claude Code.

This repository is both a **Claude Code marketplace** (so you can install the `wiki` plugin with one command) and a **template scaffold** (`init.sh` materializes a fresh wiki in any folder).

## Quickstart

```bash
# 1. Add this repo as a Claude Code marketplace and install the plugin
#    Inside Claude Code:
/plugin marketplace add genkovich/llm-wiki
/plugin install wiki@llm-wiki

# 2. Materialize a wiki skeleton inside your project
git clone https://github.com/genkovich/llm-wiki ~/.local/share/llm-wiki   # template files
~/.local/share/llm-wiki/init.sh /path/to/project/wiki

# 3. Install qmd (search engine: on-device BM25 + vector + LLM rerank)
npm install -g @tobilu/qmd
qmd collection add /path/to/project/wiki --name my-wiki
qmd context add qmd://my-wiki "<1-2 sentences about the domain — affects reranking>"
qmd embed   # first run downloads ~330MB of embedder GGUF
```

In Claude Code, install the qmd plugin so that `query`/`get`/`multi_get` are available as native MCP tools:

```
/plugin marketplace add tobi/qmd
/plugin install qmd@qmd
/reload-plugins
```

After that the skills are reachable under the `wiki:` namespace:

| Skill | Triggers on |
|---|---|
| `wiki:inbox` | `inbox this`, `wiki: inbox <url>`, drop a URL for later parsing |
| `wiki:parse` | `parse this`, `wiki: parse <path>`, a new file in `raw/_inbox/` |
| `wiki:query` | `wiki: <question>`, `що каже wiki про X`, `знайди в wiki` |
| `wiki:lint` | `wiki: lint`, `перевір wiki`, `audit the wiki` |

Each skill locates the target wiki by `type: schema, scope: wiki` in the `CLAUDE.md` frontmatter and runs the workflow from that wiki's `CLAUDE.md`.

## Cron / scheduled parse (optional)

Auto-parse `raw/_inbox/` every 10 minutes — through launchd on macOS or systemd user units on Linux.

### Common — env file

```bash
mkdir -p ~/.config
WIKI_PLUGIN_BASE="$HOME/.claude/plugins/cache/llm-wiki/wiki"
WIKI_PLUGIN="$WIKI_PLUGIN_BASE/$(ls -1t "$WIKI_PLUGIN_BASE" | head -1)"
cp "$WIKI_PLUGIN/scripts/wiki-parse.env.example" ~/.config/wiki-parse.env
# edit ~/.config/wiki-parse.env — set WIKI=/path/to/your/wiki
```

### macOS (launchd)

```bash
sed "s|__PLUGIN_ROOT__|$WIKI_PLUGIN|g" "$WIKI_PLUGIN/launchd/com.wiki-parse.plist.example" \
  > ~/Library/LaunchAgents/com.wiki-parse.plist
launchctl load ~/Library/LaunchAgents/com.wiki-parse.plist
```

Logs: `$WIKI/.cron-parse.log`. Stop: `launchctl unload ~/Library/LaunchAgents/com.wiki-parse.plist`.

### Linux (systemd user units)

```bash
mkdir -p ~/.config/systemd/user
for f in wiki-parse.service wiki-parse.timer; do
  sed "s|__PLUGIN_ROOT__|$WIKI_PLUGIN|g" "$WIKI_PLUGIN/systemd/$f.example" \
    > ~/.config/systemd/user/$f
done
systemctl --user daemon-reload
systemctl --user enable --now wiki-parse.timer
```

Logs: `~/.local/state/wiki-parse.log` and `$WIKI/.cron-parse.log`. Stop: `systemctl --user disable --now wiki-parse.timer`.

## Migration from manual symlink install

If you previously activated the plugin manually (the older instructions for this repo), undo that first to avoid a namespace collision with the marketplace install:

```bash
# 1. Remove the symlink
rm ~/.claude/local-plugins/wiki

# 2. Remove the manual flag from settings.json
python3 -c "import json,os; p=os.path.expanduser('~/.claude/settings.json'); d=json.load(open(p)); d.get('enabledPlugins',{}).pop('wiki@local', None); json.dump(d,open(p,'w'),indent=2,ensure_ascii=False)"

# 3. Restart Claude Code, then install via marketplace as in Quickstart
```

## Local development

Working on the plugin itself? Add the local checkout as a marketplace and reinstall after every change:

```
/plugin marketplace add /path/to/llm-wiki
/plugin install wiki@llm-wiki
/reload-plugins
```

## Customization

After `init.sh` runs, open and edit the placeholders in the new wiki:

- `wiki/CLAUDE.md` — replace `<DOMAIN>` and `<DOMAIN_DESCRIPTION>` with your domain. This is the schema the LLM reads on every ingest/query/lint
- `wiki/overview.md` — set the domain title in the heading
- `wiki/log.md` — set today's date in the bootstrap entry

## Workflows

Three workflows are described in the generated `wiki/CLAUDE.md` — the LLM reads them every time:

- **ingest** — new source (raw → `sources/<slug>.md` → updates to `entities/`/`concepts/`)
- **query** — question → MCP query → synthesis → optional filer-back into `comparisons/`/`questions/`
- **lint** — find contradictions / orphans / stale pages / data gaps

## Optional: Claude Code seed entities

If your domain is about Claude Code itself — drop in the stub entities from a real instance:

```bash
cp examples/claude-code-seeds/*.md /path/to/project/wiki/entities/
```

## Generated structure

```
wiki/
├── CLAUDE.md          schema & workflows (LLM reads every time)
├── index.md           Dataview catalog
├── log.md             append-only chronology
├── overview.md        thesis stub
├── raw/               immutable sources (LLM never edits)
│   ├── anthropic-docs/  articles/  transcripts/
│   ├── feedback/  assets/  _inbox/
├── entities/          concrete entities
├── concepts/          patterns and meta-ideas
├── sources/           1:1 summary per raw source
├── comparisons/       comparative analyses
└── questions/         open questions + lint findings
```

## Requirements

- Node.js or Bun (for qmd)
- ~2GB of disk for GGUF models (embedder + reranker, downloaded on first use)
- Obsidian optional (Dataview plugin renders `index.md`)

## Verification

```bash
qmd query "schema" -c my-wiki    # should return CLAUDE.md as the top hit
```

In Claude Code, ask: `wiki: what is this wiki and how do I use it?` — the query skill should find `CLAUDE.md` via MCP and answer.

## Docs

- Plugin marketplaces: <https://code.claude.com/docs/en/plugin-marketplaces>
- Plugins reference: <https://code.claude.com/docs/en/plugins-reference>
- qmd: <https://github.com/tobi/qmd>
