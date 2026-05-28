---
name: harness-1-boot
description: Boot stage of the harness loop (Boot → Do Work → Observe → Retro). Validate that the engineering harness is healthy at session start and report its maturity. VALIDATE mode runs the Boot → Interact → Observe health check; STATUS mode gives a quick read-only maturity report. Reads `docs/project-rules/engineering-harness.md` (legacy `agent-harness.md` / `harness.md` read as fallback, canonical-first). Reports `UNAVAILABLE` gracefully when no governance doc and no boot command exist — the governance doc is provisioned by the separate engineering-harness setup effort, not by this skill.
---
# harness-1-boot

The **Boot** stage of the harness loop. Run it at session start to confirm the engineering harness is healthy and to report where it sits on the maturity curve. Two modes: `--validate` (run the live Boot → Interact → Observe checks) and `--status` (read-only maturity report).

> **The harness IS the product.** Development infrastructure — CLI tools, build scripts, test harnesses, `just`/`make` recipes, seed scripts, environment setup, plus the agent-facing Boot/Interact/Observe loop on top — is not scaffolding. It is the first-class product of engineering work. Boot exists because if a brand-new agent session can't reach a healthy, observable running system in 30-60 seconds using only the governance doc, that is the most important thing to fix before any feature work. Every "no" here is harness work to do.

**Engineering harness governance**: `docs/project-rules/engineering-harness.md` (canonical). Legacy names `docs/project-rules/agent-harness.md` and `docs/project-rules/harness.md` are still read as fallbacks for projects that haven't migrated — see Step 0 for the read order. This skill never *creates* the governance doc; provisioning it is the separate engineering-harness setup effort's job. If it is absent, boot degrades gracefully (reports `UNAVAILABLE`) rather than blocking the session.

**Layering**: the agent-facing Boot/Interact/Observe loop sits **on top of** the engineering substrate (the project's `justfile`/`Makefile`/`package.json scripts.dev` boot command, test runner, etc.). The Boot command the governance doc records IS the engineering harness substrate. If no substrate exists, the verdict is `UNAVAILABLE` — Boot can't work without something to boot.

---

## Input

```
$ARGUMENTS
# Flags:
# --validate   Run the live 3-stage Boot → Interact → Observe health check (default if governance doc exists)
# --status     Quick read-only maturity report (no boots, no changes)
# (no flags)   Auto-detect: VALIDATE if governance doc exists, else report UNAVAILABLE
```

---

## Step 0: Read the governance doc (canonical-first)

```
Check governance file (read order: canonical path first, then legacy fallbacks in order of recency):
  1. docs/project-rules/engineering-harness.md  ← canonical path
  2. docs/project-rules/agent-harness.md         ← legacy fallback (pre engineering-harness rename)
  3. docs/project-rules/harness.md               ← older legacy fallback (pre agent-harness rename)

If found at either legacy path: log a one-line migration advisory in this skill's
output (e.g. "📁 Legacy filename detected — consider `git mv agent-harness.md
engineering-harness.md`") but do NOT modify the file. Continue normally.

Mode resolution:
  ├── EXISTS + no --status flag → VALIDATE mode
  ├── EXISTS + --status         → STATUS mode (read-only report)
  └── MISSING at all 3 paths    → report UNAVAILABLE gracefully (no governance doc to validate;
                                   it is provisioned by the separate engineering-harness setup effort)
```

---

## VALIDATE Mode

### Step 1: Read the engineering harness governance doc

Read the governance doc using the canonical-first fallback chain from Step 0: `docs/project-rules/engineering-harness.md` → `agent-harness.md` → `harness.md` (emit the migration advisory if a legacy name was used). Parse: boot command, health check, interaction method, observe method, current maturity level.

If all three paths are missing or unparseable → report `UNAVAILABLE` (verdict table below). The governance doc is provisioned by the separate engineering-harness setup effort, not by this skill — boot does not block the session; it notes the harness is not yet provisioned and proceeds.

### Step 2: Execute 3-Stage Validation

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

### Step 3: Classify Verdict

| Verdict | Criteria |
|---------|----------|
| **✅ HEALTHY** | All 3 checks pass, boot ≤ 45s |
| **⚠️ SLOW** | All 3 checks pass, boot > 45s |
| **❌ UNHEALTHY** | Any check fails |
| **🔴 UNAVAILABLE** | No engineering-harness.md (or legacy agent-harness.md / harness.md) and no boot command |

### Step 4: Update Maturity & Report

Update engineering-harness.md `## Maturity Assessment` to reflect current reality.
Update `**Maturity Level**` header field.
Append validation result to `## History` table.

(If the verdict is `UNAVAILABLE`, there is no governance doc to update — skip this step and report the gap.)

Report:
```
🔍 Engineering Harness Validation Report:

  Boot:      [✅/❌] [detail] ([duration])
  Interact:  [✅/❌] [detail] ([duration])
  Observe:   [✅/❌] [detail] ([duration])

  Verdict:   [verdict]
  Maturity:  L[N] ([description])
  Checklist: [X/15] items passing
  Missing:   [list unchecked items]
```

---

## STATUS Mode

Quick read-only report — no validation, no changes.

Read engineering-harness.md (or legacy agent-harness.md / harness.md, with migration advisory) and report: project type, maturity level, last validation date, checklist completion. No harness boots or health checks. If all three paths are absent → report `UNAVAILABLE`.

---

## Measure compounding value

> **Measure.** Note what each session encodes — not for estimates, for evidence. The maturity level Boot reports IS the dashboard reading. If Session N+1 boots faster, cleaner, or at a higher maturity level than Session N because the previous session encoded what it learned, that is data proving the loop is closing. The `## History` table the validation appends is the trajectory; a maturity level that climbs (or a boot time that shrinks) over successive sessions is the compounding value made visible. A flat or regressing trajectory is a signal that observed friction is not getting encoded — check the retro ledger (`harness-3-retro --harvest`).

---

## Maturity model (reference)

| Level | Meaning |
|-------|---------|
| L0: No harness | Agent writes code, human tests |
| L1: Manual boot + API | Human starts stack, agent sends requests |
| L2: Auto boot + API | Agent starts stack, health check, API interaction |
| L3: Full interaction + evidence | Agent boots, drives UI/CLI, captures screenshots |
| L4: Self-healing | Auto-recovery from stale processes, auth expiry |

Boot reports the level that is *actually working* (not aspirational).
