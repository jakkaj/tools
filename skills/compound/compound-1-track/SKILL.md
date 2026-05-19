---
name: compound-1-track
description: |
  Silent producer-side skill for the compounding-value loop. Called silently during a session whenever friction or insight arises — logs one entry per call to `docs/compound/_buffers/<agent>.session-buffer.md`. No user output during work; the only user surface is `compound-2-bubble` at session end. Calibrated for ≤1 self-prompt per 5 minutes and ≤5 entries per session (anti-vibe 7 mitigation).
---

# compound-1-track

The producer side of the compound loop. Runs silently. Writes entries to the per-agent session buffer. Never prompts the user.

## When to fire

Two firing modes — both silent, both append-only:

### A. Agent-observed friction (during work)

The agent calling this skill notices something worth logging. Concrete trigger heuristics:

- A tool call took >30 seconds and the agent was waiting on it
- A search returned zero results when the agent expected matches
- The agent had to retry the same operation more than once
- The agent backtracked from a wrong assumption
- A test or build failure required guesswork to interpret
- The agent caught itself muttering "if only there were a …" (the magic-wand reflex)

When any of these triggers, call this skill with one entry.

### B. Self-prompt at natural pauses (magic-wand reflex)

At a natural pause in the work — between phases, after completing a discrete task, after a long search — the agent asks itself: *"If I had a magic wand right now, what would I change?"* If the answer is concrete, log it. If nothing comes to mind, **don't force it**.

**Calibration target** (anti-vibe 7 — over-introspection):

- Self-prompt rate: **≤ 1 per 5 minutes** of clock time
- Entries per session average: **≤ 5**

These are soft targets, not enforced. The Compounding Test signal at the 1-week mark will tell us if they need adjustment.

## Sentinel check

If `docs/compound/.disabled` exists → silently no-op. Do not log, do not prompt, do not error. The opt-out is absolute.

## Buffer path

`docs/compound/_buffers/<agent>.session-buffer.md`

Where `<agent>` is the calling CLI's slug (lowercase kebab-case):

- Claude Code → `claude-code.session-buffer.md`
- Codex → `codex.session-buffer.md`
- GitHub Copilot → `github-copilot.session-buffer.md`
- OpenCode → `opencode.session-buffer.md`
- Pi → `pi.session-buffer.md`
- Minih companion → `<companion-slug>.session-buffer.md` (e.g. `plan-6-companion.session-buffer.md`)

Per-agent buffer means two simultaneous agents on the same repo don't trample each other's entries.

If the buffer file doesn't exist, create it (touch). If `_buffers/` doesn't exist, the agent should run `compound-0-setup` first (the producer should not silently create scaffold).

## Entry format

Append-only YAML block per entry (one entry per call). Each entry conforms to the universal Entry schema (`skills/compound/schemas/retro.schema.json` § `$defs.Entry`):

```yaml
- id: DL-001                          # Required. <PREFIX>-<3+ digit number>. Per-buffer counter.
  kind: difficulty                    # Required. Enum: difficulty | magic-wand | gift | insight | coordination | improvement-suggestion | confusion
  description: "grep on src/ took 47s — should use ripgrep."   # Required. ≥10 chars.
  target: tooling                     # Optional. project | tooling | plan | skill | doc | infra | minih | coordination | (custom)
  severity: degrading                 # Optional. Recommended for kind=difficulty. blocking | degrading | annoying.
  workaround: "Used grep -r -I to skip binaries."              # Optional. What you did to get past it.
  suggested_encoding: "justfile recipe wrapping ripgrep"       # Optional. Free-text hint for compound-2-bubble's encoding flow.
  system:
    compound:
      status: open                    # Initial status.
      source: agent-self              # user | agent-self
      first_seen_at: "2026-05-18T10:15:00Z"
```

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

The buffer is append-only. Each call appends a single YAML block. The skill never reads existing entries to validate or modify them. `compound-2-bubble` is the consumer that reads + drains.

## Task-boundary heuristic

Per spec Q6.1: at the end of a discrete task (phase complete, file written, test passed), check the buffer:

- **If buffer is EMPTY** → fire the magic-wand self-prompt (per § "B. Self-prompt at natural pauses"). Nothing has been observed this task; ask if there's a magic-wand worth logging.
- **If buffer is NON-EMPTY** → do NOT additionally prompt. The existing entries are sufficient signal; piling on a magic-wand check now is over-introspection (anti-vibe 7).

The point is: ask once per natural pause, only when otherwise silent.

## What this skill does NOT do

- **No user-facing output**. Not even a one-line "logged" message. The buffer is silent; the bubble at session end is the only surface.
- **No fix application**. Entries describe friction; encoding happens via `compound-2-bubble [e]ncode` (stages a diff for review).
- **No prompting the user mid-session**. Bubble-up is exclusively at session end.
- **No buffer reading or curation**. That's `compound-2-bubble` (drain) and `compound-3-harvest` (curate).

## Edge cases

- **Sentinel mid-write**: if `.disabled` appears between two calls, subsequent calls no-op. Already-written entries stay until next bubble.
- **Concurrent agents**: per-agent buffer files mean no collision. Two agents call compound-1-track simultaneously → two different files.
- **Malformed entry**: if the agent constructs an invalid entry (missing required field), the write fails. Better to skip the entry than to corrupt the buffer.
- **Buffer file missing**: create it (touch). The first entry initializes it. If `_buffers/` is also missing, suggest the user run `compound-0-setup` (the producer doesn't auto-scaffold).

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
