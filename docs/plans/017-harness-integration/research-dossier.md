# Research Dossier: Harness Integration into V2 Command System

**Plan**: 017-harness-integration  
**Date**: 2026-03-06  
**Branch**: main  
**Research Query**: How to integrate the agent harness concept into the v2 command pipeline — adding harness awareness to /1a, /2, /3, /5, and /6, with a new harness prompt, and governance at `docs/project-rules/harness.md`.

---

## Summary

The v2 command system has a well-established pattern for cross-cutting concerns: the **domain system** is woven through every command using a consistent file-check → context-load → subagent-pass → output-section → review-validate lifecycle. The **harness** (Boot → Interact → Observe → Validate feedback loop for agents) should follow this exact same pattern — not as a standalone command, but as awareness integrated into 5 existing commands plus one new utility prompt. The canonical location for harness governance is `docs/project-rules/harness.md` (not `docs/rules/` — that path has zero references across all 27 v2 commands).

---

## Key Findings

| # | Finding | Impact | Source |
|---|---------|--------|--------|
| KF-01 | **`docs/project-rules/` is the canonical rules path** — zero references to `docs/rules/` in any v2 command. Harness.md must live alongside constitution, rules, idioms, architecture. | CRITICAL | DC-08 |
| KF-02 | **Cross-cutting concerns follow a 10-step integration pattern** (file check → spec section → clarify question → subagent context → manifest entry → task column → implementation enforcement → post-impl sync → review subagent → graceful degradation). Domains prove this pattern works. | CRITICAL | PS-01–10 |
| KF-03 | **Harness is infrastructure, not a domain** — it's a project-wide governance concern like constitution. Should be woven into existing commands, not a new standalone command. | HIGH | DB-01, DB-04 |
| KF-04 | **Plan-0 constitution already supports extensible detection** — same "check file → assess maturity → flag for plan-2" pattern can detect harness.md presence and maturity level (L0–L4). | HIGH | DB-06, DC-05 |
| KF-05 | **The testing pipeline already partially implements harness concepts** — Evidence capture (plan-6 execution log), testing strategy selection (plan-2 Q2), validation checkpoints (plan-7 subagent 4), coverage mapping (plan-7 AC↔Evidence). Harness awareness extends these, not replaces them. | HIGH | QT-01–10 |
| KF-06 | **Rules are convention-discovered, not parameter-passed** — v2 commands auto-locate `docs/project-rules/*.md` files during execution. No parameter plumbing needed for harness.md. | MEDIUM | DC-06 |
| KF-07 | **The flight plan IS already a live execution harness** — Plan-5b creates a state-machine tracking artifact; plan-6 mandates real-time updates. Harness awareness adds the missing Boot/Interact/Observe loop around this. | MEDIUM | IA-05 |
| KF-08 | **Harness maturity directly affects Complexity Scores** — A project at Harness Level 0 has higher CS because feedback loops are slow. Post-harness phases drop CS because agents iterate autonomously (30-60s cycles). | MEDIUM | DB-07, PL-08 |
| KF-09 | **Auth expiry is the #1 harness failure mode** — From the MYOB case study. Harness.md governance must include auth strategy requirements and expiry detection patterns. | MEDIUM | PL-07, PL-14 |
| KF-10 | **Two complementary layers needed**: `docs/project-rules/harness.md` (governance — what harnesses MUST provide) and per-project `AGENT_BOOTSTRAP.md` or `justfile` (procedure — HOW to run the harness). | MEDIUM | DC-09 |

---

## Integration Architecture

### The Cross-Cutting Pattern (proven by domains)

```
┌─────────────────────────────────────────────────────────────────────┐
│  DOMAIN PATTERN (template)          HARNESS PATTERN (new)           │
├─────────────────────────────────────────────────────────────────────┤
│  1. File check: registry.md?    →   1. File check: harness.md?     │
│  2. Spec section: Target Domains →  2. Spec section: Harness Req   │
│  3. Clarify Q: Domain Review    →   3. Clarify Q: Harness Status   │
│  4. Architect: Domain Manifest  →   4. Architect: Harness Strategy  │
│  5. Tasks: Domain column        →   5. Tasks: Harness column/gate   │
│  6. Implement: Placement rules  →   6. Implement: Health check gate │
│  7. Post-impl: domain.md sync   →   7. Post-impl: harness.md sync  │
│  8. Review: Compliance subagent →   8. Review: Harness validation   │
│  9. Graceful degradation        →   9. Graceful degradation         │
│  10. Concepts reuse             →   10. Harness pattern reuse       │
└─────────────────────────────────────────────────────────────────────┘
```

### Per-Command Integration Map

| Command | Role | What Changes |
|---------|------|-------------|
| **plan-1a-v2-explore** | **Producer** | Add harness discovery to research. If `docs/project-rules/harness.md` exists → include harness status, maturity level, usage history in dossier. If absent → note "No harness found" and **suggest a workshop** (workshop opportunity for plan-1b spec). If present → include boot command, health URL, interaction patterns, evidence capture methods in Context section. |
| **plan-2-v2-clarify** | **Gate** | Add "Harness Readiness" as a **standard question** (like Testing Strategy). If no harness exists → ask user: "This project has no agent harness. Should building one be the first phase? (Yes/No/Override — feature doesn't need one)". Capture answer in spec. |
| **plan-3-v2-architect** | **Producer** | If harness needed (from plan-2) and doesn't exist → **Phase 0 MUST be "Build Harness"** (unless user overrode). Phase 0 is special — it's the prerequisite that enables agent autonomy for all subsequent phases. Add `## Harness Strategy` section to plan output: maturity target, boot command, health check, interaction model. If harness exists → reference it in Pre-Implementation Requirements and note that pre-phase validation is required. |
| **plan-5-v2-phase-tasks** | **Producer/Gate** | **Phase 0 enforcement**: If harness is needed (from plan-2/plan-3) and doesn't exist → plan-5 MUST ensure "Build Harness" is **Phase 0** (before any feature work). This is not Phase 1 — it's the prerequisite phase that enables all others. Pre-Implementation Check: verify harness health (if harness.md specifies a health URL). Context Brief: include harness boot command, known gotchas, auth strategy. If generating tasks for Phase 0 → task table generates harness-specific tasks (Boot, Interact, Observe, Health Check, Auth). |
| **plan-6-v2-implement** | **Consumer/Gate** | **Pre-phase harness validation is mandatory**: Before starting ANY phase (not just Phase 0), plan-6 MUST validate the harness is fully operational — run health check, confirm Boot/Interact/Observe capabilities all work. If harness is unhealthy → stop and diagnose before implementing (don't implement blind). This validation runs at the START of every phase, not just once. Post-phase: update `docs/project-rules/harness.md § History` with what changed. Evidence capture: use harness observe capabilities for validation throughout implementation. |

### New Artifact: Harness Prompt

A new utility prompt is needed: **`harness-v2.md`** (or similar). Purpose: Create or validate the agent harness for the current project.

**When invoked**:
1. Check `docs/project-rules/harness.md` — exists?
2. If NO → **Create mode**: Detect project type (web app, CLI, API, MCP, etc.), generate harness.md governance doc + bootstrap script skeleton, assess current maturity level
3. If YES → **Validate mode**: Run health check, verify Boot/Interact/Observe capabilities, report maturity level, flag issues (auth expiry, stale processes, missing evidence capture)

**Output**: Updated `docs/project-rules/harness.md` with current status, maturity assessment, and recommendations.

---

## Harness.md Governance Format

Based on IC-09/IC-10 (rule file format conventions) and the cross-cutting pattern:

```markdown
# Agent Harness

**Version**: 1.0.0  
**Created**: YYYY-MM-DD  
**Maturity Level**: [0-4]  
**Project Type**: [web-app | cli | api | mcp-server | mobile | iac]

## Purpose
[1-2 sentences: what this harness enables for agents]

## Boot
- **Command**: `just chat` | `node harness.mjs` | `docker-compose up`
- **Health Check**: `curl -sf http://localhost:PORT/health`
- **Boot Time**: ~Xs (target: 30-60s)
- **Idempotent**: Yes/No

## Interact
- **Primary**: [HTTP API | Terminal stdin | Browser automation | JSON-RPC]
- **Auth Strategy**: [Persistent profile | API key | Token file | None]
- **Auth Expiry**: [~24h | N/A | Token refresh]

## Observe
- **Response capture**: [HTTP JSON | stdout | DOM]
- **Screenshots**: [Playwright | N/A]
- **Structured output**: [JSON responses | parsed terminal | log files]
- **Evidence directory**: [./scratch/evidence/ | /tmp/]

## Maturity Assessment
| Level | Status | Notes |
|-------|--------|-------|
| L0: No harness | [current] | Agent writes code, human tests |
| L1: Manual boot + API | | |
| L2: Auto boot + API | | |
| L3: Auto boot + full interaction + evidence | | |
| L4: Self-healing | | |

## Anti-Patterns to Avoid
[from dossier Section 6 — project-specific notes]

## History
| Date | Plan | Change | Maturity Before → After |
|------|------|--------|------------------------|

<!-- USER CONTENT START -->
[Project-specific harness notes, custom boot sequences, domain-specific setup]
<!-- USER CONTENT END -->
```

---

## User Override Mechanism

The harness is a **soft gate, not a hard gate** (following domain precedent):

- **plan-2**: Asks about harness. User can answer "Override — this feature doesn't need a harness" → captured in spec `## Clarifications`
- **plan-3**: If user overrode, skip "Build Harness" Phase 0. Document override in plan.
- **plan-6**: Pre-phase harness validation runs at the **start of every phase**. If no harness → proceed with standard testing (unit tests, manual verification). Log "No harness available — using manual validation" in execution log. If harness exists but unhealthy → **stop and ask the human**. Human can override to continue without harness, or fix the issue first.
- **plan-7**: If no harness → review subagent notes it but doesn't block (MEDIUM finding, not CRITICAL)

This follows PS-09: the system works without a harness; findings are less structured but the pipeline doesn't break.

---

## Workshop Reference

The harness dossier at `workshop-001-agent-harness-dossier.md` establishes:
- **Three capabilities**: Boot, Interact, Observe (PL-02)
- **Seven design principles**: One-command boot, Health check gate, Idempotent boot, Clean shutdown, Two modes (Full/API-only), Evidence capture, Auth as infrastructure (PL-03–07)
- **Six patterns by software type**: Web app, CLI, MCP server, API/backend, Mobile/desktop, IaC (PL-09–12)
- **Maturity model L0–L4** with target L3 minimum (PL-08)
- **Harness checklist**: 15 items across Boot/Interact/Observe/Operate (PL-15)
- **Case study**: MYOB Agentic Web Server with concrete timings and failure modes (PL-14)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Harness awareness adds overhead to every command | Medium | Medium | Graceful degradation — if harness.md absent, commands proceed normally with a note |
| Users confused by harness vs testing strategy | Low | Medium | Plan-2 clarification separates concerns: testing = what to verify; harness = how agent verifies |
| Harness.md becomes stale | Medium | Low | Post-implementation sync (plan-6 step) keeps History current; plan-7 flags staleness |
| Auth expiry breaks harness mid-implementation | High | High | Harness.md must document expiry detection; plan-6 checks health before each task |

---

## Recommended Next Steps

1. **Run `/plan-1b-v2-specify`** to create the feature spec from this research
2. The spec should capture:
   - New harness prompt command (create/validate)
   - Modifications to 5 existing commands (plan-1a, plan-2, plan-3, plan-5, plan-6)
   - `docs/project-rules/harness.md` governance format
   - User override mechanism
3. **Run `/plan-2-v2-clarify`** to resolve: exact path (`docs/project-rules/harness.md` vs user's `docs/rules/harness.md`), whether plan-7 gets explicit harness validation, whether plan-0 should detect harness maturity
