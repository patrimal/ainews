#!/bin/bash
# Publishes the current ainews-site/ to the patrimal/ainews repo and deploys to Vercel.
# Usage: ./publish.sh
# Called by the daily-ai-news scheduled task after generating index.html.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$SCRIPT_DIR/ainews-site"
REPO_URL="https://github.com/patrimal/ainews.git"
WORK_DIR=$(mktemp -d)
TODAY=$(date +%Y-%m-%d)

trap 'rm -rf "$WORK_DIR"' EXIT

if [ ! -f "$SITE_DIR/index.html" ]; then
  echo "Error: $SITE_DIR/index.html not found"
  exit 1
fi

echo "Cloning repo..."
git clone "$REPO_URL" "$WORK_DIR" 2>&1

# Archive the current index.html if it exists and has content
if [ -f "$WORK_DIR/index.html" ]; then
  ARCHIVE_DATE=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d yesterday +%Y-%m-%d)

  # Don't archive if it's the same date as today
  if [ "$ARCHIVE_DATE" != "$TODAY" ]; then
    ARCHIVE_FILE="archive/ainews-${ARCHIVE_DATE}.html"
    echo "Archiving current briefing to $ARCHIVE_FILE"
    cp "$WORK_DIR/index.html" "$WORK_DIR/$ARCHIVE_FILE"

    # Update archive/index.json
    INDEX_FILE="$WORK_DIR/archive/index.json"
    if [ -f "$INDEX_FILE" ]; then
      python3 -c "
import json
with open('$INDEX_FILE') as f:
    entries = json.load(f)
new_entry = {'file': 'ainews-${ARCHIVE_DATE}.html', 'date': '${ARCHIVE_DATE}'}
if not any(e['date'] == '${ARCHIVE_DATE}' for e in entries):
    entries.insert(0, new_entry)
with open('$INDEX_FILE', 'w') as f:
    json.dump(entries, f, indent=2)
"
      echo "Updated archive/index.json"
    fi
  fi
fi

# Copy new site files
cp "$SITE_DIR/index.html" "$WORK_DIR/index.html"
cp "$SITE_DIR/archive/index.html" "$WORK_DIR/archive/index.html" 2>/dev/null || true
cp "$SITE_DIR/archive/view.html" "$WORK_DIR/archive/view.html" 2>/dev/null || true
echo "Copied site files"

# Commit and push
cd "$WORK_DIR"
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Update briefing for $TODAY"
  git push origin main 2>&1
  echo "Pushed to GitHub"
fi

# Deploy to Vercel
echo "Deploying to Vercel..."
vercel --prod --yes --cwd "$WORK_DIR" 2>&1
echo "Deploy complete"
