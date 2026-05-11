#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <wiki-target-dir>"
  echo "Example: $0 /path/to/project/wiki"
  exit 1
fi

TEMPLATE="$(cd "$(dirname "$0")" && pwd)/template"

if [ ! -d "$TEMPLATE" ]; then
  echo "Error: template directory not found at $TEMPLATE"
  exit 1
fi

if [ -e "$TARGET/CLAUDE.md" ]; then
  echo "Error: wiki already exists at $TARGET (CLAUDE.md found)"
  exit 1
fi

mkdir -p "$TARGET"
cp -R "$TEMPLATE/." "$TARGET/"
find "$TARGET" -name '.gitkeep' -delete

cat <<EOF
✓ Wiki scaffold created at $TARGET

Next:
  1. Edit $TARGET/CLAUDE.md       — replace <DOMAIN> and <DOMAIN_DESCRIPTION>
  2. Edit $TARGET/overview.md     — set domain title
  3. Edit $TARGET/log.md          — set today's date in the bootstrap entry
  4. Read $TARGET/USAGE.md        — operator cheat-sheet (triggers + cadence)

Install the wiki plugin into Claude Code (marketplace):
  /plugin marketplace add genkovich/llm-wiki
  /plugin install wiki@llm-wiki
  /reload-plugins

  Skills available: wiki:inbox, wiki:parse, wiki:query, wiki:lint

Then index with qmd:
  npm install -g @tobilu/qmd
  qmd collection add "$TARGET" --name <collection>
  qmd context add qmd://<collection> "<description>"
  qmd embed

Then install the qmd MCP plugin in Claude Code:
  /plugin marketplace add tobi/qmd
  /plugin install qmd@qmd
  /reload-plugins

Optional cron/launchd/systemd setup for auto-parse: see README.md
Optional Claude-Code seed entities:
  cp examples/claude-code-seeds/*.md "$TARGET/entities/"
EOF
