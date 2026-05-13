---
name: agent-harness-v2
description: Create or validate the agent harness for the current project. Detects project type, generates docs/project-rules/agent-harness.md (legacy name harness.md still supported on read), and verifies Boot/Interact/Observe capabilities.
---
# agent-harness-v2

Create or validate the **agent harness** — the automated Boot → Interact → Observe → Validate feedback loop that lets an agent iterate on running software in 30-60 second cycles.

**Agent harness governance**: `docs/project-rules/agent-harness.md` (new projects). Legacy name `docs/project-rules/harness.md` is still read as a fallback for projects that haven't migrated yet — see Step 0 for the read order and Step 6 for the migration advisory.

**Layering**: the agent harness sits **on top of** the engineering harness (the project's `justfile`/`Makefile`/`package.json scripts.dev` boot command, test runner, etc.). The Boot command this skill records IS the engineering harness substrate. If no engineering harness exists, raise that as a finding before attempting to build the agent harness — Boot can't work without something to boot.

**Agent harness dossier**: Three capabilities (Boot, Interact, Observe), maturity model (L0–L4), 7 design principles.

---

## Input

```
$ARGUMENTS
# Flags:
# --create     Force CREATE mode (even if agent-harness.md exists)
# --validate   Force VALIDATE mode
# --status     Quick maturity report (no changes)
# (no flags)   Auto-detect: CREATE if missing, VALIDATE if exists
```

---

## Execution Flow

### Step 0: Mode Detection

```
Check governance file (read order: new path first, legacy fallback):
  1. docs/project-rules/agent-harness.md  ← new canonical path
  2. docs/project-rules/harness.md        ← legacy fallback (pre-rename)

If found at legacy path: log a one-line migration advisory in this skill's
output ("📁 Legacy filename detected — consider `git mv harness.md
agent-harness.md`") but do NOT modify the file. Continue normally.

Mode resolution:
  ├── EXISTS + no --create flag  → VALIDATE mode
  ├── MISSING + no --validate flag → CREATE mode
  ├── --create                 → CREATE mode (writes to agent-harness.md)
  ├── --validate               → VALIDATE mode (error if missing at both paths)
  └── --status                 → STATUS mode (read-only report)
```

---

### CREATE Mode

#### Step 1: Parallel Discovery (2 subagents)

Launch 2 subagents in parallel:

**Subagent 1: Project Type Detection**
Scan the codebase for signature files and classify:

| Signature Files | Project Type |
|----------------|-------------|
| `package.json` + (`next.config.*` \| `vite.config.*` \| `nuxt.config.*` \| `angular.json`) | `web-app` |
| Executable entry + no server config, CLI framework, `bin/` | `cli` |
| MCP tool exports, stdio/HTTP transport config | `mcp-server` |
| Server framework (express, fastapi, gin) without frontend | `api` |
| `app.json` (Expo) \| `.xcodeproj` \| `build.gradle` \| Electron | `mobile` |
| `terraform/` \| `pulumi/` \| `cloudformation/` \| `bicep/` | `iac` |

Output: `{ type: string, confidence: 0-1, signature_files: string[] }`

**Subagent 2: Interaction Surface Probe**
Search for existing engineering-harness infrastructure that the agent harness will sit on top of:
- Health endpoints (grep: `/health`, `/api/health`, `healthcheck`)
- Boot scripts (`justfile`, `Makefile`, `docker-compose.yml`, `scripts/`)
- Engineering test harnesses (`playwright.config`, `cypress.config`, etc.) — these are evidence the project already has a runnable substrate.
- Existing `AGENT_BOOTSTRAP.md` or similar quick-start docs
- Auth configuration (`.env`, token files, profile directories)

Output: `{ boot_candidates: string[], health_urls: string[], existing_bootstrap: string|null, auth_hints: string[] }`

**If `boot_candidates` is empty**: the engineering harness substrate is missing or undiscoverable. Raise as a finding in Step 2 before proceeding — agent harness creation needs at least one runnable boot command.

#### Step 2: Present & Confirm

Present discovery results to user via `ask_user`:

```
🔍 Project Analysis:

  Type:        [detected type] ([framework])    confidence: [0-1]
  Boot:        [candidate command]               from: [source]
  Health:      [URL or "none detected"]          from: [source]
  Auth:        [strategy or "none detected"]
  Evidence:    [available tools]                 from: [source]

  Is this correct?
```

Choices: "Yes" / "Adjust type" / "Adjust details"

If user adjusts → ask follow-up questions for corrections.

#### Step 3: Gather Remaining Details

Only ask what couldn't be auto-detected. Skip questions where detection has high confidence.

Possible questions (ask only if needed):
- Q: What port does the server listen on?
- Q: How does auth work? (No auth / Persistent profile / API key / Token file)
- Q: Primary interaction method? (HTTP API / Browser automation / Terminal / Both)
- Q: Where should evidence files go? (default: `./scratch/evidence/`)

#### Step 4: Generate agent-harness.md

Write to `docs/project-rules/agent-harness.md` (new canonical path) using this governance format. If a legacy `docs/project-rules/harness.md` exists, do NOT overwrite or migrate it automatically — write the new file alongside and emit the migration advisory in Step 6 so the user can choose when to `git mv` and remove the legacy.

```markdown
# Agent Harness

**Version**: 1.0.0
**Created**: [TODAY]
**Maturity Level**: [assessed level]
**Project Type**: [detected type]

## Purpose
[1-2 sentences: what this harness enables for agents in this project]

## Boot
- **Command**: [single boot command]
- **Health Check**: [health check command, e.g. curl -sf http://localhost:PORT/health]
- **Expected Response**: [what healthy looks like, e.g. {"ok":true}]
- **Boot Time**: ~[N]s (target: 30-60s)
- **Idempotent**: [Yes/No] — [how: check health before spawning / kill stale]

## Interact
- **Primary**: [HTTP API | Terminal stdin | Browser automation | JSON-RPC]
- **Endpoints / Commands**:
  - [primary interaction example]
  - [secondary if applicable]
- **Auth Strategy**: [Persistent profile | API key | Token file | None]
- **Auth Expiry**: [~24h | N/A | Token refresh mechanism]
- **Auth Detection**: [How agent detects expired auth, e.g. 401 response]

## Observe
- **Response capture**: [HTTP JSON | stdout | DOM snapshots]
- **Screenshots**: [Playwright | Puppeteer | N/A]
- **Logs**: [log file path or command]
- **Evidence directory**: [path, default ./scratch/evidence/]

## Maturity Assessment
| Level | Status | Notes |
|-------|--------|-------|
| L0: No harness | | Agent writes code, human tests |
| L1: Manual boot + API | | Human starts stack, agent sends requests |
| L2: Auto boot + API | | Agent starts stack, health check, API interaction |
| L3: Full interaction + evidence | | Agent boots, drives UI/CLI, captures screenshots |
| L4: Self-healing | | Auto-recovery from stale processes, auth expiry |

Current: **L[N]** — [brief justification]

## Validation Checklist
### Boot
- [ ] Single command starts full stack
- [ ] Health check endpoint/command exists and returns expected response
- [ ] Boot is idempotent (safe to run twice)
- [ ] Handles port conflicts (kill stale or fail fast)
- [ ] Clean shutdown on SIGTERM/SIGINT

### Interact
- [ ] Agent can send input (HTTP/stdin/keystrokes)
- [ ] Agent can trigger all user-facing actions
- [ ] Auth is automated (persistent profile, token file, API key)
- [ ] Auth expiry is detected with clear error message

### Observe
- [ ] Agent can read output (responses, stdout, DOM)
- [ ] Evidence capture works (screenshots, logs, response files)
- [ ] Structured output available (JSON, not just visual)

### Operate
- [ ] Bootstrap doc explains harness to new agents
- [ ] Example validation script exists (copy-paste ready)
- [ ] Named commands exist (justfile, Makefile, or scripts/)

## History
| Date | Plan | Change | Maturity Before → After |
|------|------|--------|------------------------|

<!-- USER CONTENT START -->
<!-- Project-specific harness notes, custom boot sequences, domain-specific setup -->
<!-- USER CONTENT END -->
```

Mark the current maturity level based on what's actually working (not aspirational).

#### Step 5: Validate (post-create)

After generating agent-harness.md, run the VALIDATE flow (below) to confirm it works. Report results.

#### Step 6: Report

```
✅ Agent harness created:

  Governance:   docs/project-rules/agent-harness.md
  Type:         [type] ([framework])
  Maturity:     L[N] ([description])
  Checklist:    [X/15] items verified

  Next steps:
  - Review agent-harness.md and adjust as needed
  - Run /agent-harness-v2 --validate after changes
  - Pipeline commands (plan-1a, plan-5, plan-6) will auto-discover this file
```

If a legacy `docs/project-rules/harness.md` was found during Step 0, append:

```
  📁 Legacy filename detected: docs/project-rules/harness.md still present.
     Consider migrating: git mv docs/project-rules/harness.md docs/project-rules/agent-harness.md
     (Old file is still read as fallback; this advisory is informational, not blocking.)
```

---

### VALIDATE Mode

#### Step 1: Read Agent Harness Config

Read `docs/project-rules/agent-harness.md` (or fall back to legacy `docs/project-rules/harness.md` and emit the migration advisory). Parse: boot command, health check, interaction method, observe method, current maturity level.

If both paths are missing or unparseable → error with suggestion to run `/agent-harness-v2 --create`.

#### Step 2: Execute 3-Stage Validation

Run checks using bash tool:

**Stage 1: Boot Check** (5s if running, 60s cold boot)
```
1. Check if already running: run health check command from agent-harness.md
   ├── Healthy → "Already running" (skip boot)
   └── Not responding → Run boot command, retry health check (30 × 2s = 60s max)
```

**Stage 2: Interact Check** (5s, single attempt)
```
1. Send test input per agent-harness.md § Interact
   ├── Response received → ✅
   └── No response / error → ❌ (log specific error)
```

**Stage 3: Observe Check** (5s, single attempt)
```
1. Capture evidence per agent-harness.md § Observe
   ├── Evidence non-empty and readable → ✅
   └── Empty or failed → ❌
```

#### Step 3: Classify Verdict

| Verdict | Criteria |
|---------|----------|
| **✅ HEALTHY** | All 3 checks pass, boot ≤ 45s |
| **⚠️ SLOW** | All 3 checks pass, boot > 45s |
| **❌ UNHEALTHY** | Any check fails |
| **🔴 UNAVAILABLE** | No agent-harness.md (or legacy harness.md) and no boot command |

#### Step 4: Update Maturity & Report

Update agent-harness.md `## Maturity Assessment` to reflect current reality.
Update `**Maturity Level**` header field.
Append validation result to `## History` table.

Report:
```
🔍 Agent Harness Validation Report:

  Boot:      [✅/❌] [detail] ([duration])
  Interact:  [✅/❌] [detail] ([duration])
  Observe:   [✅/❌] [detail] ([duration])

  Verdict:   [verdict]
  Maturity:  L[N] ([description])
  Checklist: [X/15] items passing
  Missing:   [list unchecked items]
```

---

### STATUS Mode

Quick read-only report — no validation, no changes.

Read agent-harness.md (or legacy harness.md, with migration advisory) and report: project type, maturity level, last validation date, checklist completion. No agent harness boots or health checks.

---

## Anti-Patterns (from agent harness dossier)

When generating agent-harness.md, warn against:
- **"Tests Are Enough"** — unit tests (engineering harness signal) pass while the running app the agent harness exercises is broken. These are different signals; you need both.
- **"The Agent Can Figure It Out"** — agents need explicit Boot/Interact/Observe instructions
- **"We'll Add the Agent Harness Later"** — agent harness first (after engineering harness exists), features second
- **"Screenshot Everything"** — prefer structured output over screenshots
- **"One Process Per Terminal"** — single entry point, single shutdown handler
