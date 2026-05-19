---
name: engineering-harness-v2
description: Create or validate the engineering harness for the current project — the broader substrate (justfile/Makefile/dev scripts, test runner, seed/fixture, env config) plus the Boot/Interact/Observe loop layered on top. Detects project type; generates `docs/project-rules/engineering-harness.md` (legacy names `agent-harness.md` / `harness.md` still supported on read); seeds `## Known Difficulties` from the compound ledger so boot-time reads see accumulated friction.
---
# engineering-harness-v2

Create or validate the **engineering harness** — the umbrella term covering both (1) the engineering substrate (`justfile`/`Makefile`/`package.json scripts`, test runner, seed scripts, env config — what developers and CI run) and (2) the Boot → Interact → Observe → Validate loop layered on top so agents can iterate on running software in 30-60 second cycles. This skill governs both as one cohesive thing.

**Engineering harness governance**: `docs/project-rules/engineering-harness.md` (new projects). Legacy names `docs/project-rules/agent-harness.md` and `docs/project-rules/harness.md` are still read as fallbacks for projects that haven't migrated yet — see Step 0 for the read order and Step 6 for the migration advisory.

**Layering**: the agent harness sits **on top of** the engineering harness (the project's `justfile`/`Makefile`/`package.json scripts.dev` boot command, test runner, etc.). The Boot command this skill records IS the engineering harness substrate. If no engineering harness exists, raise that as a finding before attempting to build the agent harness — Boot can't work without something to boot.

**Agent harness dossier**: Three capabilities (Boot, Interact, Observe), maturity model (L0–L4), 7 design principles.

---

## Input

```
$ARGUMENTS
# Flags:
# --create     Force CREATE mode (even if engineering-harness.md exists)
# --validate   Force VALIDATE mode
# --status     Quick maturity report (no changes)
# (no flags)   Auto-detect: CREATE if missing, VALIDATE if exists
```

---

## Execution Flow

### Step 0: Mode Detection

```
Check governance file (read order: new path first, then legacy fallbacks in order of recency):
  1. docs/project-rules/engineering-harness.md  ← new canonical path
  2. docs/project-rules/agent-harness.md        ← legacy fallback (pre engineering-harness rename)
  3. docs/project-rules/harness.md              ← older legacy fallback (pre agent-harness rename)

If found at either legacy path: log a one-line migration advisory in this skill's
output (e.g. "📁 Legacy filename detected — consider `git mv agent-harness.md
engineering-harness.md`") but do NOT modify the file. Continue normally.

Mode resolution:
  ├── EXISTS + no --create flag  → VALIDATE mode
  ├── MISSING + no --validate flag → CREATE mode
  ├── --create                 → CREATE mode (writes to engineering-harness.md)
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

#### Step 4: Generate engineering-harness.md

Write to `docs/project-rules/engineering-harness.md` (new canonical path) using this governance format. If a legacy `docs/project-rules/agent-harness.md` or `docs/project-rules/harness.md` exists, do NOT overwrite or migrate it automatically — write the new file alongside and emit the migration advisory in Step 6 so the user can choose when to `git mv` and remove the legacy.

```markdown
# Engineering Harness

**Version**: 1.0.0
**Created**: [TODAY]
**Maturity Level**: [assessed level]
**Project Type**: [detected type]

## Purpose
[1-2 sentences: what this harness enables for agents in this project. Covers both the engineering substrate (justfile/Makefile/dev scripts) and the agent-facing Boot/Interact/Observe loop on top.]

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

## Known Difficulties

<!-- Auto-seeded by engineering-harness-v2 from the compound ledger. -->
<!-- Up to 10 most-relevant open entries, filtered by target: engineering-harness | tooling | infra | build | config | dependencies | env | auth | tests | observe. -->
<!-- Sorted by recurrence (count of entries in the same cluster) descending, then by age (oldest first). -->
<!-- Agents reading this file at boot see accumulated friction without scanning the whole ledger. -->
<!-- Refresh: re-run engineering-harness-v2 (idempotent; re-reads compound and re-renders this section in place). -->

| # | Entry | Recurrence | Source retros |
|---|-------|-----------|---------------|
| _ | _If the compound ledger is empty (no `docs/compound/agents/**/*.retro.md` files matching the filter), this table stays empty — that's normal for a fresh install._ | _ | _ |

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

#### Step 4a: Seed `## Known Difficulties` from the compound ledger

After writing the template (or on every re-run of this skill), populate the `## Known Difficulties` section:

1. **Read** `docs/compound/agents/**/*.retro.md` files (skip if `docs/compound/` doesn't exist — the section stays empty until compound starts producing entries).
2. **Filter** entries to:
   - `entry.system.compound.status == "open"` OR `entry.system.compound.status == "suggested"` (closed/resolved entries are noise here)
   - `entry.target` in: `engineering-harness | tooling | infra | build | config | dependencies | env | auth | tests | observe` (relevance filter — these are the target classes a fresh agent hits during boot/install/health-check; entries outside this set are not boot-time concerns)
3. **Cluster** by `(entry.kind, entry.target)` and count recurrence (how many entries fall in each cluster across all retros).
4. **Sort** clusters by recurrence (descending), then by oldest entry in the cluster.
5. **Take top 10** clusters (cap to keep the boot read manageable).
6. **Render** as a table row per cluster:
   - `#` — sequential 1..N
   - `Entry` — one-line summary (longest representative `entry.description`)
   - `Recurrence` — count
   - `Source retros` — link list of `retro_id`s contributing to the cluster (cap at 3, then `+M more`)

Re-running this skill always re-renders Section 4a in place — idempotent; never appends duplicates.

If `docs/compound/` is missing or empty: write the placeholder row from the template (no harm; the section is informational and will populate once compound has data).

#### Step 5: Validate (post-create)

After generating engineering-harness.md, run the VALIDATE flow (below) to confirm it works. Report results.

#### Step 6: Report

```
✅ Agent harness created:

  Governance:   docs/project-rules/engineering-harness.md
  Type:         [type] ([framework])
  Maturity:     L[N] ([description])
  Checklist:    [X/15] items verified

  Next steps:
  - Review engineering-harness.md and adjust as needed
  - Run /agent-harness-v2 --validate after changes
  - Pipeline commands (plan-1a, plan-5, plan-6) will auto-discover this file
```

If a legacy `docs/project-rules/agent-harness.md` or `docs/project-rules/harness.md` was found during Step 0, append:

```
  📁 Legacy filename detected: docs/project-rules/<legacy-name> still present.
     Consider migrating: git mv docs/project-rules/<legacy-name> docs/project-rules/engineering-harness.md
     (Old file is still read as fallback; this advisory is informational, not blocking.)
```

---

### VALIDATE Mode

#### Step 1: Read Agent Harness Config

Read `docs/project-rules/engineering-harness.md` (or fall back to legacy `docs/project-rules/harness.md` and emit the migration advisory). Parse: boot command, health check, interaction method, observe method, current maturity level.

If both paths are missing or unparseable → error with suggestion to run `/agent-harness-v2 --create`.

#### Step 2: Execute 3-Stage Validation

Run checks using bash tool:

**Stage 1: Boot Check** (5s if running, 60s cold boot)
```
1. Check if already running: run health check command from engineering-harness.md
   ├── Healthy → "Already running" (skip boot)
   └── Not responding → Run boot command, retry health check (30 × 2s = 60s max)
```

**Stage 2: Interact Check** (5s, single attempt)
```
1. Send test input per engineering-harness.md § Interact
   ├── Response received → ✅
   └── No response / error → ❌ (log specific error)
```

**Stage 3: Observe Check** (5s, single attempt)
```
1. Capture evidence per engineering-harness.md § Observe
   ├── Evidence non-empty and readable → ✅
   └── Empty or failed → ❌
```

#### Step 3: Classify Verdict

| Verdict | Criteria |
|---------|----------|
| **✅ HEALTHY** | All 3 checks pass, boot ≤ 45s |
| **⚠️ SLOW** | All 3 checks pass, boot > 45s |
| **❌ UNHEALTHY** | Any check fails |
| **🔴 UNAVAILABLE** | No engineering-harness.md (or legacy agent-harness.md / harness.md) and no boot command |

#### Step 4: Update Maturity & Report

Update engineering-harness.md `## Maturity Assessment` to reflect current reality.
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

Read engineering-harness.md (or legacy agent-harness.md / harness.md, with migration advisory) and report: project type, maturity level, last validation date, checklist completion. No agent harness boots or health checks.

---

## Anti-Patterns (from agent harness dossier)

When generating engineering-harness.md, warn against:
- **"Tests Are Enough"** — unit tests (engineering harness signal) pass while the running app the agent harness exercises is broken. These are different signals; you need both.
- **"The Agent Can Figure It Out"** — agents need explicit Boot/Interact/Observe instructions
- **"We'll Add the Agent Harness Later"** — agent harness first (after engineering harness exists), features second
- **"Screenshot Everything"** — prefer structured output over screenshots
- **"One Process Per Terminal"** — single entry point, single shutdown handler
