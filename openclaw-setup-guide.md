## Context

This document provides a comprehensive guide for setting up OpenClaw securely and privately, along with the top 20 productivity use cases — each with a detailed risk assessment and mitigation strategies. OpenClaw is the fastest-growing open-source project on GitHub (247k+ stars in ~60 days), but its power comes with significant security implications that must be carefully managed.

---

## Part 1: Secure & Private Setup Guide

### 1.1 Understanding the Architecture

OpenClaw is a long-running Node.js service that connects LLMs (Claude, GPT, DeepSeek, local models) to your local machine and messaging apps (Signal, Telegram, Discord, WhatsApp). Key architectural facts:

- **Local-first but NOT local-processing**: The core app runs on your hardware, but prompts still travel over the public internet to LLM API endpoints
- **Gateway model**: OpenClaw's Gateway listens on port 18789 via WebSocket — this is the primary attack surface
- **Skills system**: Functionality comes from skill directories containing SKILL.md files — these are a supply chain risk vector
- **Persistent memory**: Stores context across sessions in SOUL.md and MEMORY.md files

### 1.2 Hardware & Environment Setup

**Option A: Dedicated Cloud VPS (Recommended for security)**
- Use a dedicated VPS (e.g., DigitalOcean, Hetzner, Contabo — 2vCPU, 8GB RAM, ~$5-10/month)
- This isolates OpenClaw from your personal devices entirely
- Run inside Docker for additional containment

**Option B: Local Machine (Convenient but higher risk)**
- Use a dedicated VM or container — never run directly on your main OS
- Microsoft explicitly recommends: "not appropriate to run on a standard personal or enterprise workstation"

**Option C: Dedicated Physical Device**
- Repurpose an old laptop or use a Raspberry Pi 5 (8GB)
- Air-gap from sensitive networks

### 1.3 Installation Steps

1. **Create a dedicated non-root user**:
   ```bash
   sudo adduser openclaw --disabled-password
   sudo su - openclaw
   ```

2. **Install via official script** (always verify the script first):
   ```bash
   # Download and review before piping to shell
   curl -fsSL https://get.openclaw.ai -o install.sh
   less install.sh  # REVIEW IT
   bash install.sh
   ```

3. **Run the onboarding wizard** — it generates a gateway token by default

4. **Immediately run security audit**:
   ```bash
   openclaw security audit --fix
   ```

### 1.4 Network Security Hardening

1. **Never expose the Gateway to the public internet directly**
   - Bind to loopback only: `OPENCLAW_GATEWAY_HOST=127.0.0.1`
   - For remote access, use SSH tunnel or Tailscale:
     ```bash
     ssh -L 18789:localhost:18789 user@your-vps
     ```

2. **Disable mDNS broadcasting**:
   ```bash
   export OPENCLAW_DISABLE_BONJOUR=1
   ```
   This prevents leaking filesystem paths and hostname info on your local network.

3. **Firewall rules**: Block port 18789 from all external access
   ```bash
   sudo ufw deny 18789
   ```

4. **Use a reverse proxy with TLS** if you must expose it (Caddy or nginx with Let's Encrypt)

### 1.5 Authentication & Credential Management

1. **Use strong gateway tokens** — the wizard generates one, but verify it's not weak
2. **Scoped API tokens**: For every integration (Gmail, GitHub, etc.), create tokens with minimum required permissions (read-only where possible)
3. **Short-lived credentials** over long-lived ones wherever possible
4. **Never store secrets in .env files the agent can read** — use a secrets manager or OS keychain
5. **Disable memory storage of secrets**: Ensure SOUL.md/MEMORY.md never contain API keys or passwords

### 1.6 Skill & Supply Chain Security

This is critical — as of Feb 2026, ~20% of ClawHub skills were found to be malicious (the "ClawHavoc" campaign: 824+ malicious skills out of 10,700+).

1. **Audit every skill before installing**: Read the SKILL.md and all associated code manually
2. **Only install skills from verified/trusted authors**
3. **Never install skills that request exec/shell access unless you've audited them thoroughly**
4. **Pin skill versions** — don't auto-update
5. **Run `openclaw security audit` after every skill install**
6. **Consider writing your own skills** for sensitive workflows rather than trusting third-party ones

### 1.7 LLM API Key Management

- Create a **dedicated API key** for OpenClaw (not your personal/main key)
- Set **spending limits** on the API key ($20-50/month to start)
- Monitor usage dashboards for anomalous spikes (could indicate prompt injection exfiltrating data)
- Rotate keys monthly

### 1.8 Ongoing Maintenance

- **Keep OpenClaw updated** — 60+ CVEs and 60+ GHSAs disclosed in ~4 months, including CVE-2026-28363 (CVSS 9.9) and CVE-2026-25253 (CVSS 8.8)
- Run `openclaw security audit --fix` regularly (weekly minimum)
- Monitor the OpenClaw GitHub security advisories
- Review SOUL.md/MEMORY.md periodically for injected content (memory poisoning attacks)
- Check logs for suspicious activity

---

## Part 2: Top 20 Use Cases with Risk Assessments

### Use Case 1: Email Triage & Morning Briefing
**What**: OpenClaw reads your inbox, summarizes emails by priority, and sends you a digest via Telegram/Signal each morning.
**Time saved**: 30-45 min/day
**Risk level**: HIGH
**Risks**:
- Your email contents (potentially containing sensitive/confidential info) are sent to an external LLM API
- Email credentials stored locally could be exfiltrated via prompt injection
- Malicious emails could contain prompt injection payloads that hijack the agent
**Mitigations**:
- Use a read-only email app password / OAuth token with minimal scopes
- Filter out emails from unknown senders before processing
- Use a dedicated email account for testing initially, not your primary inbox
- Consider a local LLM (Llama, Mistral) for this use case to keep data on-premise

### Use Case 2: Calendar Management & Scheduling
**What**: Auto-schedule meetings, detect conflicts, send scheduling links, and provide daily agenda briefings.
**Time saved**: 15-30 min/day
**Risk level**: MEDIUM
**Risks**:
- Calendar data reveals your location, contacts, and daily patterns
- Write access could delete or modify meetings (accidentally or via injection)
- Meeting details sent to LLM API
**Mitigations**:
- Start with read-only calendar access
- Require human confirmation for any write operations (creating/modifying/deleting events)
- Use scoped OAuth tokens

### Use Case 3: Code Review & PR Summaries
**What**: Automatically summarize PRs, flag potential issues, and post review comments on GitHub.
**Time saved**: 1-2 hrs/day for active developers
**Risk level**: MEDIUM
**Risks**:
- Source code (potentially proprietary) sent to external LLM
- Write access to GitHub could merge bad PRs or delete branches if agent is compromised
- Prompt injection via malicious PR descriptions or code comments
**Mitigations**:
- Use a GitHub token scoped to specific repos with minimal permissions
- Never grant merge/admin permissions to the agent's token
- Review agent-generated comments before they're posted (require approval)
- For proprietary code, use a local LLM or an LLM provider with a data processing agreement

### Use Case 4: Automated DevOps & Deployment
**What**: Run test suites, deploy to staging/production, monitor CI/CD pipelines via chat commands.
**Time saved**: 1-3 hrs/day
**Risk level**: VERY HIGH
**Risks**:
- Shell command execution on your infrastructure — this is the most dangerous capability
- A compromised agent could deploy malicious code, delete databases, or exfiltrate secrets
- Production credentials exposed to the agent
**Mitigations**:
- NEVER give the agent production deployment access directly
- Use a dedicated CI/CD service (GitHub Actions, etc.) as an intermediary — agent triggers, CI deploys
- Restrict exec permissions to a whitelist of safe commands
- Use staging-only access initially
- Require human approval for any deployment actions
- Run the agent in a container with no network access to production systems

### Use Case 5: Meeting Transcription & Action Items
**What**: Transcribe meeting recordings, extract action items, and email summaries to participants.
**Time saved**: 30-60 min/meeting
**Risk level**: HIGH
**Risks**:
- Meeting recordings contain sensitive business discussions
- Audio/transcription data sent to external APIs
- Action items could be mis-attributed or fabricated (hallucination)
- Participant email addresses exposed
**Mitigations**:
- Use local transcription (Whisper) before sending text to LLM
- Review action items before sending to participants
- Get consent from all meeting participants
- Consider legal/compliance requirements (some jurisdictions require consent for recording)

### Use Case 6: Social Media Content Generation & Scheduling
**What**: Generate platform-specific posts from blog content, schedule posts, and manage multiple accounts.
**Time saved**: 5-10 hrs/week
**Risk level**: MEDIUM
**Risks**:
- Agent could post inappropriate/incorrect content under your brand
- Social media credentials exposed
- Generated content could contain hallucinations or plagiarized text
- Write access means agent could delete posts or reply to people
**Mitigations**:
- Always require human approval before posting
- Use a content queue/draft system, not direct posting
- Use platform-specific API tokens with limited scopes (post-only, no DM access)
- Review all generated content for accuracy and brand alignment

### Use Case 7: Research & Web Monitoring
**What**: Monitor specific topics, competitors, or news sources and provide summarized briefings.
**Time saved**: 1-2 hrs/day
**Risk level**: LOW-MEDIUM
**Risks**:
- Web browsing exposes the agent to prompt injection via malicious web content
- Headless browser could be exploited to visit phishing sites
- Research summaries may contain hallucinations presented as facts
**Mitigations**:
- Run the browser in a sandboxed container (Chromium in Docker)
- Restrict browsing to a whitelist of trusted domains
- Cross-reference important findings manually
- Disable JavaScript execution for simple content scraping

### Use Case 8: Personal Finance Tracking
**What**: Aggregate bank transactions, categorize spending, generate budget reports.
**Time saved**: 2-3 hrs/week
**Risk level**: VERY HIGH
**Risks**:
- Financial data is extremely sensitive — bank credentials, transaction history, account numbers
- Data sent to external LLM API could be logged or breached
- Compromised agent could initiate transfers if write access is granted
- Regulatory implications (PCI-DSS, financial data protection laws)
**Mitigations**:
- Use read-only bank API access (Plaid with read-only scope)
- NEVER grant transfer/payment capabilities
- Use a local LLM for processing financial data — do not send to cloud APIs
- Export transactions as CSV and process offline rather than live API connections
- Encrypt all stored financial data at rest

### Use Case 9: Customer Support Triage
**What**: Monitor support channels (email, chat, social), categorize issues, draft responses, escalate urgent items.
**Time saved**: 3-5 hrs/day
**Risk level**: HIGH
**Risks**:
- Customer PII (names, emails, account details) sent to external LLM
- Incorrect auto-responses could damage customer relationships
- Prompt injection via customer messages could hijack the agent
- GDPR/CCPA compliance issues with processing customer data via third-party LLMs
**Mitigations**:
- Always require human approval for outgoing responses
- Strip PII before sending to LLM (use regex/NER pre-processing)
- Use an LLM provider with a DPA (Data Processing Agreement)
- Log all agent actions for audit trail
- Have a clear escalation path for edge cases

### Use Case 10: Document Drafting & Editing
**What**: Draft contracts, proposals, reports, and other documents from templates and context.
**Time saved**: 2-5 hrs/week
**Risk level**: MEDIUM
**Risks**:
- Confidential business information sent to LLM API
- Hallucinated legal/financial terms could have real consequences
- Document content stored in agent memory could leak across sessions
**Mitigations**:
- Never use for final legal documents without lawyer review
- Clear agent memory after processing sensitive documents
- Use document templates to constrain output
- Review all drafts thoroughly before use

### Use Case 11: Smart Home Automation
**What**: Control lights, thermostats, locks, cameras via natural language through messaging apps.
**Time saved**: Convenience (15-30 min/day)
**Risk level**: HIGH
**Risks**:
- Physical security implications — agent could unlock doors, disable security cameras
- Smart home credentials exposed to the agent
- Prompt injection could trigger physical actions (unlock doors, open garage)
- Camera feeds are extremely sensitive
**Mitigations**:
- Never connect door locks or security systems to OpenClaw
- Limit to non-critical devices (lights, thermostats, speakers)
- Require 2FA or physical confirmation for any security-related actions
- Use a separate smart home hub with its own auth layer

### Use Case 12: Expense Report Automation
**What**: Scan receipts, categorize expenses, fill out expense report forms, submit for approval.
**Time saved**: 2-3 hrs/week
**Risk level**: MEDIUM
**Risks**:
- Receipt images may contain personal credit card numbers
- Incorrect categorization could cause tax/compliance issues
- Corporate expense data sent to external LLM
**Mitigations**:
- Mask credit card numbers before processing
- Always require human review before submission
- Use local OCR (Tesseract) for receipt scanning, only send extracted text to LLM
- Maintain audit trail of all agent decisions

### Use Case 13: Automated Data Entry & Form Filling
**What**: Extract data from PDFs/emails and populate spreadsheets, CRMs, or databases.
**Time saved**: 3-5 hrs/week
**Risk level**: MEDIUM
**Risks**:
- Data accuracy — incorrect entries could propagate through systems
- Write access to databases/CRMs is a significant attack surface
- Source documents may contain sensitive data
**Mitigations**:
- Implement validation rules before any database writes
- Use staging/draft records that require human approval
- Log all changes with before/after values for rollback
- Start with low-stakes data entry (non-financial, non-medical)

### Use Case 14: Personal Knowledge Base / Second Brain
**What**: Automatically organize notes, bookmarks, highlights into a searchable knowledge base (Notion, Obsidian).
**Time saved**: 1-2 hrs/day
**Risk level**: LOW
**Risks**:
- Personal notes and thoughts sent to external LLM for processing
- Memory poisoning — malicious content could be injected into your knowledge base
- Over-reliance on AI-organized information could introduce bias
**Mitigations**:
- Use a local LLM for processing personal notes
- Periodically review the knowledge base for injected/suspicious content
- Keep original source material alongside AI summaries
- Use read-only access to source apps where possible

### Use Case 15: Competitive Intelligence
**What**: Monitor competitor websites, pricing, job postings, press releases, and social media activity.
**Time saved**: 3-5 hrs/week
**Risk level**: LOW-MEDIUM
**Risks**:
- Web scraping may violate terms of service of target websites
- Competitor websites could contain prompt injection targeting your agent
- Hallucinated competitive insights could lead to bad business decisions
- Legal risk if scraping crosses into unauthorized access territory
**Mitigations**:
- Only monitor publicly available information
- Verify critical intelligence manually before acting on it
- Use sandboxed browser with restricted JavaScript
- Consult legal counsel on scraping legality in your jurisdiction
- Label all AI-generated insights as unverified

### Use Case 16: Automated Reporting & Dashboards
**What**: Pull data from multiple sources (analytics, CRM, database), generate weekly/monthly reports.
**Time saved**: 3-5 hrs/week
**Risk level**: MEDIUM
**Risks**:
- Business metrics and KPIs sent to external LLM
- Incorrect data aggregation could lead to bad decisions
- API credentials for multiple services exposed
**Mitigations**:
- Use read-only database replicas or API tokens
- Validate generated reports against known benchmarks
- Use pre-built SQL queries/templates rather than letting the agent write arbitrary queries
- Review reports before distribution

### Use Case 17: Language Translation & Localization
**What**: Translate documents, emails, and content between languages with context awareness.
**Time saved**: 2-4 hrs/week
**Risk level**: LOW
**Risks**:
- Confidential documents sent to external LLM for translation
- Mistranslations in legal/medical/technical contexts could have serious consequences
- Cultural nuances may be missed
**Mitigations**:
- Have native speakers review critical translations
- Use domain-specific glossaries to improve accuracy
- Never use for legally binding translations without professional review
- Test with non-sensitive content first

### Use Case 18: Automated Testing & QA
**What**: Generate test cases, run test suites, report bugs, and track regression.
**Time saved**: 2-4 hrs/day for QA teams
**Risk level**: MEDIUM
**Risks**:
- Source code and test data sent to external LLM
- Shell command execution for running tests
- Generated tests may have false positives/negatives, creating false confidence
- Test environments may contain real customer data
**Mitigations**:
- Use sanitized test data only
- Restrict exec permissions to test commands only
- Review generated test cases before adding to test suite
- Run in an isolated CI environment, not on development machines

### Use Case 19: Invoice Processing & Accounts Payable
**What**: Extract data from incoming invoices, match to POs, route for approval, update accounting system.
**Time saved**: 5-10 hrs/week
**Risk level**: HIGH
**Risks**:
- Financial documents contain sensitive vendor and company information
- Incorrect processing could result in wrong payments
- Fraudulent invoices could bypass detection if agent is compromised
- Write access to accounting systems is extremely sensitive
**Mitigations**:
- Always require human approval for any payment-related actions
- Implement multi-person approval for amounts above a threshold
- Use local processing for OCR/extraction, minimize data sent to cloud LLM
- Cross-reference invoices against PO database automatically
- Maintain complete audit trail

### Use Case 20: Personal Health & Fitness Tracking
**What**: Aggregate health data from wearables, track habits, generate wellness reports, suggest improvements.
**Time saved**: 30-60 min/day
**Risk level**: HIGH
**Risks**:
- Health data is among the most sensitive categories (HIPAA in US, special category under GDPR)
- Incorrect health advice could be harmful
- Wearable API data includes location, heart rate, sleep patterns
- Health data sent to external LLM could be used for insurance discrimination
**Mitigations**:
- Use a local LLM exclusively — never send health data to cloud APIs
- Never act on AI health suggestions without consulting a healthcare professional
- Use read-only access to health platforms
- Anonymize/aggregate data before processing
- Understand the legal framework for health data in your jurisdiction

---

## Part 3: Risk Summary Matrix

| Risk Level | Use Cases |
|-----------|-----------|
| **VERY HIGH** | #4 DevOps/Deployment, #8 Personal Finance |
| **HIGH** | #1 Email, #5 Meeting Transcription, #9 Customer Support, #11 Smart Home, #19 Invoice Processing, #20 Health Tracking |
| **MEDIUM** | #2 Calendar, #3 Code Review, #6 Social Media, #10 Document Drafting, #12 Expense Reports, #13 Data Entry, #16 Reporting, #18 Automated Testing |
| **LOW-MEDIUM** | #7 Research/Monitoring, #15 Competitive Intel |
| **LOW** | #14 Knowledge Base, #17 Translation |

---

## Part 4: Universal Security Principles

1. **Start small**: Begin with low-risk use cases (#14, #17, #7) and build confidence
2. **Principle of least privilege**: Every integration gets the minimum permissions needed
3. **Human in the loop**: Require approval for all write/send/deploy actions initially
4. **Defense in depth**: Container + firewall + auth + scoped tokens + monitoring
5. **Assume compromise**: Design your setup so that even if the agent is hijacked, the blast radius is limited
6. **Local LLMs for sensitive data**: Use Ollama + Llama/Mistral for processing financial, health, or confidential data
7. **Regular audits**: Run `openclaw security audit` weekly, review memory files monthly
8. **Stay updated**: OpenClaw has had 60+ CVEs and 60+ GHSAs in its first 4 months (including a CVSS 9.9) — always run the latest version
9. **Vet all skills**: Never install unaudited third-party skills (~20% of ClawHub skills were malicious)
10. **Monitor costs**: Set API spending limits to detect exfiltration-via-API-abuse early

---

## Part 5: Verification

After setup, verify security by:
1. Running `openclaw security audit --fix` and confirming zero findings
2. Port scanning your host to confirm 18789 is not externally accessible
3. Testing that the gateway rejects unauthenticated WebSocket connections
4. Verifying API key spending limits are set
5. Confirming mDNS is disabled (`OPENCLAW_DISABLE_BONJOUR=1`)
6. Testing a benign prompt injection to see if the agent's guardrails hold
7. Reviewing SOUL.md and MEMORY.md for any unexpected content
8. Verify `allow_url_actions: false` in `openclaw.yaml` to block the one-click RCE vector
9. Confirm you're running version 2026.3.12+ (patches all known CVEs)
10. Test that WebSocket connections from non-localhost origins are rejected
11. Verify Docker container runs as non-root with `--cap-drop=ALL` and `--read-only`

---

## Part 6: Pentester / Whitehat Review of Recommendations

### Upgraded Risk Assessments

Based on the full CVE landscape and real-world attack data, these use case risk levels should be upgraded:

| Use Case | Original Rating | Pentester Rating | Justification |
|---|---|---|---|
| #3 Code Review | MEDIUM | **HIGH** | Prompt injection via PR descriptions is a proven attack vector; source code exfiltration is high-value |
| #7 Research/Monitoring | LOW-MEDIUM | **MEDIUM-HIGH** | Web browsing is the #1 indirect prompt injection vector; malicious sites can hijack the agent |
| #14 Knowledge Base | LOW | **MEDIUM** | Memory poisoning (SOUL.md/MEMORY.md rewrite) makes this a persistence vector for attackers |

### Critical Attack Vectors Missing from Original Guide

**1. The "Lethal Trifecta" (Penligent/OctoClaw research)**
The combination of System Access + Execution Power + Untrusted Ingestion creates a perfect storm. Most OpenClaw setups have all three by default. The guide should emphasize: **never combine all three in a single agent instance**. Use separate agents with different permission levels.

**2. Time-Shifted Memory Poisoning (Palo Alto Networks)**
Malicious inputs written to SOUL.md/MEMORY.md can appear benign at ingestion but "detonate" later when the agent's state aligns — logic bomb-style. Palo Alto mapped OpenClaw to **every category in the OWASP Top 10 for Agentic Applications**.

Mitigation: Treat memory files as code, not data. Use file integrity monitoring (FIM), enforce read-only permissions during runtime, require admin approval for memory file changes.

**3. Log Poisoning → Indirect Prompt Injection**
Attackers can write malicious content to log files via WebSocket requests. Since the agent reads its own logs, this is an injection vector. Mitigation: Ensure logs are write-only from the agent's perspective; use a separate log viewer.

**4. Container Escape via API**
CVE-2026-25253's WebSocket hijacking works even inside Docker containers — the container boundary doesn't block it. A containerized install running a vulnerable image is just as exposed as bare-metal.

**5. Localhost Trust Assumption (ClawJacked)**
OpenClaw's gateway exempted localhost from rate limiting entirely. Browser JavaScript could brute-force the gateway at hundreds of guesses/second with no lockout and no logging. This assumption that "localhost = trusted" was fundamentally flawed.

### Docker Hardening Deep Dive (Missing from Original)

Add to Section 1.2 for anyone running Docker:

```yaml
# docker-compose.yml — hardened OpenClaw deployment
version: '3.8'
services:
  openclaw:
    image: openclaw/openclaw:2026.3.12  # Pin to patched version
    read_only: true                      # Read-only root filesystem
    cap_drop:
      - ALL                              # Drop all Linux capabilities
    security_opt:
      - no-new-privileges:true           # Prevent privilege escalation
      - seccomp=openclaw-seccomp.json    # Custom seccomp profile
    user: "1000:1000"                    # Non-root user
    ports:
      - "127.0.0.1:18789:18789"         # Bind to loopback ONLY
    volumes:
      - ./config:/app/config:ro          # Config read-only
      - ./data:/app/data                 # Data writable (minimal)
    mem_limit: 2g                        # Memory cap
    cpus: 1.0                            # CPU cap
    networks:
      - openclaw-internal

  # Optional: egress proxy to restrict outbound traffic
  egress-proxy:
    image: nginx:alpine
    # Allowlist only LLM API endpoints
    networks:
      - openclaw-internal
      - external

networks:
  openclaw-internal:
    internal: true   # No direct internet access for OpenClaw
  external:
    driver: bridge
```

Key additions:
- `internal: true` network prevents the agent from reaching the internet directly — all traffic must go through an egress proxy with an allowlist of permitted API endpoints
- Even a fully compromised agent cannot exfiltrate data to arbitrary servers
- Never mount `docker.sock` — it grants container escape
- Never use `--network=host` — it removes network isolation entirely

### Incident Response Plan (Missing from Original)

If you suspect compromise:
1. **Immediately**: Disconnect OpenClaw from the network (stop container or kill process)
2. **Within 1 hour**: Rotate ALL credentials the agent had access to (API keys, OAuth tokens, service passwords)
3. **Audit**: Check logs for unexpected `system.run` calls; review `sandbox list` state
4. **Review**: Examine SOUL.md/MEMORY.md for injected instructions
5. **Scan**: Check for installed backdoor skills or modified skill files
6. **Report**: If you find evidence of exploitation, report to OpenClaw security (GitHub Security Advisories)

### Pentester Mitigation Ratings by Use Case

| Use Case | Mitigations Rating | Key Gap |
|---|---|---|
| #1 Email | NEEDS IMPROVEMENT | Add: never open attachments via agent; email is the #1 prompt injection delivery vector |
| #2 Calendar | SUFFICIENT | — |
| #3 Code Review | NEEDS IMPROVEMENT | Add: sanitize PR descriptions before LLM processing; use separate browser profile |
| #4 DevOps | SUFFICIENT | Already rated VERY HIGH with strong mitigations |
| #5 Meeting Transcription | SUFFICIENT | — |
| #6 Social Media | SUFFICIENT | — |
| #7 Research | NEEDS IMPROVEMENT | Add: never browse in same browser session as OpenClaw Control UI; use separate profile |
| #8 Finance | SUFFICIENT | Already rated VERY HIGH with strong mitigations |
| #9 Customer Support | NEEDS IMPROVEMENT | Add: rate-limit outgoing responses; implement canary tokens in customer data |
| #10 Document Drafting | SUFFICIENT | — |
| #11 Smart Home | NEEDS IMPROVEMENT | Should be VERY HIGH; physical security implications are severe |
| #12 Expense Reports | SUFFICIENT | — |
| #13 Data Entry | SUFFICIENT | — |
| #14 Knowledge Base | NEEDS IMPROVEMENT | Add: file integrity monitoring on knowledge base; memory poisoning is a real vector |
| #15 Competitive Intel | SUFFICIENT | — |
| #16 Reporting | SUFFICIENT | — |
| #17 Translation | SUFFICIENT | — |
| #18 Testing | SUFFICIENT | — |
| #19 Invoices | NEEDS IMPROVEMENT | Add: implement anomaly detection on invoice amounts; attackers target AP workflows |
| #20 Health | SUFFICIENT | Already emphasizes local LLM only |

### Real-World Scale of the Problem

As of March 2026:
- **220,000+** OpenClaw instances exposed to the internet
- **12,812** confirmed exploitable via RCE
- **63%** of observed deployments were vulnerable
- **60+ CVEs and 60+ GHSAs** disclosed in ~4 months
- **900+** malicious ClawHub skills identified (Atomic Stealer malware payloads)
- **Meta** has banned OpenClaw from corporate devices
- **China** restricted OpenClaw in government agencies
- **Palo Alto Networks** called it "the potential biggest insider threat of 2026"

---

## Part 7: OpenClaw vs Claude Code — When to Use Which

### What is Claude Code?

Claude Code is Anthropic's official CLI and agentic coding tool. It runs in your terminal, IDE (VS Code, JetBrains), and now as a desktop app (Cowork). Unlike OpenClaw's messaging-app-first approach, Claude Code is purpose-built for software development with deep filesystem and git integration.

### New in 2026: Channels & Cowork

**Claude Code Channels** (launched March 20, 2026): Bridges messaging platforms (Telegram, Discord, Slack) to your Claude Code CLI session using MCP plugins. You message Claude through a chat app, it does work on your machine, and replies in the same conversation. A webhook from your monitoring system can trigger Claude Code to investigate and patch issues autonomously. This directly competes with OpenClaw's core messaging-app integration model.

**Claude Cowork** (launched 2026): The desktop agent version of Claude Code for knowledge workers. Uses the same agentic architecture as Claude Code but with a desktop interface instead of terminal. Reads/writes your actual files, executes multi-step tasks autonomously, and delivers finished work. Powered by the same Claude Agent SDK.

**Agent Teams** (experimental): Coordinates multiple Claude Code instances working together. One session acts as team lead, assigning tasks and synthesizing results. Unlike subagents (which run within a single session), team members can communicate with each other, share discoveries mid-task, and coordinate without the main agent as intermediary. Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.

### Head-to-Head Comparison

| Dimension | Claude Code | OpenClaw |
|---|---|---|
| **Primary interface** | Terminal CLI + IDE + Desktop (Cowork) | Messaging apps (Signal, Telegram, WhatsApp, Discord) |
| **Messaging integration** | Channels (Telegram, Discord, Slack) — new in March 2026 | Native, core architecture — all major platforms |
| **Security model** | Sandboxed; explicit per-action permission approval | Broad default permissions; you configure restrictions |
| **Permission granularity** | Every tool call requires approval unless allow-listed | Gateway token + skill-level permissions |
| **Enterprise compliance** | SOC 2, GDPR, SSO, RBAC, audit trails | None — no dedicated security team, no bug bounty |
| **CVEs (first 4 months)** | Managed by Anthropic security team | 60+ CVEs, 60+ GHSAs, CVSS 8.8 critical RCE |
| **LLM flexibility** | Claude models only (Opus, Sonnet, Haiku) | Any LLM — Claude, GPT, DeepSeek, Llama, Mistral, etc. |
| **Cost** | ~$20/month (Max plan) or API usage-based | Free (MIT license) + LLM API costs ($6-200+/month) |
| **Multi-agent** | Agent Teams (experimental) — coordinated instances | Single agent with multiple skill integrations |
| **Coding depth** | Purpose-built — deep codebase understanding, git-native | General-purpose — coding is one of many capabilities |
| **Non-coding tasks** | Cowork handles knowledge work; Channels for ops | Native strength — email, calendar, smart home, finance, etc. |
| **Customization** | CLAUDE.md project files, hooks, MCP servers | SKILL.md skills, SOUL.md personality, full source access |
| **Self-hosting** | No — Anthropic-hosted API | Yes — runs entirely on your hardware |
| **Data sovereignty** | Data goes to Anthropic's API | You choose: cloud LLM API or local models |
| **Supply chain risk** | MCP servers (smaller ecosystem, less attack surface) | ClawHub skills (~20% malicious as of Feb 2026) |

### When to Use Claude Code

- **Software development**: Code review, refactoring, debugging, architecture — Claude Code is purpose-built for this
- **Enterprise/regulated environments**: SOC 2, GDPR compliance, audit trails, SSO/RBAC
- **Security-conscious teams**: Sandboxed execution, explicit permissions, managed by Anthropic's security team
- **Git-heavy workflows**: Native git integration, PR management, commit workflows
- **When you want managed security**: You don't want to be responsible for patching CVEs and hardening infrastructure

### When to Use OpenClaw

- **Life automation beyond coding**: Email, calendar, smart home, finance, health — OpenClaw's breadth is unmatched
- **Messaging-native workflows**: If your team lives in Telegram/Signal/WhatsApp, OpenClaw is native there
- **LLM flexibility**: Need to use local models, DeepSeek, or mix providers? OpenClaw supports anything
- **Full data sovereignty**: Run entirely on your hardware with local LLMs — nothing leaves your network
- **Cost-sensitive teams**: Free software + cheap VPS vs. per-seat SaaS pricing
- **Maximum customization**: Full source access, custom skills, custom personality via SOUL.md

### The Emerging Pattern: Use Both

Many developers are running Claude Code as their coding engine and OpenClaw as their life/ops orchestration layer. With Claude Code Channels now supporting Telegram and Discord, the overlap is growing — but OpenClaw's breadth of non-coding integrations (50+ services) still gives it a unique position.

**Key architectural difference**: Claude Code Channels gives you messaging-app access to a *coding agent*. OpenClaw gives you messaging-app access to a *general-purpose agent with system-level access*. The security implications of that distinction are enormous.

---

## Part 8: Steinberger's Perspective (Creator's View)

*This section is based on Peter Steinberger's documented public statements — his blog at steipete.me (Feb 15, 2026), the Pragmatic Engineer podcast ("I ship code I don't read," Jan 28, 2026), Lex Fridman Podcast #491, Fortune/TechCrunch/CNBC interviews, and his GitHub activity.*

### His Philosophy: Empowerment, Not Containment

Steinberger positions OpenClaw as "an AI that actually does things" — a revolutionary tool for power users. His vision is building "an agent that even my mum can use." He frames AI agents as a new skill: *"You pick up the guitar — you're not going to be good at the guitar in the first day."* He calls this approach **"agentic engineering"** and explicitly distinguishes it from "vibe coding."

### Where Steinberger Would Push Back on This Guide

1. **The tone is too CISO-like**: This guide reads like a risk assessment. Steinberger would lead with the empowerment narrative ("own your data, own your agent") before the risk narrative. He'd want users excited about the possibilities, then educated on safety.

2. **Absolutist "NEVER" prohibitions**: Steinberger's philosophy favors graduated trust models over blanket bans. Instead of "NEVER connect door locks," he'd say "start read-only, level up as you validate." The whole pitch is that OpenClaw *does things* — telling users it can never do anything risky defeats the purpose.

3. **The Microsoft quote**: The guide presents "not appropriate to run on a standard personal or enterprise workstation" without noting this is Microsoft's external security team's view, not a universal consensus. Steinberger's entire pitch is that OpenClaw runs on YOUR machine.

4. **Model interchangeability**: The guide underplays a core architectural principle — Steinberger designed LLMs as swappable inference endpoints. This is central to data sovereignty: you can route sensitive tasks to local models and mundane tasks to cloud APIs on the same agent.

### Where Steinberger Acknowledges the Risks

- He announced moving OpenClaw to an **independent open-source foundation** (Apache/PSF model) on Feb 14, 2026, acknowledging that community governance is needed for security at scale.
- He's been active in GitHub Security Advisory work, though he's also publicly criticized GitHub's vulnerability reporting system as "a mess" drowning in "AI-generated slop."

### Uncomfortable Truths the Guide Should Include

1. **ClawHavoc response was slow**: Steinberger was criticized for saying he was "too busy" to address malicious skills in ClawHub. C2 infrastructure from the campaign stayed operational for days before takedown. This is important context for anyone relying on ClawHub.

2. **Community as security asset**: The guide undervalues this. ClawCon drew 1,000+ attendees; Cisco's DefenseClaw tool and VirusTotal scanning integration came from community contributions. The security story isn't just "OpenClaw is dangerous" — the community is actively building defenses.

3. **One maintainer's candid warning** (from Discord): *"If you can't understand how to run a command line, this is far too dangerous of a project for you to use safely."* This is honest and should be front-and-center.

### The Balanced Take

Steinberger is more optimistic about OpenClaw's risk-reward tradeoff than the security community. This guide deliberately errs on the side of security researchers (Microsoft, Palo Alto Networks, Cisco) rather than the creator's more permissive view. **That's the right call for a security-focused setup guide.** But users should know that Steinberger's graduated-trust approach ("start minimal, expand carefully") is valid for experienced users who understand the risks they're accepting.

Sources:
- [OpenClaw, OpenAI and the future | steipete.me](https://steipete.me/posts/2026/openclaw)
- [The creator of Clawd: "I ship code I don't read" | Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/the-creator-of-clawd-i-ship-code)
- [OpenClaw creator Peter Steinberger joins OpenAI | TechCrunch](https://techcrunch.com/2026/02/15/openclaw-creator-peter-steinberger-joins-openai/)
- [Who is OpenClaw creator Peter Steinberger? | Fortune](https://fortune.com/2026/02/19/openclaw-who-is-peter-steinberger-openai-sam-altman-anthropic-moltbook/)
- [ClawHavoc Poisons OpenClaw's ClawHub | CyberPress](https://cyberpress.org/clawhavoc-poisons-openclaws-clawhub-with-1184-malicious-skills/)
- [OpenClaw founder rips into GitHub's security reporting | Cryptopolitan](https://www.cryptopolitan.com/openclaw-founder-rips-github-mess/)
- [OpenClaw: Peter Steinberger on Lex Fridman #491 | Summify](https://summify.io/discover/openclaw-the-viral-ai-agent-that-broke-the-internet-peter-st-YFjfBk/)
