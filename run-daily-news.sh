#!/bin/bash
# Runs the daily AI news briefing via Claude CLI.
# Called by launchd at 6 AM PST daily.

set -euo pipefail

LOG_DIR="$HOME/Code/DailyAINews/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/daily-news-$(date +%Y-%m-%d).log"

exec &> >(tee -a "$LOG_FILE")
echo "=== Daily AI News run started at $(date) ==="

SKILL_FILE="$HOME/Documents/Claude/Scheduled/daily-ai-news/SKILL.md"
PROJECT_DIR="$HOME/Code/DailyAINews"

if [ ! -f "$SKILL_FILE" ]; then
  echo "Error: SKILL.md not found at $SKILL_FILE"
  exit 1
fi

PROMPT=$(cat "$SKILL_FILE")

cd "$PROJECT_DIR"

# Run claude in non-interactive print mode from the project directory
# so it picks up CLAUDE.md context automatically
/Users/patrickmalone/.local/bin/claude -p "$PROMPT" --verbose

echo "=== Daily AI News run finished at $(date) ==="
