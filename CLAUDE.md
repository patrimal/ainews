# AI News Aggregator

Daily AI news briefing system that publishes to ainews.malone.gr via Vercel.

## Repository & Hosting

- **Repo:** github.com/patrimal/ainews (public)
- **Hosting:** Vercel (project: `ainews-deploy` under `patrick-9375s-projects`)
- **Vercel URL:** https://ainews-deploy.vercel.app
- **Custom domain:** ainews.malone.gr (DNS A record → 76.76.21.21)
- **Owner:** patrimal

## Project files

All project files live in this directory (`~/Code/DailyAINews`) and are pushed to `patrimal/ainews`:

- `CLAUDE.md` — this file (project documentation)
- `ai-news-sources.md` — curated list of sources to monitor
- `publish.sh` — deployment script (clone, archive, push, deploy)
- `run-daily-news.sh` — runner script invoked by launchd to run the daily briefing via `claude -p`

## Site files (deployed)

Site files are in `ainews-site/` locally and pushed to the root of `patrimal/ainews`:

- `index.html` — main page with today's stories baked in as HTML
- `archive/index.html` — archive listing, reads archive/index.json
- `archive/view.html` — renders individual archived briefings (HTML pages)
- `archive/index.json` — archive manifest (updated daily)

## Daily publishing

A macOS **launchd agent** (`com.patrickmalone.daily-ai-news`) runs at 6 AM PST every day. It invokes `run-daily-news.sh`, which calls `claude -p` with the SKILL.md prompt. Claude generates `ainews-site/index.html` with stories baked in, then runs `publish.sh` which:

1. Clones `patrimal/ainews`
2. Archives the current `index.html` to `archive/ainews-YYYY-MM-DD.html`
3. Updates `archive/index.json` (reverse chronological)
4. Copies new site files from `ainews-site/`
5. Commits, pushes to GitHub, and deploys via `vercel --prod`

**Launchd plist:** `~/Library/LaunchAgents/com.patrickmalone.daily-ai-news.plist`
**Task prompt:** `~/Documents/Claude/Scheduled/daily-ai-news/SKILL.md`
**Logs:** `logs/` directory (created at runtime)

## How the site works

The site is fully static — no build step. Stories are baked directly into `index.html` as HTML. Dark mode is automatic via `prefers-color-scheme`. Mobile-first design (max-width 640px).

The archive page reads `archive/index.json` for the list of past briefings. Archived files are full HTML pages; `view.html` extracts and renders the `#content` div from them.

## Briefing format

The scheduled task generates `ainews-site/index.html` with stories as HTML. Each story uses date tag bubbles:

- **Today** (`tag-today`, green): news from the same day as the report
- **Yesterday** (`tag-yesterday`, amber): news from the previous day
- **Older dates** (`tag-date`, gray): abbreviated date like "Mar 11"

Stories are sorted newest-first (Today at top, then Yesterday, then older).

## Sources

Sources are tracked in `ai-news-sources.md` in this folder. Current sources:

- Andrej Karpathy (@karpathy) — AI research, LLMs, deep learning
- Boris Cherny (@bcherny) — Anthropic, creator of Claude Code, agentic engineering
- swyx / Shawn Wang (@swyx) — AI engineering, Latent Space podcast
- Simon Willison (@simonw) — Practical LLM usage, AI tool testing
- TLDR AI (tldr.tech/ai) — Daily AI digest newsletter
