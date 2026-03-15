# AI News — Saturday, March 14, 2026

---

## Karpathy launches AgentHub — "GitHub, but for AI agents"
**Mar 11** — Andrej Karpathy (@karpathy)

Karpathy dropped AgentHub, an open-source collaboration platform designed for swarms of AI agents working on the same codebase. Instead of branches, PRs, and merges, it exposes a bare git DAG where agents push commits via bundles and coordinate through a built-in message board. Built as the organizational layer for autoresearch, it's explicitly a sketch — but hit 2,000+ GitHub stars in under 24 hours. The "GitHub for agents" framing is already spawning forks and community implementations.

[Karpathy's AgentHub](https://github.com/karpathy/agenthub) · [Yuchen Jin's breakdown](https://x.com/Yuchenj_UW/status/2031438602383798514)

---

## Claude Code adds MCP elicitation — servers can now ask you questions mid-task
**Mar 14** — Claude Code changelog (v2.1.76)

Claude Code now supports MCP elicitation, letting MCP servers request structured input from the user via an interactive dialog while a task is running. New `Elicitation` and `ElicitationResult` hooks let developers tap into this flow. Also added a `-n` / `--name` CLI flag to name sessions at startup.

[Claude Code changelog](https://code.claude.com/docs/en/changelog)

---

## Claude Code gets /color, session names, and smarter memory
**Mar 13** — Boris Cherny (@bcherny), Claude Code changelog (v2.1.75)

Anthropic shipped a batch of Claude Code updates: a `/color` command to tag sessions with a prompt-bar color, session name display when using `/rename`, and last-modified timestamps on memory files so Claude can reason about which memories are fresh vs. stale. 1M context window enabled by default for Opus on Max/Team/Enterprise plans. Also fixed voice mode, model switching, and HTTP 400 errors for users behind proxies on Bedrock/Vertex.

[Claude Code changelog](https://code.claude.com/docs/en/changelog) · [Claude Code release notes](https://releasebot.io/updates/anthropic/claude-code)

---

## Autoresearch goes distributed — 35 agents, 333 experiments, zero humans
**Mar 10** — Andrej Karpathy (@karpathy)

Following Karpathy's autoresearch release, Varun Mathur (Hyperspace AI) distributed the single-agent loop across a peer-to-peer network. On the night of March 8–9, 35 autonomous agents ran 333 experiments completely unsupervised. Karpathy's original 2-day run found ~20 real improvements that cut time-to-GPT-2 by 11% — the distributed version is scaling that approach to a research community.

[Karpathy's results post](https://x.com/karpathy/status/2031135152349524125) · [Autoresearch repo](https://github.com/karpathy/autoresearch)

---
