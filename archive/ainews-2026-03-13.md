# AI News — Saturday, March 14, 2026

---

## Karpathy launches AgentHub — "GitHub, but for AI agents"
**Mar 11** — Andrej Karpathy (@karpathy)

Karpathy dropped AgentHub, an open-source collaboration platform designed for swarms of AI agents working on the same codebase. Instead of branches, PRs, and merges, it exposes a bare git DAG where agents push commits via bundles and coordinate through a built-in message board. Built as the organizational layer for autoresearch, it's explicitly a sketch — but hit 2,000+ GitHub stars in under 24 hours. The "GitHub for agents" framing is already spawning forks and community implementations.

[Karpathy's AgentHub](https://github.com/karpathy/agenthub) · [Yuchen Jin's breakdown](https://x.com/Yuchenj_UW/status/2031438602383798514)

---

## Claude Code gets /color, session names, and smarter memory
**Mar 13** — Boris Cherny (@bcherny)

Anthropic shipped a batch of Claude Code updates: a `/color` command to tag sessions with a prompt-bar color, session name display when using `/rename`, and last-modified timestamps on memory files so Claude can reason about which memories are fresh vs. stale. Also fixed voice mode, model switching, and HTTP 400 errors for users behind proxies on Bedrock/Vertex.

[Claude Code release notes](https://releasebot.io/updates/anthropic/claude-code)

---

## Autoresearch goes distributed — 35 agents, 333 experiments, zero humans
**Mar 10** — Andrej Karpathy (@karpathy)

Following Karpathy's autoresearch release, Varun Mathur (Hyperspace AI) distributed the single-agent loop across a peer-to-peer network. On the night of March 8–9, 35 autonomous agents ran 333 experiments completely unsupervised. Karpathy's original 2-day run found ~20 real improvements that cut time-to-GPT-2 by 11% — the distributed version is scaling that approach to a research community.

[Karpathy's results post](https://x.com/karpathy/status/2031135152349524125) · [Autoresearch repo](https://github.com/karpathy/autoresearch)

---
