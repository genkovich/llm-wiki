#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: curl -fsSL https://raw.githubusercontent.com/genkovich/llm-wiki/main/init.sh | bash -s <wiki-target-dir>"
  echo "Example: curl -fsSL https://raw.githubusercontent.com/genkovich/llm-wiki/main/init.sh | bash -s ./wiki"
  exit 1
fi

if [ -e "$TARGET/CLAUDE.md" ]; then
  echo "Error: wiki already exists at $TARGET (CLAUDE.md found)"
  exit 1
fi

REPO_URL="https://codeload.github.com/genkovich/llm-wiki/tar.gz/refs/heads/main"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/llm-wiki.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching template from $REPO_URL ..."
curl -fsSL "$REPO_URL" | tar -xz -C "$TMP" --strip-components=1

TEMPLATE="$TMP/template"
if [ ! -d "$TEMPLATE" ]; then
  echo "Error: template/ missing in fetched tarball"
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
