# Workshop: Pre-Phase Validation Protocol

**Type**: Integration Pattern  
**Plan**: 017-harness-integration  
**Spec**: [harness-integration-spec.md](../harness-integration-spec.md)  
**Created**: 2026-03-06  
**Status**: Draft

**Related Documents**:
- [001-agent-harness-dossier.md](./001-agent-harness-dossier.md) — Harness design principles
- [002-harness-prompt-design.md](./002-harness-prompt-design.md) — Create/validate harness prompt

---

## Purpose

Specify the exact protocol that `plan-6-v2-implement-phase` executes at the **start of every phase** to validate the harness is operational. This is a mandatory pre-flight check — the agent's equivalent of a pilot's pre-departure checklist.

## Key Questions Addressed

- What's the health check sequence? (Boot → Interact → Observe → Verdict)
- How long to wait for health checks? (Timeout strategy)
- What's "unhealthy" vs "slow" vs "unavailable"? (Failure classification)
- How does the human override UX work?
- How does override get logged?
- Should validation re-boot, or just check if running?

---

## Protocol Overview

```
┌─────────────────────────────────────────────────────────┐
│                PRE-PHASE VALIDATION                      │
│            Runs at START of every phase                   │
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │  BOOT    │──→│ INTERACT │──→│ OBSERVE  │──→ VERDICT  │
│  │  check   │   │  check   │   │  check   │             │
│  └──────────┘   └──────────┘   └──────────┘            │
│       │              │              │                    │
│       ▼              ▼              ▼                    │
│    Running?      Can send?     Can capture?             │
│    ├─ Yes: skip  ├─ Yes: ✅     ├─ Yes: ✅              │
│    └─ No: boot   └─ No: ❌     └─ No: ❌               │
│                                                          │
│  Any ❌ → ASK HUMAN (override available)                 │
└─────────────────────────────────────────────────────────┘
```

---

## Three-Stage Validation Sequence

### Stage 1: Boot Check

**Goal**: Confirm the harness runtime is up and responsive.

**Procedure**:
1. Read `docs/project-rules/harness.md § Boot` for health check command
2. Run health check (e.g., `curl -sf http://localhost:PORT/health`)
3. If healthy → mark "already running", skip boot (idempotent — **never re-boot a healthy harness**)
4. If not responding → run boot command from harness.md
5. Retry health check: 30 attempts × 2s intervals = 60s max

**Timeout**: 60 seconds total for cold boot; 5 seconds for "already running" check.

```bash
# Check-if-running (fast path)
curl -sf http://localhost:3000/api/health && echo "RUNNING" && exit 0

# Cold boot (slow path)
npm run dev &
for i in $(seq 1 30); do
  curl -sf http://localhost:3000/api/health && echo "READY" && exit 0
  sleep 2
done
echo "BOOT_FAILED" && exit 1
```

### Stage 2: Interact Check

**Goal**: Confirm the agent can send input to the running software.

**Procedure**:
1. Read `docs/project-rules/harness.md § Interact` for interaction method
2. Send a test input per the documented method
3. Verify a response was received (any valid response — not checking correctness, just reachability)

**Timeout**: 5 seconds, single attempt (if boot passed, interact should work immediately).

```bash
# HTTP interaction test
curl -sf -X POST http://localhost:3000/api/health \
  -H "Content-Type: application/json" \
  -d '{"test":true}' && echo "INTERACT_OK"

# Terminal interaction test
tmux send-keys -t harness "echo health-check" Enter
sleep 1
tmux capture-pane -t harness -p | grep -q "health-check" && echo "INTERACT_OK"
```

### Stage 3: Observe Check

**Goal**: Confirm the agent can capture evidence from the running software.

**Procedure**:
1. Read `docs/project-rules/harness.md § Observe` for evidence capture method
2. Capture one piece of evidence (response body, screenshot, terminal output)
3. Verify evidence is non-empty and readable

**Timeout**: 5 seconds, single attempt.

```bash
# HTTP observe test
curl -sf http://localhost:3000/api/health | jq . && echo "OBSERVE_OK"

# Screenshot observe test (Playwright)
node -e "
  const { chromium } = require('playwright');
  (async () => {
    const b = await chromium.launch();
    const p = await b.newPage();
    await p.goto('http://localhost:3000');
    await p.screenshot({ path: '/tmp/harness-check.png' });
    await b.close();
    console.log('OBSERVE_OK');
  })();
"

# Terminal observe test
tmux capture-pane -t harness -p | head -5 && echo "OBSERVE_OK"
```

---

## Timeout Strategy

| Check | Per-Attempt | Retries | Total Max | Rationale |
|-------|-------------|---------|-----------|-----------|
| **Boot (already running)** | 5s | 1 | 5s | Fast path: just a curl |
| **Boot (cold start)** | 2s | 30 | 60s | SPA stabilization can take 10-15s |
| **Interact** | 5s | 1 | 5s | If boot passed, this should be instant |
| **Observe** | 5s | 1 | 5s | Evidence capture is a single operation |
| **Total (worst case)** | — | — | **70s** | Acceptable: dossier targets 30-60s cycles |

---

## Failure Classification

| Verdict | Criteria | Agent Action | Human Action |
|---------|----------|-------------|--------------|
| **✅ HEALTHY** | All 3 checks pass, boot ≤ 45s | Proceed to phase | None needed |
| **⚠️ SLOW** | All 3 checks pass, boot > 45s | Proceed with note | Consider optimizing boot |
| **❌ UNHEALTHY** | Any check fails | **Stop. Ask human.** | Override / fix / abort |
| **🔴 UNAVAILABLE** | No harness.md exists OR harness.md has no boot command | **Stop. Ask human.** | Build harness / override / skip |

### Failure Diagnosis Table

| Symptom | Likely Cause | Suggested Fix |
|---------|-------------|---------------|
| Boot timeout (60s, no health response) | Server crashed on start, port conflict, missing dependencies | Check stderr, `lsof -i :PORT`, `npm install` |
| Health returns non-200 | App started but routes not registered, middleware error | Check server logs, verify route registration |
| Interact fails (no response) | Wrong endpoint, auth required, CORS blocking | Verify endpoint URL, check auth strategy, disable CORS for local |
| Observe fails (empty evidence) | Evidence path wrong, Playwright not installed, tmux session gone | Verify paths, `npx playwright install`, create tmux session |
| Auth error (401/403) | Token expired, cookie stale, profile locked | Refresh token, re-login browser profile, kill competing sessions |

---

## Human Override UX

When any check fails, present choices via `ask_user`:

### Unhealthy Harness

```
🛑 Harness validation failed for Phase 2: API Routes

  Boot:      ✅ Running (0.3s)
  Interact:  ❌ FAILED — POST /api/chat returned 401 Unauthorized
  Observe:   ⏭️ Skipped (interact failed)

  Likely cause: Auth token expired (last validated 26h ago)
```

**Choices**:
1. **"Retry after I fix it"** — Human fixes auth, agent re-runs validation
2. **"Continue without harness"** — Agent proceeds, logs override, uses manual/unit testing only
3. **"Abort this phase"** — Agent stops, waits for human to resolve

### Unavailable Harness

```
ℹ️ No harness found for this project

  docs/project-rules/harness.md: Not found
  
  This phase has no automated validation loop.
  The agent will rely on unit tests and manual verification.
```

**Choices**:
1. **"Build a harness first"** — Agent runs `/harness-v2 --create` before continuing
2. **"Continue without harness"** — Agent proceeds with standard testing
3. **"Abort"** — Agent stops

---

## Override Logging

Every validation result is logged in **two locations**:

### Location 1: Execution Log (`execution.log.md`)

Appended at the start of each phase's execution log section:

```markdown
### Pre-Phase Validation — 2026-03-06T14:32:00Z

| Check | Status | Duration | Detail |
|-------|--------|----------|--------|
| Boot | ✅ Running | 0.3s | Already active, skipped cold boot |
| Interact | ✅ OK | 0.8s | POST /api/chat → 200 |
| Observe | ✅ OK | 0.2s | JSON response captured, 847 bytes |
| **Verdict** | **✅ HEALTHY** | **1.3s** | |

---
```

When override is used:

```markdown
### Pre-Phase Validation — 2026-03-06T14:32:00Z

| Check | Status | Duration | Detail |
|-------|--------|----------|--------|
| Boot | ✅ Running | 0.3s | Already active |
| Interact | ❌ FAILED | 5.0s | POST /api/chat → 401 Unauthorized |
| Observe | ⏭️ Skipped | — | Interact failed |
| **Verdict** | **❌ UNHEALTHY** | **5.3s** | |

**⚠️ HUMAN OVERRIDE**: User chose "Continue without harness"
- Reason: "Auth token expired, will fix after this phase"
- Fallback: Unit tests and manual verification only
- Evidence capture: Degraded (no API interaction available)

---
```

### Location 2: Harness History (`docs/project-rules/harness.md § History`)

Only if harness.md exists. Append row to History table:

```markdown
| Date | Plan | Change | Maturity Before → After |
|------|------|--------|------------------------|
| 2026-03-06 | 017-harness P2 | Validated ✅ HEALTHY | L2 → L2 |
| 2026-03-06 | 017-harness P3 | Override: auth expired | L2 → L2 (degraded) |
```

---

## Re-Boot vs Check-If-Running Decision Tree

```
                    ┌──────────────────┐
                    │ Health check URL  │
                    │ from harness.md   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ curl health URL   │
                    │ (5s timeout)      │
                    └────────┬─────────┘
                             │
                   ┌─────────┴──────────┐
                   │                    │
              200 OK?              Not reachable?
                   │                    │
                   ▼                    ▼
         ✅ Already running     ┌──────────────┐
         Skip boot.             │ Run boot cmd │
         Proceed to             │ from harness │
         Interact check.        │ (60s timeout)│
                                └──────┬───────┘
                                       │
                              ┌────────┴────────┐
                              │                 │
                         Health OK?        Timeout?
                              │                 │
                              ▼                 ▼
                    ✅ Fresh boot          ❌ BOOT FAILED
                    Proceed to             → Ask human
                    Interact check.
```

**Rule**: Never kill a healthy running harness. Only cold-boot when nothing is responding. If human chooses "kill & retry", agent runs `kill` on the documented process, then re-boots.

---

## Integration Points in plan-6

The protocol inserts into plan-6-v2-implement-phase at **Step 2** (Load Context), before the task loop begins:

```
Step 1: Resolve plan + phase
Step 2: Load context (spec, plan, tasks, domains)
  ↓
Step 2a: PRE-PHASE HARNESS VALIDATION  ← NEW
  - Read harness.md (if exists)
  - Run Boot → Interact → Observe sequence
  - Log result to execution.log.md
  - If UNHEALTHY: ask_user for override
  - If UNAVAILABLE: ask_user for override
  ↓
Step 3: Begin task loop
  - For each task: implement → test → update progress
  - Use harness observe for evidence capture when available
  ↓
Step 4: Post-phase updates
  - Update harness.md § History
```

---

## Edge Cases

### Edge Case 1: Harness was healthy at phase start, breaks mid-phase

**Not handled by pre-phase validation** — this is a runtime concern. The agent should detect interaction failures during task execution and:
1. Log the failure in Discoveries & Learnings table
2. Attempt one retry
3. If still failing, ask human (same override UX as pre-phase)

### Edge Case 2: Multiple phases run back-to-back

Each phase gets its own pre-phase validation. If Phase 1 leaves the harness running and healthy, Phase 2's check is the fast path (5s check-if-running, skip boot).

### Edge Case 3: Phase 0 IS "Build Harness"

Special case: Phase 0 creates the harness, so pre-phase validation will show UNAVAILABLE. Agent should:
1. Note "Phase 0: Building harness — validation will run at end of phase instead"
2. Skip pre-phase validation
3. Run validation at **end** of Phase 0 to confirm harness works
4. Log result — Phase 0 only succeeds if harness validates HEALTHY

### Edge Case 4: Harness.md exists but boot command is wrong

Interact check will fail after boot succeeds. Agent should surface the mismatch:
```
⚠️ Boot succeeded but interact failed.
   harness.md says: POST /api/chat
   Actual error: Connection refused on port 3000
   
   Possible fix: Update harness.md § Boot with correct port
```

---

## Open Questions

### Q1: Should validation also check auth token freshness?

**RESOLVED**: Yes — if harness.md § Interact documents an auth strategy, validation should attempt an authenticated request. A 401/403 is a clear signal that auth has expired. Surface it as the #1 failure mode it is.

### Q2: Should validation results be cached across rapid re-runs?

**RESOLVED**: No — always re-validate. The check is cheap (5s for already-running). Caching introduces staleness risk, which defeats the purpose. The only optimization is not re-booting a healthy harness.

### Q3: How does this interact with CI/CD?

**OPEN**: In CI, there's no human to override. Options:
- CI mode: UNHEALTHY → hard fail (no override)
- CI mode: UNAVAILABLE → skip harness, rely on test suite
- Future consideration — not in scope for this plan
