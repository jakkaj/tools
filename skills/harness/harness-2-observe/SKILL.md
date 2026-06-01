---
name: harness-2-observe
description: |
  Observe stage of the harness loop (Boot → Do Work → Observe → Retro). Silent producer: called silently during a session whenever friction or insight arises — logs one entry per call to `docs/harness/_buffers/<agent>.session-buffer.md`. No user output during work; the only user surface is `harness-3-retro --drain` at session end. Tracks compounding value — every difficulty catalogued is a gift to your future self. Calibrated for ≤1 self-prompt per 5 minutes and ≤5 entries per session (anti-vibe 7 mitigation).
---

# harness-2-observe

The **Observe** stage of the harness loop. Runs silently during work, capturing friction to the per-agent session buffer so the next session is cheaper. Never prompts the user.

> **Track compounding value.** Each entry logged here is not overhead — it is the mechanism by which the harness compounds. The meta-question is never whether one task succeeded; it is whether the development infrastructure gets cheaper, safer, and clearer every iteration. Every difficulty catalogued is a gift to your future self.

## When to fire

Two firing modes — both silent, both append-only:

### A. Agent-observed friction (during work)

The agent calling this skill notices something worth logging. Concrete trigger heuristics:

- A tool call took >30 seconds and the agent was waiting on it
- A search returned zero results when the agent expected matches
- The agent had to retry the same operation more than once
- The agent backtracked from a wrong assumption
- A test or build failure required guesswork to interpret
- The agent had to infer runtime behavior because no smoke path, screenshot, log, trace, or health evidence was available
- The agent had to eyeball an architecture, dependency, security, schema, or data constraint that a deterministic check could have proved
- `harness-1-boot` reported a missing or "not declared" signal-readiness dimension that affected the current work
- The agent caught itself muttering "if only there were a …" (the magic-wand reflex)

When any of these triggers, call this skill with one entry.

### B. Self-prompt at natural pauses (magic-wand reflex)

At a natural pause in the work — between phases, after completing a discrete task, after a long search — the agent asks itself: *"If I had a magic wand right now, what would I change?"* If the answer is concrete, log it. If nothing comes to mind, **don't force it**.

> **Agents are real users.** When you (the agent) hit friction or wish for a tool that doesn't exist, that is not noise — it is the most honest feedback the harness gets. A magic-wand wish is a feature request from a real user of the infrastructure. Treat it that way: log it so the loop can compound it.

**Calibration target** (anti-vibe 7 — over-introspection):

- Self-prompt rate: **≤ 1 per 5 minutes** of clock time
- Entries per session average: **≤ 5**

These are soft targets, not enforced. The Compounding Test signal at the 1-week mark will tell us if they need adjustment.

## Sentinel check

If `docs/harness/.disabled` exists → silently no-op. Do not log, do not prompt, do not error. The opt-out is absolute.

## Buffer path

`docs/harness/_buffers/<agent>.session-buffer.md`

Where `<agent>` is the calling CLI's slug (lowercase kebab-case):

- Claude Code → `claude-code.session-buffer.md`
- Codex → `codex.session-buffer.md`
- GitHub Copilot → `github-copilot.session-buffer.md`
- OpenCode → `opencode.session-buffer.md`
- Pi → `pi.session-buffer.md`
- Minih companion → `<companion-slug>.session-buffer.md` (e.g. `plan-6-companion.session-buffer.md`)

Per-agent buffer means two simultaneous agents on the same repo don't trample each other's entries.

If the buffer file doesn't exist, create it (touch). If `_buffers/` doesn't exist, **no-op gracefully** — this skill never scaffolds. A missing `docs/harness/` ledger tree means the harness ledger isn't provisioned yet; provisioning it is the separate engineering-harness setup effort's job, not the producer's. Report `UNAVAILABLE` and exit silently.

## Entry format

Append-only YAML block per entry (one entry per call). Each entry conforms to the universal Entry schema (`docs/harness/schemas/retro.schema.json` § `$defs.Entry`):

```yaml
- id: DL-001                          # Required. <PREFIX>-<3+ digit number>. Per-buffer counter.
  kind: difficulty                    # Required. Enum: difficulty | magic-wand | gift | insight | coordination | improvement-suggestion | confusion
  description: "grep on src/ took 47s — should use ripgrep."   # Required. ≥10 chars.
  target: tooling                     # Optional. project | tooling | plan | skill | doc | infra | minih | coordination | (custom)
  severity: degrading                 # Optional. Recommended for kind=difficulty. blocking | degrading | annoying.
  workaround: "Used grep -r -I to skip binaries."              # Optional. What you did to get past it.
  suggested_encoding: "justfile recipe wrapping ripgrep"       # Optional. Free-text hint for harness-3-retro --drain's encoding flow.
  system:
    compound:
      status: open                    # Initial status.
      source: agent-self              # user | agent-self
      first_seen_at: "2026-05-18T10:15:00Z"
```

### Schema-safe signal/back-pressure encodings

Do not invent new `kind` values such as `signal-gap`, `sensor-gap`, or `weak-back-pressure`. Encode missing proof with existing kinds plus explicit targets:

```yaml
- id: DL-003
  kind: difficulty
  target: project-sensor
  severity: degrading
  description: "Had to infer whether the website rendered correctly because no smoke path or screenshot evidence was available."
  workaround: "Read the code path manually."
  suggested_encoding: "add smoke command or visual evidence capture"
  system:
    compound:
       status: open
       source: agent-self
       first_seen_at: "2026-05-30T07:45:00Z"
```

```yaml
- id: SUGG-002
  kind: improvement-suggestion
  target: architecture-fitness
  description: "Add a deterministic dependency-direction or CodeQL check so architecture regressions fail before review."
  suggested_encoding: "architecture check recipe"
  system:
    compound:
       status: open
       source: agent-self
       first_seen_at: "2026-05-30T07:47:00Z"
```

Use targets such as `project-sensor`, `runtime-inspectability`, `architecture-fitness`, `security`, `schema`, or `tooling` to make the missing signal visible to `harness-3-retro --harvest` without changing the schema.

### ID generation

Per-buffer counter, scoped within the buffer file:

- Scan the existing buffer for IDs matching the chosen prefix (e.g. `DL-\d+`)
- Find the highest number, add 1, zero-pad to ≥3 digits
- Recommended prefixes (from workshop 005 § D6):
  - `DL` — difficulty
  - `MW` — magic-wand
  - `GFT` — gift
  - `INS` — insight
  - `COORD` — coordination
  - `SUGG` — improvement-suggestion
  - `CONF` — confusion

Counters are independent per kind. A buffer with `DL-001`, `DL-002`, `MW-001` is valid.

## Append, never rewrite

The buffer is append-only. Each call appends a single YAML block. The skill never reads existing entries to validate or modify them. `harness-3-retro --drain` is the consumer that reads + drains.

## Task-boundary heuristic

Per spec Q6.1: at the end of a discrete task (phase complete, file written, test passed), check the buffer:

- **If buffer is EMPTY** → fire the magic-wand self-prompt (per § "B. Self-prompt at natural pauses"). Nothing has been observed this task; ask if there's a magic-wand worth logging.
- **If buffer is NON-EMPTY** → do NOT additionally prompt. The existing entries are sufficient signal; piling on a magic-wand check now is over-introspection (anti-vibe 7).

The point is: ask once per natural pause, only when otherwise silent.

## What this skill does NOT do

- **No user-facing output**. Not even a one-line "logged" message. The buffer is silent; the bubble at session end is the only surface.
- **No fix application**. Entries describe friction; encoding happens via `harness-3-retro --drain [e]ncode` (stages a diff for review).
- **No prompting the user mid-session**. Bubble-up is exclusively at session end.
- **No buffer reading or curation**. That's `harness-3-retro --drain` (drain) and `harness-3-retro --harvest` (curate).
- **No sensor implementation**. This skill logs missing proof. It never creates product-specific smoke tests, CodeQL queries, schema checks, or setup artifacts.

## Edge cases

- **Sentinel mid-write**: if `.disabled` appears between two calls, subsequent calls no-op. Already-written entries stay until next bubble.
- **Concurrent agents**: per-agent buffer files mean no collision. Two agents call harness-2-observe simultaneously → two different files.
- **Malformed entry**: if the agent constructs an invalid entry (missing required field), the write fails. Better to skip the entry than to corrupt the buffer.
- **Buffer file missing**: create it (touch). The first entry initializes it. If `_buffers/` is also missing, **no-op gracefully** (report `UNAVAILABLE`, exit silently) — the producer never auto-scaffolds; provisioning `docs/harness/` is the separate engineering-harness setup effort's job.
- **Inference gap discovered late**: log the missing signal as the friction, not just the symptom. Prefer "no smoke/evidence path proved X" over "I was confused", because the former is encodable into deterministic back-pressure.

## Producer-side annotation

`system.compound.source` distinguishes:

- `user` — the user said something the agent captured (rare; most input is task-driven)
- `agent-self` — the agent observed it itself

Default to `agent-self` unless the user explicitly muttered the friction.

## References

- Workshop 001 — Self-improvement vibe (§ Anti-vibe 7 over-introspection; § Trigger heuristics; § Magic-wand reflex)
- Workshop 005 — Universal retro contract (§ Entry schema; § D5 entry kinds; § D6 identity)
- Workshop 006 — Compound folder layout (§ D3 buffer location)
- Spec § Acceptance Criteria #4, #5, #6, #23
- Spec § Q6.1 (task-boundary check only when buffer empty)
