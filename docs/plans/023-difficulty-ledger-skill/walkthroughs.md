# Plan 023 — Anti-Vibe + Imagined-Session Walkthroughs

This file satisfies plan T029 (manual design-review walkthroughs). It is a **pre-dogfood** analytical pass — actual evidence-based verification waits for T028 (post-1-week dogfood). Here we walk the design against the 7 anti-vibes from workshop 001 and trace 3 imagined sessions through the implementation to confirm the architecture aligns with the vibe.

---

## Part 1 — Anti-vibe walkthroughs (workshop 001 § Anti-vibes 1-7)

For each anti-vibe, we name one **concrete piece of evidence** in the implementation that the design does NOT trigger it.

### Anti-vibe 1 — Nag-ware

*"Pop-ups, modal interruptions, please-take-action banners every time the agent thinks of something."*

**Mitigation**: `compound-1-track` is silent. Zero user-facing output during work. The ONE user surface (`compound-2-bubble`) fires at session end / logical pauses ONLY, with a single prompt, default action is `[a]ll-save` (pressing Enter dismisses the bubble cleanly). Empty buffer = silent (no prompt at all).

**Evidence in code/spec**: `skills/compound/compound-1-track/SKILL.md` § "What this skill does NOT do" — "No user-facing output. Not even a one-line 'logged' message." `skills/compound/compound-2-bubble/SKILL.md` § "Step 1 — Read the buffer" — "If the file is missing or empty → silent (no prompt). Exit."

### Anti-vibe 2 — Bureaucratic ceremony

*"6 maintenance files for 3 retros; index files that drift from source of truth; ritual updates that don't serve information."*

**Mitigation**: Workshop 006 § D4 KISS revision dropped ALL on-disk index files. The canonical tree is: `README.md` + `_buffers/` + `agents/<slug>/<date>/<retro>.retro.md`. Cross-cutting views are computed at read time by `compound-3-harvest` and printed to terminal. Source-of-truth retros only; nothing else persisted.

**Evidence**: `skills/compound/compound-3-harvest/SKILL.md` § "Step 5 — Print terminal view (NO on-disk writes)". `docs/compound/README.md` § "No on-disk index files". The implementation walks this — there are no `_LEDGER.md` / `_AGENT.md` / `_DAY.md` / `_PLAN.md` files in `docs/compound/`.

### Anti-vibe 3 — Silent journal

*"Entries land somewhere but no one reads them; the ledger becomes write-only."*

**Mitigation**: Three readers wired into the SDD pipeline:
1. `plan-1a-v2-explore` Subagent 7 reads `docs/compound/agents/**/*.retro.md` (in addition to legacy `## Discoveries & Learnings`) and surfaces relevant prior entries in every research dossier
2. `engineering-harness-v2`'s produced doc template auto-seeds `## Known Difficulties` from compound — every agent boot-read sees accumulated friction
3. `compound-3-harvest` is auto-fired at plan-6-companion FINAL-phase debrief + plan-8 merge end + plan-7 (rare path) — the user gets a curated view at long-horizon reflection moments without having to remember

**Evidence**: `skills/SDD/plan-1a-v2-explore/SKILL.md` § Subagent 7 search locations (now includes locations 4-5 — compound + back-compat). `skills/SDD/engineering-harness-v2/SKILL.md` § "Step 4a: Seed `## Known Difficulties` from the compound ledger". `skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md` § "At the FINAL phase's debrief".

### Anti-vibe 4 — Lecture mode

*"The skill tells the user what to do at length; explanations + warnings + reminders the user already knows."*

**Mitigation**: Prompts are terse. `compound-2-bubble`'s prompt is ≤8 lines (entries + action menu). One-line encoding hint per entry. No "did you know" preambles. No "you should consider" trailers. The `[a]ll-save` default means Enter is a one-keystroke escape.

**Evidence**: `skills/compound/compound-2-bubble/SKILL.md` § "Step 2 — Present the soft prompt" — the prompt template is literally one screen of text, mostly the entry list.

### Anti-vibe 5 — Auto-magic

*"The system applies fixes automatically; the user can't review or veto."*

**Mitigation**: `compound-2-bubble`'s `[e]ncode` action stages a diff in `scratch/encode-<id>-<target>.diff` — **nothing is auto-applied**. The user reviews and runs `git apply` (or doesn't) when ready.

**Evidence**: `skills/compound/compound-2-bubble/SKILL.md` § "`[e]ncode` — stage diffs" — "Nothing is auto-applied. The diff is staged for user review. This is the 'encode, don't document' mechanism — the encoding is in the diff, not in a doc."

### Anti-vibe 6 — Schema-driven UX

*"The UI surface is the schema; users see field names, validation errors, JSON-shaped widgets instead of plain language."*

**Mitigation**: The user only ever sees the `compound-2-bubble` prompt (one line per entry, kind/target prefix, English description) and `compound-3-harvest`'s terminal view (clusters, plain language). The JSON Schema is the wire format contract — invisible to the user.

**Evidence**: All user-facing prompts in `skills/compound/compound-2-bubble/SKILL.md` and `skills/compound/compound-3-harvest/SKILL.md` are English, not field-name-driven. The schema lives in `skills/compound/schemas/` and is consumed only by validators and round-trip helpers.

### Anti-vibe 7 — Agent over-introspection

*"The agent stops every minute to ask itself 'what could be better?'; introspection becomes the work instead of supporting it."*

**Mitigation**: Calibration targets `≤1 self-prompt per 5 minutes` AND `≤5 entries per session`. The task-boundary magic-wand reflex (Q6.1) fires **only when the buffer is empty** — if the agent has already observed something this task, it doesn't pile on. Calibration is soft (no enforcement gate), refined during dogfood per Compounding Test signal #1.

**Evidence**: `skills/compound/compound-1-track/SKILL.md` § "Calibration target" + § "Task-boundary heuristic" — explicit Q6.1 rule "If buffer is NON-EMPTY → do NOT additionally prompt".

---

## Part 2 — Imagined session walkthroughs (workshop 001 § Sessions A/B/C)

For each session, we trace the system's behavior end-to-end and confirm it matches the vibe.

### Session A — Code review with 2 difficulties

**Setup**: User runs `/plan-7-v2-code-review --plan ...` after `/plan-6-companion` completed. Phase had 12 commits across 4 files. Reviewer encounters 2 difficulties: (1) a finding that's hard to express in a single severity bucket, (2) a finding the spec implies but doesn't make explicit.

**Trace**:
1. plan-7 starts → sentinel check (`docs/compound/.disabled` absent) → buffer check (empty from prior bubble at plan-6-companion's final-phase debrief) → proceeds
2. During review, the reviewer hits difficulty #1 (severity ambiguity). `compound-1-track` fires silently — entry appended to `_buffers/claude-code.session-buffer.md`:
   ```yaml
   - id: DL-001
     kind: difficulty
     target: review-flow
     severity: degrading
     description: "Reviewer finding doesn't fit single severity bucket — both 'degrading' and 'annoying' apply"
   ```
3. Difficulty #2 (spec implication) → another silent track → DL-002 appended
4. plan-7 spot-checks 2-3 auto-firing skills for sentinel + buffer-check coverage (T030 audit folded in)
5. plan-7 finishes → auto-fire `/compound-2-bubble`:
   ```
   💡 compound — 2 entries from this session:

     1. [difficulty/review-flow] Reviewer finding doesn't fit single severity bucket
        → encode as: review-flow taxonomy clarification in plan-7 SKILL.md

     2. [difficulty/review-flow] Spec implication wasn't explicit (missing AC)
        → encode as: spec template prompt update

   [s/t/p/e/d/a]: ▮
   ```
6. User presses `[t]` for task — bubble emits:
   ```
   /plan-5 --fix --description "Reviewer finding doesn't fit single severity bucket" --target review-flow
   /plan-5 --fix --description "Spec implication wasn't explicit" --target spec-template
   ```
7. User pastes one. The other entry is also saved to a `.retro.md` (so the suggestion is captured even if not acted on now).
8. plan-7 also auto-fires `/compound-3-harvest` (preserved for rare solo `/plan-6` flow) — terminal view shows: "27 retros, 47 entries, 28 open. Top cluster: [tooling] grep slowness — 4 entries. ..."

**Vibe check**: ✓ silent during review (anti-vibe 1, 4); ✓ one prompt at end (anti-vibe 1); ✓ tersely written entries (anti-vibe 4); ✓ user-chosen action (anti-vibe 5); ✓ both entries saved regardless of action (anti-vibe 3 — no dropped data).

### Session B — Planning research with 1 magic-wand

**Setup**: User runs `/plan-1a-v2-explore "how does X work"`. Research dossier has 8 subagents; one of them returns inconclusive results despite the topic being covered in the codebase. The agent notices and self-prompts.

**Trace**:
1. plan-1a starts → sentinel check → buffer check (empty) → start-of-skill check: if ≥5 unharvested entries, print one-liner suggesting `/compound-3-harvest`. In this case there are 3 entries — no nudge. Proceeds.
2. Subagent 7 (Prior Learnings Scout) reads `docs/plans/*/...` AND `docs/compound/agents/**/*.retro.md` AND `docs/retros/*.md` (back-compat). Surfaces 3 prior learnings in the dossier's PL-01 through PL-03 entries.
3. Subagent 5 (Interface & Contract Analyst) returns inconclusive. The orchestrator (plan-1a) notices the inconclusive result + the magic-wand reflex fires AT a natural pause (after subagent batch completes, buffer is empty):
   ```yaml
   - id: MW-001
     kind: magic-wand
     target: tooling
     description: "If Subagent 5 had a fallback search via the registry, it wouldn't return inconclusive on this topic"
   ```
4. plan-1a writes the research dossier with PL findings + the compound-activity one-liner ("✓ 3 entries surfaced from compound — 1 encoded, 2 open").
5. plan-1a finishes → auto-fire `/compound-2-bubble`:
   ```
   💡 compound — 1 entry from this session:

     1. [magic-wand/tooling] Subagent 5 fallback search via registry
        → encode as: edit plan-1a-v2-explore SKILL.md Subagent 5 spec

   [s/t/p/e/d/a]: ▮
   ```
6. User presses Enter ([a]ll-save default). The entry is wrapped in a universal retro envelope and written to `docs/compound/agents/claude-code/2026-05-20/T14-30-22Z-a8f3.retro.md` with `plan_id: <current-plan>`.

**Vibe check**: ✓ silent buffer (anti-vibe 1); ✓ readers see prior compound entries (anti-vibe 3); ✓ magic-wand fires only at natural pause when buffer empty (anti-vibe 7); ✓ Enter = save default — one keystroke (anti-vibe 4); ✓ entry persisted, not lost (anti-vibe 3).

### Session C — Typo fix with no entries

**Setup**: User runs `/plan-6-v2-implement-phase` for a 1-task phase that's just fixing a typo in AGENTS.md. No friction, no surprises.

**Trace**:
1. plan-6 starts → sentinel check → buffer check (empty) → proceeds
2. During work: agent edits one line in AGENTS.md. No tool calls >30s; no zero-result searches; no retries; no backtracks; no test/build failures. No magic-wand reflex (would only fire AT task boundary AND when buffer empty — buffer IS empty but the work is trivial enough that there's nothing wishful to log).
3. End-of-phase: `compound-1-track` was never called. Buffer is still empty.
4. plan-6 auto-fires `/compound-2-bubble` at end-of-phase → bubble reads empty buffer → **silent exit** (no prompt).
5. plan-6 reports phase complete. User sees no compound output at all.

**Vibe check**: ✓ no friction means no compound noise (anti-vibe 1, 2, 4); ✓ low-friction sessions look identical to a pre-compound world (anti-vibe 1 — invisible until something happens); ✓ this is the "silent until interesting" promise made literal.

---

## Summary

| Anti-vibe | Triggered? | Evidence file |
|-----------|------------|---------------|
| 1. Nag-ware | No | compound-1-track SKILL.md (silent producer) + compound-2-bubble SKILL.md (empty = silent) |
| 2. Ceremony | No | workshop 006 § D4 KISS revision (no on-disk indexes) |
| 3. Silent journal | No | plan-1a Subagent 7 reads compound + engineering-harness.md § Known Difficulties seed + auto-fire harvest sites |
| 4. Lecture mode | No | compound-2-bubble SKILL.md (terse prompt template, ≤8 lines) |
| 5. Auto-magic | No | compound-2-bubble [e]ncode (stages diff in scratch/; never applies) |
| 6. Schema-driven UX | No | all user prompts are English, not schema-shaped |
| 7. Over-introspection | No | compound-1-track SKILL.md (≤1/5min calibration + Q6.1 task-boundary-only-when-empty rule) |

| Session | Behavior matches vibe? | Notes |
|---------|------------------------|-------|
| A (review, 2 difficulties) | ✓ | Bubble fires; user picks `[t]`; tasks emitted; entries persisted |
| B (research, 1 magic-wand) | ✓ | Bubble fires; user presses Enter ([a]ll-save); entry persists to plan-scope file |
| C (typo fix, no entries) | ✓ | Bubble silent; user sees no compound output |

**Pre-dogfood verdict**: design walks cleanly against all 7 anti-vibes and the 3 canonical session shapes. Evidence-based verification (T028) will run after the 1-week dogfood window.

**Failure modes to watch during dogfood**:
- If anti-vibe 7 (over-introspection) triggers despite the Q6.1 rule, calibration needs tightening
- If anti-vibe 3 (silent journal) triggers because users dismiss every bubble, the encoding hints need iteration (workshop 001 D5 framing)
- If anti-vibe 5 (auto-magic) is breached anywhere, that's a bug — no compound skill should auto-apply diffs

These watch-items become the T028 verification checklist's failure-detection lens.
