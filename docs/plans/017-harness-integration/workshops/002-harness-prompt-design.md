# Workshop: Harness Prompt Design

**Type**: CLI Flow  
**Plan**: 017-harness-integration  
**Spec**: [harness-integration-spec.md](../harness-integration-spec.md)  
**Created**: 2026-03-06  
**Status**: Draft

**Related Documents**:
- [001-agent-harness-dossier.md](./001-agent-harness-dossier.md) — First-principles harness concept
- [003-pre-phase-validation-protocol.md](./003-pre-phase-validation-protocol.md) — How plan-6 validates harness health

---

## Purpose

Design the `harness-v2.md` utility prompt — a dual-mode command that either **creates** a new `docs/project-rules/harness.md` or **validates** an existing one. This workshop specifies the detection logic, user interaction flow, output format, and bootstrap script generation.

## Key Questions Addressed

- How does project type detection work?
- What's the minimal viable harness.md?
- How does validate mode run health checks from a markdown prompt?
- What's the complete UX flow?
- Should it also generate a skeleton bootstrap script?

---

## Command Summary

| Command | Purpose |
|---------|---------|
| `/harness-v2` | Auto-detect mode (create or validate) |
| `/harness-v2 --create` | Force create mode |
| `/harness-v2 --validate` | Force validate mode |
| `/harness-v2 --status` | Quick maturity report |

---

## Mode Detection

```
┌─────────────────────────────────────────────────┐
│ Step 0: Check docs/project-rules/harness.md     │
│                                                  │
│   EXISTS?                                        │
│   ├── YES → VALIDATE mode                        │
│   └── NO  → CREATE mode                         │
│                                                  │
│   Override: --create forces CREATE even if exists │
│   Override: --validate forces VALIDATE            │
└─────────────────────────────────────────────────┘
```

---

## CREATE Mode

### Step 1: Project Type Detection

Scan the codebase for signature files to classify the project:

| Pattern | Signature Files | Project Type |
|---------|----------------|-------------|
| **Web Application** | `package.json` + (`next.config.*` \| `vite.config.*` \| `nuxt.config.*` \| `angular.json`) | `web-app` |
| **CLI / Terminal** | Executable entry point, no server config, `bin/` or CLI framework | `cli` |
| **MCP Server** | MCP tool exports, `"type": "module"`, stdio/HTTP transport | `mcp-server` |
| **API / Backend** | Server framework (`express`, `fastapi`, `gin`) without frontend | `api` |
| **Mobile / Desktop** | `app.json` (Expo) \| `.xcodeproj` \| `build.gradle` \| `electron` | `mobile` |
| **Infrastructure** | `terraform/` \| `pulumi/` \| `cloudformation/` \| `bicep/` | `iac` |

**Detection is 2 parallel subagents**:

```
Subagent 1: File Scanner
  - glob for signature files
  - Read package.json dependencies
  - Check for Dockerfile, justfile, Makefile
  - Output: { type_candidates: [...], confidence: 0-1, files_found: [...] }

Subagent 2: Interaction Surface Probe
  - Search for health endpoints (grep: /health, /api/health, healthcheck)
  - Search for existing boot scripts (justfile, Makefile, scripts/)
  - Search for test harnesses (playwright.config, cypress.config, harness.*)
  - Search for existing AGENT_BOOTSTRAP.md or similar
  - Output: { boot_candidates: [...], health_urls: [...], existing_harness: null|path }
```

### Step 2: Present & Confirm

```
$ /harness-v2

🔍 Project Analysis:

  Detected type:  web-app (Next.js)     confidence: 0.95
  Boot candidate: `npm run dev`          from: package.json scripts.dev
  Health URL:     /api/health            from: src/app/api/health/route.ts
  Auth:           None detected          (will need configuration)
  Evidence:       Playwright available   from: package.json devDependencies

  Is this correct? [Yes / Adjust type / Adjust details]
```

User confirms or adjusts. Agent uses `ask_user` tool with choices.

### Step 3: Gather Remaining Details

Only ask what couldn't be auto-detected:

```
Questions (only if not auto-detected):

Q1: What port does the server listen on?
    → [3000] (detected from next.config.js)

Q2: How does auth work for this project?
    → [No auth needed / Persistent browser profile / API key / Token file]

Q3: What's the primary interaction method?
    → [HTTP API / Browser automation / Both]

Q4: Where should evidence files go?
    → [./scratch/evidence/] (default)
```

Skip questions where auto-detection has high confidence.

### Step 4: Generate harness.md

Write to `docs/project-rules/harness.md`:

```markdown
# Agent Harness

**Version**: 1.0.0
**Created**: 2026-03-06
**Maturity Level**: 1
**Project Type**: web-app

## Purpose
Enable agent autonomy by providing Boot → Interact → Observe capabilities
for the Next.js application at localhost:3000.

## Boot
- **Command**: `npm run dev`
- **Health Check**: `curl -sf http://localhost:3000/api/health`
- **Expected Response**: `{"ok":true}`
- **Boot Time**: ~8-12s
- **Idempotent**: Yes — check health before spawning

## Interact
- **Primary**: HTTP API
- **Endpoints**:
  - `POST /api/chat` — send message
  - `GET /api/chat/status?since=<id>` — poll for events
- **Auth Strategy**: None
- **Auth Expiry**: N/A

## Observe
- **Response capture**: JSON from API responses
- **Screenshots**: Playwright (`page.screenshot()`)
- **Logs**: `tail -f .next/server.log`
- **Evidence directory**: `./scratch/evidence/`

## Maturity Assessment
| Level | Status | Notes |
|-------|--------|-------|
| L0: No harness | | |
| L1: Manual boot + API | ✅ current | npm run dev + curl |
| L2: Auto boot + API | target | harness.mjs boots automatically |
| L3: Full interaction + evidence | | Add Playwright screenshots |
| L4: Self-healing | | Add auth refresh, process recovery |

## Validation Checklist
- [ ] Single command starts full stack
- [ ] Health check returns expected response
- [ ] Boot is idempotent (safe to run twice)
- [ ] Agent can send input (HTTP/stdin)
- [ ] Agent can capture output (JSON/screenshots)
- [ ] Auth is automated (if applicable)
- [ ] Evidence directory exists and is writable

## History
| Date | Plan | Change | Maturity Before → After |
|------|------|--------|------------------------|
| 2026-03-06 | 017-harness-integration | Initial creation | — → L1 |

<!-- USER CONTENT START -->
<!-- Project-specific notes, custom boot sequences, known issues -->
<!-- USER CONTENT END -->
```

### Step 5: Generate Bootstrap Script (Optional)

If user wants a bootstrap script, generate based on project type:

**Web App → harness.mjs**:
```javascript
#!/usr/bin/env node
// harness.mjs — Agent Harness
import { spawn } from 'child_process';

const HEALTH_URL = 'http://localhost:3000/api/health';
const BOOT_CMD = ['npm', ['run', 'dev']];
const BOOT_TIMEOUT = 30; // seconds
let procs = [];

async function boot() {
  // Idempotent: check if already running
  try {
    const res = await fetch(HEALTH_URL);
    if (res.ok) { console.log('✅ Already running'); return; }
  } catch {} // not running, start it

  const server = spawn(...BOOT_CMD, { stdio: 'pipe' });
  procs.push(server);

  for (let i = 0; i < BOOT_TIMEOUT; i++) {
    try {
      const res = await fetch(HEALTH_URL);
      if (res.ok) { console.log('✅ Ready'); return; }
    } catch {}
    await new Promise(r => setTimeout(r, 1000));
  }
  throw new Error('Boot failed — health check never passed');
}

async function interact(input) {
  return fetch('http://localhost:3000/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input)
  }).then(r => r.json());
}

async function observe() {
  return fetch('http://localhost:3000/api/chat/status')
    .then(r => r.json());
}

async function shutdown() {
  for (const p of procs) p.kill('SIGTERM');
  await new Promise(r => setTimeout(r, 1000));
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// Main — run if invoked directly
if (process.argv[2] === '--validate') {
  await boot();
  const result = await interact({ message: 'health check' });
  const evidence = await observe();
  console.log('✅ Harness validated:', { result, evidence });
  await shutdown();
}
```

**CLI → justfile recipe** (if project uses just):
```justfile
harness-boot:
  @echo "Booting CLI harness..."
  ./target/release/my-cli --serve &
  @sleep 2
  @curl -sf http://localhost:8080/health && echo "✅ Ready"

harness-interact CMD:
  echo '{{CMD}}' | ./target/release/my-cli

harness-observe:
  tmux capture-pane -t harness -p
```

**API → docker-compose wrapper**:
```bash
#!/bin/bash
# harness.sh — API Harness
docker-compose up -d
for i in $(seq 1 30); do
  curl -sf http://localhost:8080/health && echo "✅ Ready" && exit 0
  sleep 1
done
echo "❌ Boot failed" && exit 1
```

### Step 6: Report

```
✅ Harness created:

  Governance:  docs/project-rules/harness.md
  Bootstrap:   harness.mjs (optional — generated if requested)
  Type:        web-app (Next.js)
  Maturity:    L1 (Manual boot + API)

  Validation checklist: 3/7 items auto-verified
  
  Next steps:
  - Review harness.md and adjust as needed
  - Run /harness-v2 --validate to test
  - Plan-6 will validate harness at start of each phase
```

---

## VALIDATE Mode

When `docs/project-rules/harness.md` already exists:

### Step 1: Read Harness Config

Parse harness.md for: boot command, health URL, interaction method, observe method, maturity level.

### Step 2: Execute Validation Sequence

The prompt instructs the agent to run these checks using bash:

```
┌───────────────────────────────────────────────────────┐
│ BOOT CHECK                                             │
│                                                        │
│ 1. Check if already running:                           │
│    curl -sf {HEALTH_URL} → 200?                        │
│    ├── YES → Skip boot, mark "already running"         │
│    └── NO  → Run {BOOT_CMD}, wait up to 60s            │
│                                                        │
│ Result: ✅ Running | ⚠️ Slow (>45s) | ❌ Failed         │
└───────────────────────────────────────────────────────┘
                          │
                          ▼
┌───────────────────────────────────────────────────────┐
│ INTERACT CHECK                                         │
│                                                        │
│ 1. Send test input per harness.md § Interact:          │
│    curl -X POST {ENDPOINT} -d '{"test":true}'          │
│    OR: echo "test" | {CLI_CMD}                         │
│    OR: tmux send-keys -t harness "test" Enter          │
│                                                        │
│ Result: ✅ Responded | ❌ No response | ❌ Error         │
└───────────────────────────────────────────────────────┘
                          │
                          ▼
┌───────────────────────────────────────────────────────┐
│ OBSERVE CHECK                                          │
│                                                        │
│ 1. Capture evidence per harness.md § Observe:          │
│    Read JSON response body                             │
│    OR: page.screenshot() → file written?               │
│    OR: tmux capture-pane -p → non-empty output?        │
│                                                        │
│ Result: ✅ Evidence captured | ❌ No evidence            │
└───────────────────────────────────────────────────────┘
                          │
                          ▼
┌───────────────────────────────────────────────────────┐
│ VERDICT                                                │
│                                                        │
│ ✅ HEALTHY — All checks pass                            │
│ ⚠️ DEGRADED — Passes but slow or partial evidence      │
│ ❌ UNHEALTHY — Any check fails                          │
│ 🔴 UNAVAILABLE — Harness config missing/corrupt         │
└───────────────────────────────────────────────────────┘
```

### Step 3: Report & Recommend

```
🔍 Harness Validation Report:

  Boot:      ✅ Running (already active, 0s)
  Interact:  ✅ POST /api/chat → 200 (0.3s)
  Observe:   ✅ JSON response captured (0.1s)

  Verdict:   ✅ HEALTHY
  Maturity:  L2 (Auto boot + API)
  
  Checklist: 5/7 items passing
  Missing:   [ ] Screenshots configured
             [ ] Auth expiry detection
  
  Recommend: Add Playwright for L3 maturity
```

---

## Maturity Assessment Algorithm

| Check | L0 | L1 | L2 | L3 | L4 |
|-------|----|----|----|----|-----|
| harness.md exists | | ✅ | ✅ | ✅ | ✅ |
| Health check URL documented | | ✅ | ✅ | ✅ | ✅ |
| Boot command documented | | ✅ | ✅ | ✅ | ✅ |
| Agent can run boot autonomously | | | ✅ | ✅ | ✅ |
| Health check passes via agent | | | ✅ | ✅ | ✅ |
| Agent can interact (send input) | | | ✅ | ✅ | ✅ |
| Agent can observe (capture evidence) | | | | ✅ | ✅ |
| Screenshot/visual capture works | | | | ✅ | ✅ |
| Idempotent boot (detect already running) | | | | | ✅ |
| Auth expiry detection | | | | | ✅ |
| Auto-recovery from stale processes | | | | | ✅ |

**Assessment**: Count passing checks, map to highest fully-satisfied level.

---

## Open Questions

### Q1: Should validate mode auto-update maturity level in harness.md?

**RESOLVED**: Yes — validate mode updates `## Maturity Assessment` table and the header `**Maturity Level**` field to reflect current reality. This keeps harness.md honest.

### Q2: What if project uses multiple boot targets (dev, test, prod)?

**RESOLVED**: harness.md documents the **development** harness only. Production deployment is not a harness concern. If multiple dev modes exist (e.g., `just dev` vs `just chat`), document the primary one in Boot and list alternatives in USER CONTENT section.

### Q3: Should the prompt auto-detect an existing AGENT_BOOTSTRAP.md?

**RESOLVED**: Yes — if `AGENT_BOOTSTRAP.md` exists in project root, read it for boot/interact/observe hints during CREATE mode. Don't replace it — harness.md is governance, AGENT_BOOTSTRAP.md is procedure. Reference it in harness.md Related Documents.
