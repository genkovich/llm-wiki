#!/usr/bin/env bash
# Background parse for LLM Wiki — runs from launchd/systemd.
# Checks raw/_inbox/ for new files; if any exist, fires `claude -p wiki:parse`
# headlessly and lets the skill process+route them into raw/<subfolder>/.

set -euo pipefail

# --- Config: read env from XDG-style config file if present, else expect env from launchd/systemd ---
WIKI_PARSE_ENV="${WIKI_PARSE_ENV:-$HOME/.config/wiki-parse.env}"
# shellcheck disable=SC1090
[ -f "$WIKI_PARSE_ENV" ] && source "$WIKI_PARSE_ENV"

: "${WIKI:?WIKI env var required (set in $WIKI_PARSE_ENV or via launchd/systemd EnvironmentFile)}"
: "${CLAUDE_BIN:=$HOME/.local/bin/claude}"
: "${WIKI_PARSE_SKILL:=wiki:parse}"

LOG="$WIKI/.cron-parse.log"
LOCK="$WIKI/.cron-parse.lock"

mkdir -p "$WIKI/raw/_inbox" "$WIKI/raw/_inbox/_processed"
cd "$WIKI"

# --- Skip if inbox is empty (ignore _processed/ subfolder and dotfiles) ---
shopt -s nullglob
inbox_files=()
for f in raw/_inbox/*; do
  base="$(basename "$f")"
  [ "$base" = "_processed" ] && continue
  [ "$base" = ".gitkeep" ] && continue
  [ -d "$f" ] && continue
  inbox_files+=("$f")
done
if [ ${#inbox_files[@]} -eq 0 ]; then
  exit 0
fi

# --- Skip if another run still going ---
if [ -f "$LOCK" ]; then
  pid=$(cat "$LOCK")
  if kill -0 "$pid" 2>/dev/null; then
    echo "[$(date -u +%FT%TZ)] still running pid=$pid, skipping" >> "$LOG"
    exit 0
  fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# --- Run headless parse ---
{
  echo "==================================================================="
  echo "[$(date -u +%FT%TZ)] parse start — ${#inbox_files[@]} file(s) in _inbox"
  printf '  %s\n' "${inbox_files[@]}"
  echo "-------------------------------------------------------------------"
} >> "$LOG"

"$CLAUDE_BIN" -p "${WIKI_PARSE_SKILL} raw/_inbox/" \
  --permission-mode=acceptEdits \
  --output-format=text \
  >> "$LOG" 2>&1

echo "[$(date -u +%FT%TZ)] parse done" >> "$LOG"
