---
name: harness-1-boot
description: Boot stage of the harness loop (Boot → Backpressure Check → Do Work and Observe → Retro and Magic Wand → Improve). Validate that the engineering harness is healthy at session start and report its maturity. VALIDATE mode runs the Boot → Interact → Observe health check; STATUS mode gives a quick read-only maturity report. Reads `docs/project-rules/engineering-harness.md` (legacy `agent-harness.md` / `harness.md` read as fallback, canonical-first). Reports `UNAVAILABLE` gracefully when no governance doc and no boot command exist — the governance doc is provisioned by the separate engineering-harness setup effort, not by this skill.
---
# harness-1-boot

The **Boot** stage of the harness loop. Run it at session start to confirm the engineering harness is healthy and to report where it sits on the maturity curve. Two modes: `--validate` (run the live Boot → Interact → Observe checks) and `--status` (read-only maturity report).

> **The harness IS the product.** Development infrastructure — CLI tools, build scripts, test harnesses, `just`/`make` recipes, seed scripts, environment setup, plus the agent-facing Boot/Interact/Observe loop on top — is not scaffolding. It is the first-class product of engineering work. Boot exists because if a brand-new agent session can't reach a healthy, observable running system in 30-60 seconds using only the governance doc, that is the most important thing to fix before any feature work. Every "no" here is harness work to do.

**Engineering harness governance**: `docs/project-rules/engineering-harness.md` (canonical). Legacy names `docs/project-rules/agent-harness.md` and `docs/project-rules/harness.md` are still read as fallbacks for projects that haven't migrated — see Step 0 for the read order. This skill never *creates* the governance doc; provisioning it is the separate engineering-harness setup effort's job. If it is absent, boot degrades gracefully (reports `UNAVAILABLE`) rather than blocking the session.

**Layering**: the agent-facing Boot/Interact/Observe loop sits **on top of** the engineering substrate (the project's `justfile`/`Makefile`/`package.json scripts.dev` boot command, test runner, etc.). The Boot command the governance doc records IS the engineering harness substrate. If no substrate exists, the verdict is `UNAVAILABLE` — Boot can't work without something to boot.

**Signal readiness**: Boot reports more than "can the process start?" It also checks whether the harness exposes enough deterministic signals for a human or agent to prove behavior without inference: runtime inspectability, smoke paths, architecture/static checks, security/dependency/schema checks, evidence paths, and known back-pressure gaps. Missing signals are improvement candidates, not blockers or scores.

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

Read the governance doc using the canonical-first fallback chain from Step 0: `docs/project-rules/engineering-harness.md` → `agent-harness.md` → `harness.md` (emit the migration advisory if a legacy name was used). Parse: boot command, health check, interaction method, observe method, current maturity level, deterministic signal inventory, evidence paths, and any declared back-pressure gaps.

If all three paths are missing or unparseable → report `UNAVAILABLE` (verdict table below). The governance doc is provisioned by the separate engineering-harness setup effort, not by this skill — boot does not block the session; it notes the harness is not yet provisioned and proceeds.

If the governance doc exists but omits signal-readiness sections, continue normally and report those dimensions as "not declared". Do not scaffold or rewrite the doc just to add them.

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

### Step 4: Read signal/back-pressure readiness

Build a short signal-readiness summary from the governance doc and observed evidence. Use plain categories; do not invent a numeric score or threshold:

| Dimension | What to look for | Report value |
|-----------|------------------|--------------|
| Runtime inspectability | App/API/CLI can expose current health/state to the agent. | present / missing / not declared |
| Smoke paths | A deterministic route, command, or scenario proves the main behavior starts. | present / missing / not declared |
| Architecture/static checks | Dependency rules, lint, type checks, ArchUnit/Roslyn/CodeQL, or similar checks exist. | present / missing / not declared |
| Security/dependency/schema checks | Dependency audit, schema validation, CodeQL, data checks, or equivalent proof exists. | present / missing / not declared |
| Evidence paths | Screenshots, logs, traces, snapshots, artifacts, or command output locations are discoverable. | present / missing / not declared |
| Back-pressure gaps | The doc names behaviors that still rely on inference or human eyeballing. | list / none declared |

Treat absent dimensions as harness-improvement signals for Observe/Retro. They do not change `HEALTHY` to `UNHEALTHY` unless the actual Boot, Interact, or Observe checks fail.

### Step 5: Update Maturity & Report

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
  Signals:   [runtime/smoke/static/security/evidence summary]
  Gaps:      [known back-pressure gaps or "none declared"]

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

The canonical maturity ladder is the **nucleus / self-improving** ladder — the same one the engineering-harness setup effort provisions into the governance doc. Boot reports the level that is *actually working* (not aspirational), reading it from the governance doc's `## Maturity Assessment`.

| Level | Meaning |
|-------|---------|
| L0: No harness | Commands live in tribal knowledge, scattered docs, or ad-hoc scripts |
| L1: Front door | Governance doc, harness/, CLI skeleton, AGENTS.md pointer exist; commands may be unconfigured |
| L2: Commands encoded | Build/test/run/health are confirmed and runnable |
| L3: Improvement loop active | Friction log has entries; ≥1 has been encoded into the harness; magic-wand prompts have shipped harness changes |
| L4: Self-improving | The harness regularly produces improvements during normal work; new agents onboard without human help; proof-level ceilings are tracked |

### Agent-harness capability axis (separate from maturity)

This is a **capability axis**, not the maturity ladder — it describes what the agent-facing Boot → Interact → Observe layer can do, independent of where the engineering harness sits on the nucleus ladder above. It is deliberately **unnumbered** so it never collides with the L0–L4 maturity levels: a bare "L2" always means maturity, never capability. Useful when reporting how richly an agent can drive and observe the running system, roughly progressing:

**no interaction** (agent writes code, human tests) → **manual boot + API** (human starts the stack, agent sends requests) → **auto boot + API** (agent starts the stack, health check, API interaction) → **full interaction + evidence** (agent boots, drives UI/CLI, captures screenshots) → **self-healing** (auto-recovery from stale processes, auth expiry).

## What Boot does NOT do

- **No setup or scaffolding**. It never creates `docs/project-rules/engineering-harness.md`, `docs/harness/`, command maps, fixtures, or harness CLI scripts. Those are provisioned by the separate engineering-harness setup effort.
- **No gates, scores, or thresholds for back-pressure**. Signal-readiness gaps are advisory improvement candidates. Boot only fails when the live Boot, Interact, or Observe checks fail.
- **No product-specific sensor implementation**. It reports whether sensors are present or missing; it does not invent downstream project checks.
