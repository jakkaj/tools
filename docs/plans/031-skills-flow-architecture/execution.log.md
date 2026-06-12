# Execution log — plan-031 skills-flow-architecture

**Plan**: [skills-flow-architecture-plan.md](./skills-flow-architecture-plan.md) (v1.1.0, READY)
**Mode**: Simple — one phase, internally ordered A (pattern+lints) → B (Graph/Registry+fold+de-leak) → C (coach+views) → D (docs/verification/deploy)
**Testing**: Lightweight — greps are the verification layer (PL-10); no mocks
**Started**: 2026-06-12

---

## T000 — Harness pre-flight (`--event pre-implement`)

Seam: `/eng-harness-flow --event pre-implement --phase "Phase 1" --plan-dir "docs/plans/031-skills-flow-architecture" --json --prompt-optional=false`

Signals re-derived (router is stateless): `.harness/` ABSENT · governance doc (`.harness/engineering-harness.md`) ABSENT · `harness` CLI binary present on PATH · router installed at `~/.agents/skills/eng-harness-flow/SKILL.md`.

**Envelope**: `decision: noop` — adoption gate unmet (S2 governance + S4 boot rungs missing; CLI presence alone does not pass the gate). Boot verdict: **UNAVAILABLE** → not an error; standard testing applies for the whole phase. `--prompt-optional=false` honoured (no setup re-offer; the calm one-liner already fired at the session-start/post-spec seams). No further harness narration until the phase-end seam (T0zz).

---

## T001 — Baselines (the after-checks ARE these greps re-run — PL-10)

### (a) L1 leak census — exact AC2 lint pattern

Command (unique matching lines per file; pattern = AC2 verbatim):

```bash
for f in skills/SDD/the-flow/references/stages/*.md; do
  c=$( { grep -nE '/the-flow [0-9]|references/stages/[0-9]|\*\*Next routing\*\*|^## Next routing|^Next step|^## Next step' "$f" | cut -d: -f1; \
         grep -inE 'stage [0-9]+[a-z]?' "$f" | cut -d: -f1; } | sort -nu | wc -l ); echo "$(basename $f): $c"; done
```

| module | leak lines |
|---|---|
| 10-explore.md | 24 |
| 20-specify.md | 14 |
| 25-workshop.md | 20 |
| 30-architect.md | 19 |
| 35-adr.md | 10 |
| 50-phase-tasks.md | 21 |
| 60-implement.md | 9 |
| 61-implement-companion.md | 22 |
| 62-progress.md | 8 |
| 70-review.md | 11 |
| 80-merge.md | 5 |
| **TOTAL** | **163** |

> **Authoritative baseline = 163** (not the plan's indicative ≈147). The dossier's 147 was computed over a narrower pattern (commands + sibling paths + Next-routing lines only); the spec's AC2 lint pattern additionally counts case-insensitive `stage N` prose refs. PL-10 (Finding 04) anticipated exactly this — the grep is the truth. Target after T008: **0**.

### (b) Seam-invocation multiset (`grep -rc -- "--event <name>"` per file × 5 events)

| file | session-start | post-spec | pre-implement | phase-end | plan-complete |
|---|---|---|---|---|---|
| 00-routing.md | 2 | 3 | 2 | 2 | 1 |
| coach.md | 0 | 2 | 1 | 0 | 1 |
| getting-started.md | 4 | 5 | 4 | 3 | 4 |
| flight-plan.template.md | 0 | 1 | 1 | 1 | 1 |
| flight-plan.template.json | 0 | 1 | 1 | 1 | 1 |
| stages/10-explore.md | 1 | 0 | 0 | 0 | 0 |
| stages/20-specify.md | 0 | 2 | 0 | 0 | 0 |
| stages/25-workshop.md | 0 | 1 | 0 | 0 | 0 |
| stages/30-architect.md | 0 | 1 | 3 | 3 | 1 |
| stages/50-phase-tasks.md | 0 | 0 | 1 | 1 | 0 |
| stages/60-implement.md | 0 | 0 | 2 | 1 | 0 |
| stages/61-implement-companion.md | 0 | 0 | 3 | 2 | 0 |
| stages/70-review.md | 0 | 0 | 0 | 1 | 0 |
| stages/80-merge.md | 0 | 0 | 0 | 0 | 3 |
| SKILL.md | 0 | 0 | 0 | 0 | 0 |

**Expected delta after T007/T008 (AC6)**: stages/61 row disappears entirely (−3 pre-implement, −2 phase-end); stages/20 post-spec −2 and stages/25 post-spec −1 (re-homed to flow level by T005 — flow-level post-spec count rises accordingly); banner-marked views (getting-started) re-verified post-render rather than frozen. Everything else 1:1.

### (c) coach.md literal-command census (37 `/the-flow` lines + 6 `eng-harness-flow` lines)

- **Class 1 — narration blocks** (slot-convert): 120, 125, 127, 135, 141, 145, 150, 156, 163, 164, 165, 171, 174, 175, 182, 183, 190, 191, 198, 203, 205
- **Class 2 — rail-spec + handshake worked examples** (slot-convert; rendering *rules* stay byte-meaning-identical): 52, 53, 82, 214, 218, 225, 228
- **Class 3 — adoption-contract table** (verbs + render-at-write-time rule): 242, 243, 244, 245, 246, 247
- **Teaching/protocol prose** (bare `/the-flow` or placeholder grammar — not `<id> <verb>` literals): 17, 20, 101
- **Harness invocation strings (byte-frozen)**: 74, 142, 150, 170, 194, 198
- **Narration-block inventory (PL-14)**: 12 script blocks — `start`, `awaiting-1a`, `awaiting-1b`, `awaiting-2c`, `awaiting-backpressure`, `awaiting-3`, `awaiting-5`, `awaiting-6`, `awaiting-7`, `awaiting-8`, `complete`, `Optional branch mentions`. Block count must be unchanged after T009.

### (d) Diagram inventory (PL-11)

- `getting-started.md`: **2 mermaid fences** (lines 59, 125). `6c`/companion content at :31 (stage-table row), :36 (history prose — reword, don't delete), :75 (node `P6` label `(6c companion = +live review)`), :156/:176/:185 (walkthrough), :210/:212 (seam table). No banner on line 1.
- `flight-plan.template.md`: **1 mermaid fence** (line 9). Companion mentions :3/:17/:21/:24/:64/:69 are **`agents[].kind` semantics — they STAY** (Finding 07); no `6c` driver string in the .md (driver examples live in template.json:16 + schema:96 — verified at T007).

### (e) SKILL.md description

**971 chars** (≤1024 budget; matches the spec's claim). Re-measure after T006/T007 edits (fold shortens it).

### (f) Frozen-surface verbatim captures

PROCEED gate lines (source `80-merge.md`):
- `:913` → `Type "PROCEED" to begin merge execution, or "ABORT" to cancel.`
- `:1029` → `Next step: Review merge plan and type "PROCEED" to execute, or "ABORT" to cancel.`
- **Gate phrase frozen** (Finding 03): `type "PROCEED"` / `"ABORT"` wording on both lines; :1029's `Next step:` prefix may be reworded (it trips L1's `^Next step` marker).

State-write ownership (source `00-routing.md`, must survive byte-identical):

```markdown
## State-write ownership

- **Guided mode (the dispatch + this engine) is the ONLY writer** of `.the-flow-state.json`, `the-flow.json`, and `the-flow.md`.
- **Direct-jump stage modules NEVER write the-flow state.** A direct `/the-flow 6 implement …` behaves exactly like a direct `/plan-6` run did: it produces its stage artifacts and nothing else. The next guided invocation discovers those artifacts by existence (idempotency rule) and catches the state up — resume stays correct without dual writers.
- Stage modules own **their** artifacts (spec, plan, tasks, execution log, reviews); the engine never edits those.
```

---

## T002 — Pattern doc written

`docs/skills-pipeline/flow-architecture.md` created. Heading checklist verified by grep (`^## …`): The Sub-skill Template (:47) · Flow Definition (:111) · Registry (:140) · Graph (:166) · Command grammar (:186) · Narration slots (:207) · Ruleset (:226) · Lints (:241) · Worked example (:258) · Supersedes (:331). Contains: firm contract block (+ optional `**Delegates**` per D-F), forbidden content, constant Exit line verbatim, both sanctioned exceptions, permitted layouts + minimal flow skeleton, alias-table id+flag rule, render-at-write-time rule, R1–R8, L1–L6 table with D-C degradation, the triage mini-flow **plus one complete sub-skill file** (T014 needs a full worked sub-skill), supersession note naming the v1 guide by name and by content ("Next routing instruction" section).

**🔍 DISCOVERY (plan-level conflict found while designing L3)**: the byte-frozen `## State-write ownership` section of `00-routing.md` itself contains a `/the-flow 6 implement …` literal — AC7/AC13 ("zero flow-command literals in flow-level files outside grammar + views") and AC11 ("section survives verbatim") are jointly unsatisfiable as written. Neither validation pass caught this. **Resolution**: a generic lint escape hatch — `<!-- lint:allow-flow-commands -->` on its own line immediately **before** a section heading exempts that section from L3. The marker sits *outside* the frozen byte range (T001's capture starts at the heading), so AC11's grep still matches; the pattern doc documents the mechanism ("frozen-contract quotations — use sparingly"); AC13's census will record this single marker-exempted literal explicitly. Applied to 00-routing.md in T005.

---

## T003 — Lint script written + verified three ways

`scripts/check-flow-architecture.sh` (executable). Conventions: `set -euo pipefail`, `OK:`/`ERROR:`/`WARN:`, exit 0/1/2, `--help`. Flow token **derived** per dir (first backticked `/token` in `## Command grammar`, fallback dir name); table discovery by heading across non-view flow-level `.md` (fence-aware); sub-skill glob `references/stages/` or `stages/`.

1. **Baseline run** (`skills/SDD/the-flow`): exit 1 — **L1 FAIL, total 163, per-file identical to the T001 baseline** (24/14/20/19/10/21/9/22/8/11/5); L2 FAIL 11/11; **L3 warn-mode** (Registry not parsed — 117 warnings, a free census of flow-level literals); **L4 warn-mode**; L5 FAIL (`getting-started.md` no banner); L6 PASS (971 ≤ 1024). Matches the Done-When exactly.
2. **Negative self-test** (throwaway `scratch/lint-selftest/toyflow`, planted `/toyflow 2 pong` leak): token derived `/toyflow` from its grammar section — **L1 tripped (exit 1)**; leak removed → exit 0 with L5/L6 WARN-skips (D-C degradation on a minimal flow). Proves nothing is hardcoded to the-flow.
3. **Marker test**: a `/toyflow 2 pong` literal in a prose section → L3 ERROR (hardened mode — Registry parsed); same section preceded by `<!-- lint:allow-flow-commands -->` → clean. Fixture deleted after the run.

**Gotcha fixed mid-task**: `set -o pipefail` + a `grep -v` filter on an empty stream killed the script on the first leak-free sub-skill — caught by the self-test (the-flow baseline never exercised it because all 11 modules leak). `|| true` on the census pipeline.

---

## T004 — `just check-flow` recipe

Added after `skills-orphans` (justfile:358): `check-flow flow_dir="skills/SDD/the-flow"` → runs the script. Verified: `just check-flow` executes and fails with the expected baseline errors (exit 1 — correct mid-restructure; **not** wired into `ci` yet, T013 wires it once green).

**Phase A complete** (pattern + lints, zero the-flow edits). Phase B begins: source edits to the skill. Rollback anchor: commit `bb6de93` (user declined nothing — tag offer noted in the phase report; `git tag pre-flow-architecture bb6de93` remains available).

---

## T005 — Graph master in 00-routing.md

- `## Stage machine` (ASCII) + `## Routing table` **replaced by one firm `## Graph`** (state · evidence · edges-naming-**verbs** · decorations · **insight** — the kept Insight-source channel). The ASCII machine was a second edge-encoding in the same file; R1 says one owner — it's gone.
- Decorations absorbed: compact hints (4 ✓ rows), **post-spec seam** with byte-identical invocation string (`--event post-spec --spec <path>` ×3 at flow level — Graph rows awaiting-1b/awaiting-2c + § Harness seams), in-verb pre-implement/phase-end notes, **review skippable if a companion reviewed every commit** (the D7 edge decoration, landed here per AC4), **PROCEED gate** decoration on awaiting-8. Companion offer on awaiting-5 kept as `opt: **companion**` until T007 flips it.
- Literals slot-converted: fresh-start step 7 (explore/specify edges), state-contract `pending_command` example (render-at-write-time placeholder), prose refs "routing table" → "Graph". `## Must-see fields` table **untouched**; render rules untouched; § Harness seams untouched (stage-60/61 prose at :153–154 left for T007 by design).
- `<!-- lint:allow-flow-commands -->` marker added **above** `## State-write ownership` (T002 discovery); section verified **byte-identical** vs HEAD (`diff` clean).
- Lint after: `Graph parsed (references/00-routing.md): 11 state row(s)`; 00-routing.md L3 violations **22 → 0**; total L3 warns 117 → 95 (rest owned by T006/T009/T010).

---

## T006 — Registry master + Command grammar + alias table (SKILL.md)

- Stage table → firm **`## Registry`** (id · verb · module · consumes→produces · flags), declared **the master** (Graph master = 00-routing § Graph; getting-started = rendered view) — AC8's "exactly one master" satisfied. 11 rows kept (6c drops at T007).
- **`## Command grammar`** added — the single definition (grep count = 1); invariant #1 and the direct-jump/translation prose now reference it instead of carrying examples.
- Translation table: the `plan-6-v2-implement-phase-companion` row **rewritten** (slug appears exactly once — Finding 08) and `typed 6c or companion` row added — all targeting id+flag form **`6 implement --companion`**; zero `/the-flow`-prefixed strings in any table target column (AC13 census stays clean).
- Vocabulary: dispatch now speaks **sub-skill** (D-E); load-path prose updated (routing table → Graph).
- Lint after: token derived from SKILL.md grammar ✓; `Registry parsed: 11 row(s)`; **L4 closure green** (modules exist; Graph edges resolve in Registry) — warn-mode hardened exactly as D-C designed. L3 now hardened too; remaining L3 errors are the known T007 (SKILL.md:4 description) / T009 (coach) / T010 (getting-started, flight-plan.template.md) populations.
- Transient window noted (plan): alias targets a `--companion` mode that lands at T007 — source-only, deploy at T015.

---

## T007 — D7 fold complete

- `61-implement-companion.md` **deleted** (the leakiest module, 22 baseline leak lines). Its unique minih protocol moved into `60-implement.md` § **Companion mode (`--companion`)** — clearly fenced, gate sentence first, flag declared in Inputs + procedure flags; boot/brief/ping/skim/findings/debrief content preserved (commands verbatim); supersession stated as a *fact* with routing explicitly deferred to the Graph ("the flow's Graph carries the decoration") — no flow knowledge introduced.
- SKILL.md: description reworded (drops 6c, drops the literal command example — also clears its L3 hit; **967 chars**, was 971); Registry 6c row dropped (10 rows + dispatch); 6a row rewritten ("read by the implement verb after each task; owns the companion debrief"); invariant #7 → "The implement verb's companion mode (`--companion`) owns the companion protocol".
- 00-routing.md: awaiting-5 edge flipped to `→ **implement** (± its --companion mode — offer it here)`; stale "stage 60/61" seam prose → "the implement verb" (render rules :194–201 untouched).
- Flight-plan trio: schema:96 driver example → grammar-rendered companion-flag wording (`agents[].kind` semantics untouched); template.json driver → `/the-flow 6 implement --companion`, note de-commanded; template.md given a first-line 🔄 RENDERED banner (it IS generated from template.json — now L3 treats it as a view and checks its strings against the Registry).
- Verified: `grep 6c SKILL.md` → only the translation row; `grep "stage 60/61\|61-implement" 00-routing.md` → 0; 60's seam strings = baseline (pre-implement ×2, phase-end ×1); 61 absent on disk.

---

## T008 — De-leak complete: **L1 = 163 → 0** (10/10 sub-skills)

Every surviving module stamped to the firm Sub-skill Template: verb-named H1 (`# explore` … `# merge`), library boilerplate quote, contract block (`**Verb** **Purpose** **Consumes** **Flags** **Produces** **Side effects**`), constant Exit line (byte-identical ×10 — grep-verified). All `**Next routing**` fields, trailing Next-step blocks, cross-verb command examples, sibling paths, and `stage N` prose removed; usage examples rewritten in argument-only form ("flags are this verb's own — the flow renders the full command"); integration sections reworded to verb-names-in-prose (legal per the pattern's forbidden-content rule).

Key per-module notes:
- **60-implement**: `**Delegates**: progress — …; resolved via the Registry` (D-F); steps 6's sibling-path delegation rewritten to verb-name + Registry resolution; companion section already clean from T007.
- **62-progress**: dangling 61 references removed (header, Step 9 trigger prose, call-signature symmetry, harness note); debrief logic untouched — still keyed on `--companion-run-id`.
- **80-merge**: `:913` **byte-identical vs HEAD** (diff-verified); the old `:1029` line's `Next step:` prefix reworded to `Decision gate:` with the gate phrase `type "PROCEED" … "ABORT"` byte-intact (now :1033).
- **30-architect** keeps its 1 post-spec string (consumer-side provenance note — AC6's "everything else 1:1").

**Verification (lint run)**: `OK: L1: 0 leak lines across 10 sub-skill(s)` · `OK: L2: contract block + Exit line present in 10/10` · Exit-line file count = 10. **Seam multiset vs T001 baseline — exactly the documented delta**: 61's rows gone (−3 pre-implement, −2 phase-end), 20-specify post-spec 2→0, 25-workshop post-spec 1→0; every other per-file count 1:1 (session-start 10-explore 1; post-spec 30-architect 1; pre-implement 30:3/50:1/60:2; phase-end 30:3/50:1/60:1/70:1; plan-complete 30:1/80:3). Remaining lint errors are L3/L5 on coach + getting-started — owned by T009/T010.

---

## T009 — Coach slots: all three literal classes converted

Slot convention defined at the top of § Narration scripts: `{{render-edge: <state> → <verb> [flags]}}` expands at narration time via Graph row + Registry + Grammar; never printed raw; teaching prose may name verbs.

- **Class 1 (narration blocks)**: all 21 census lines converted — command literals → render-edge slots; verb names kept in prose. Companion narration reworded to the implement verb's `--companion` mode (awaiting-5 block offers both rendered forms).
- **Class 2 (rail-spec + handshake worked examples)**: :52–53 rail example, :82 harness-rail example, :214 handshake diagram → slot-converted; rail *rendering rules* untouched (byte-meaning-identical).
- **Class 3 (adoption table)**: `pending_command` column → **`pending verb`** naming verbs + flags only, with the explicit render-at-write-time rule in the intro (state always holds a runnable command; slots/bare verbs never stored). Print-then-offer step 1 now references the dispatch's § Command grammar instead of carrying placeholder grammar.

**Verification**: `grep -E '/the-flow [0-9]' coach.md` → **0**; narration-block count **12 = baseline** (PL-14); `eng-harness-flow` lines **6 = baseline** (invocation strings untouched).

---

## T010 — getting-started regenerated as banner-marked view

**Expected diagram delta (PL-11, written BEFORE the edits)**:
- Big Picture diagram (fence 1): node set {P1A,P1B,P2C,P3,P5,P6,P6A,P7,P8,R} and all edges **unchanged**; ONE label change — `P6` drops `(6c companion = +live review)` for `(--companion = +live review)`.
- Simple-vs-Full diagram (fence 2): **no change** (carries no companion content).
- Fence count stays **2**.
Non-diagram deltas: stage table 11 → 10 rows (6c row dropped; alias noted); history prose (:36) **reworded, not deleted** (companion history told in `--companion` vocabulary); walkthrough steps 5–6 re-rendered (`6 implement --companion`); Quick Reference 6c row folded into the implement row; post-spec seam attribution updated (flow-level Graph decoration, not stage-1b next-steps).

**Applied + verified**: banner on line 1 ✓; mermaid fences = 2 with exactly the declared P6-label delta ✓; L5 passes ✓; sub-skill vocabulary adopted. **Done-When deviation (recorded)**: `grep 6c` = 3, not 0 — all three are **alias documentation** (back-compat bullet :21, history prose :36, Quick Reference implement row :209), introduced by this regeneration to document the typed-`6c`/`companion` translation; zero *stale* hits (no stage row, no node, no walkthrough). This mirrors AC14's explicit carve-out ("alias documentation mentions allowed where explicitly describing the translation").

**🎉 Milestone: the lint went GREEN at T010** — `check-flow-architecture.sh skills/SDD/the-flow` → exit 0: L1 0/10 · L2 10/10 · Registry 10 rows · Graph 11 states · L3 clean · L4 closure holds · L5 banners ✓ · L6 ✓ · **0 warnings**. AC1's core condition satisfied; T013 re-runs it as the formal gate.

---

## T011 — External docs

- **CLAUDE.md**: layout comment (sub-skills); § Editing the SDD pipeline rewritten around Registry/Graph/sub-skills/grammar + `just check-flow` + plan-031 history line; § Adding or editing a skill gains the flow-authoring pointer to the pattern doc (closes the CF-01 regrowth vector at the place future authors start). Edited `CLAUDE.md` only — `AGENTS.md` symlink verified intact.
- **docs/skills-pipeline/README.md**: intro re-anchored on the pattern (+ link); `<id|name>` → `<id|verb>`; 6c row rewritten as the implement verb's `--companion` mode with the alias documented.
- **README.md**: audited — its the-flow mentions are conceptual narrative and all conform to the current Registry; no stale refs, no edit needed.
- **Verified**: `grep -n "61-implement-companion\|6c companion" CLAUDE.md docs/skills-pipeline/README.md README.md` → **0 stale hits** (AC14); pattern-doc links present in CLAUDE.md (×2) + pipeline README (AC9c).

---

## T012 — Resume verification (AC5): 12 slugs + 5 cases

### Read-through: every retired slug / typed alias → id+flag target → rendered command

| # | retired slug / typed alias | alias-table target | renders as (Grammar + Registry) |
|---|---|---|---|
| 1 | `plan-1a-v2-explore` | `1a explore` | `/the-flow 1a explore` |
| 2 | `plan-1b-v3-specify-and-clarify` | `1b specify` | `/the-flow 1b specify` |
| 3 | `plan-2-v2-clarify` | `1b specify` (§ Re-entry) | `/the-flow 1b specify` → module § Re-entry |
| 4 | `plan-2c-v2-workshop` | `2c workshop` | `/the-flow 2c workshop` |
| 5 | `plan-3-v3-architect` | `3 architect` | `/the-flow 3 architect` |
| 6 | `plan-3a-v2-adr` | `3a adr` | `/the-flow 3a adr` |
| 7 | `plan-5-v2-phase-tasks-and-brief` | `5 tasks` | `/the-flow 5 tasks` |
| 8 | `plan-6-v2-implement-phase` | `6 implement` | `/the-flow 6 implement` |
| 9 | `plan-6-v2-implement-phase-companion` | `6 implement --companion` | `/the-flow 6 implement --companion` |
| 10 | `plan-6a-v2-update-progress` | `6a progress` | `/the-flow 6a progress` |
| 11 | `plan-7-v2-code-review` | `7 review` | `/the-flow 7 review` |
| 12 | `plan-8-v2-merge` | `8 merge` | `/the-flow 8 merge` |
| + | typed `6c` / `companion` | `6 implement --companion` | `/the-flow 6 implement --companion` |

All 12 + the typed aliases resolve; flags carry over unchanged per the table's intro rule; targets are id+flag form (no stored command strings — AC13-safe).

### Five case walkthroughs (real state files read-only; one synthetic fixture)

1. **027-upstream-harness-improvements** — `current_stage: awaiting-8`, `pending_command: /plan-8-v2-merge --plan "docs/plans/027-…/upstream-harness-improvements-plan.md"`. Row 12 → `8 merge`; flags carry → renders `/the-flow 8 merge --plan "docs/plans/027-…/upstream-harness-improvements-plan.md"`. Graph `awaiting-8` row keys the resume (evidence: merge plan; decoration: typed-PROCEED gate). ✓
2. **029-eng-harness-switchover** — `awaiting-7`, `pending_command: /plan-7-v2-code-review --plan "…/eng-harness-switchover-plan.md"`. Row 11 → `7 review` + flags → `/the-flow 7 review --plan "…"`. Graph `awaiting-7`: evidence newest `reviews/*.md`; edges findings→**review** (stay) / clean→**merge**. ✓
3. **028-perplexity-deep-research** — `awaiting-8`, `pending_command` is **prose** ("commit to main (user must ask) — work-on-main-only repo, no PR flow"). Not a slug, not a command → translation is a **no-op** (exactly as AC5 rescoped); resume keys on `current_stage: awaiting-8` via the Graph; the idempotency rule re-prints the pending guidance verbatim. ✓
4. **Synthetic fixture** `scratch/test-flow-state-companion.json` — `awaiting-6`, `pending_command: /plan-6-v2-implement-phase-companion --phase "Phase 2: Hardening" --plan "scratch/demo-plan/demo-plan.md"`. Row 9 → `6 implement --companion`; flags carry → renders `/the-flow 6 implement --companion --phase "Phase 2: Hardening" --plan "scratch/demo-plan/demo-plan.md"`; next state write stores the rendered form (render-at-write-time). ✓
5. **031 itself** — `awaiting-6`, `pending_command: /the-flow 6 implement --plan "docs/plans/031-…/skills-flow-architecture-plan.md"` (current grammar). Translation no-op; the new Graph's `awaiting-6` row keys it: evidence `execution.log.md` (exists — this build); on the next guided turn the engine discovers it, narrates via the slotted coach, and offers the **review** edge rendered through Grammar+Registry. The first live run of the new Graph happens post-deploy (T015 note). ✓

---

## ⏸ PAUSE — mid-phase compaction seam (user-requested), 2026-06-12

**State at pause**: T000–T012 complete (13/17 task rows `[x]`); the lint is already **green** (exit 0) against the restructured source tree. **Remaining**: T013 (final verification sweep + wire `check-flow` into `ci`), T014 (variant-flow assembly check via fresh-context subagent), T015 (deploy + tidy — LAST), T0zz (phase-end harness seam). Nothing is committed this session beyond `bb6de93` (pre-build artifacts) — all skill/doc/script changes are uncommitted working tree.

**Resume protocol**: this is a *mid-phase* pause — `execution.log.md` existing does NOT mean the phase is done; the plan's task table still has 4 unchecked rows. After `/compact`, re-run `/the-flow` (or say "continue the build"): the implement turn resumes at **T013** using this log's baselines (PL-10 greps are all re-runnable). Deploy (T015) must stay last.

---
## T013 — Final verification sweep (the plan's G6 gate) — ALL GREEN

**Resumed post-compaction** (2026-06-12) per the ⏸ PAUSE protocol above.

1. **`just check-flow`** → exit 0, all six lints OK, 0 warnings (L1 0 leaks/10 sub-skills; L2 10/10; Registry 10 rows; Graph 11 rows; L3 clean; L4 closure; L5 banners; L6 within budget).
2. **`ci` wiring**: `justfile:217` → `ci: check-deps clean setup test test-uvx lint build check-flow`; `just --show ci` parses; recipe resolves.
3. **AC13 whole-skill literal census** (`grep -rnE '/the-flow ([0-9]|<verb>)'` across the skill tree): **53 literal-bearing lines, all authorized** —
   - 1 × Grammar definition (`SKILL.md:50`, § Command grammar — the single definition);
   - 1 × marker-exempted State-write ownership quotation (`00-routing.md:96`, under `<!-- lint:allow-flow-commands -->`);
   - 42 × banner-marked views (`getting-started.md` 41 lines, `flight-plan.template.md` 1 line);
   - 9 × worked-example **data** in the flight-plan contract (`flight-plan.template.json` 8 — `command:`/`driver:` fields modeling durable state, which stores rendered commands per the render-at-write-time rule; `flight-plan.schema.json:55` — schema description examples).
   - **0** in coach.md, **0** in any sub-skill (L1), **0** elsewhere in SKILL.md/00-routing. Alias-table targets are id+flag form (no carve-out needed) — as planned.
4. **Seam multiset, split two ways**:
   - (a) **Owning locations byte-1:1 minus the enumerated delta** — invocation *strings* extracted (`grep -ohE '/eng-harness-flow[^")`]*'`) and diffed vs HEAD for all six seam-bearing stage files + 00-routing.md + coach.md + both flight-plan templates: **identical in every file**. Per-file × 5-event counts match the T001 baseline exactly, minus: 20-specify post-spec 2→0 and 25-workshop post-spec 1→0 (re-homed to flow level at T005) and 61 deleted (−3 pre-implement, −2 phase-end). Event totals: session-start 7→7, post-spec 16→13, pre-implement 18→15, phase-end 15→13, plan-complete 12→12.
   - Note: whole-*line* diffs in 30-architect/70-review/80-merge are the intentional T008 de-leak edits to surrounding prose ("fired by `/the-flow 6 implement`" → "fired by the implement verb"); the frozen invocation strings inside those lines are byte-identical.
   - (b) **Views re-verified post-render**: getting-started.md counts 4/5/4/3/4 (recorded, not frozen — happen to equal baseline).
5. **PROCEED gate-phrase parity**: HEAD:913 (`Type "PROCEED" to begin merge execution, or "ABORT" to cancel.`) → now **:917, byte-identical** (sed-diff). HEAD:1029 → now **:1033** `Decision gate: Review merge plan and type "PROCEED" to execute, or "ABORT" to cancel.` — prefix reworded per Finding 03; the frozen gate phrase (`type "PROCEED" to execute, or "ABORT" to cancel`) byte-identical.
6. **Invariant #4**: SKILL.md "Never gate, score, or block. Workshops, backpressure, compaction, companions — all skippable…" byte-identical vs HEAD (line 73→80 shift only). Intentionally unchanged.
7. **L6 re-measure**: description = **967 chars** (≤1024; matches T006 measure).
8. **AC11 load-path read-through**: guided path reads 00-routing (Graph) + coach, loads exactly one sub-skill per accepted step, owns all state writes; direct jump resolves via Registry (id/verb each alone, mismatch → ask), reads only that sub-skill, no state writes, next guided run catches up by artifact existence; § Shared conventions lazy-pull kept as the pattern's sanctioned exception 1; State-write ownership section **byte-identical vs HEAD** (awk-section diff).

**Verdict**: nothing loops back to an owning task. T013 complete.

## T014 — Variant-flow assembly check (AC9b, anti-transcription) — PASS

**Brief** (invented; differs from the doc's `/triage` gather/diagnose/report on all three axes — flow-name, ids, verbs): *"Assemble a 3-verb flow called `/shipnote` (ids 10/20/30): **draft** turns a git log range into `notes-draft.md`; **polish** turns `notes-draft.md` into `notes-final.md`; **publish** turns `notes-final.md` into a posted release announcement (`announcement.md`)."*

**Protocol**: fresh-context subagent (agent id `a75f37c07dcbc2b30`, session transcript) received ONLY `docs/skills-pipeline/flow-architecture.md` + the brief; forbidden from reading anything else or running the lint. It chose the single-file dispatch layout (matching the doc's own scale guidance) and wrote 4 files under `scratch/mini-flow-test/shipnote/` (SKILL.md + stages/{draft,polish,publish}.md).

**Lint verdict**: `check-flow-architecture.sh scratch/mini-flow-test/shipnote` → **exit 0**. Token correctly derived (`/shipnote`); L1 0 leaks/3 sub-skills; L2 3/3; Registry 3 rows; Graph 4 rows; L3 clean; L4 closure; **L5 WARN-skip (no views — exactly per D-C)**; L6 OK. 1 warning, 0 errors.

**Doc-feedback from the assembly** (the real payoff of anti-transcription): 8 points reported.
- **Fixed now**: #7 — doc :325 claimed the example sub-skill "does not contain the strings `gather`, `report`", but its own Purpose line contains the substring "gathered" (the lint checks structural coupling — commands/ids/sibling paths — never bare vocabulary). Reworded :325 to structural-coupling terms; lint re-run on the-flow stays green.
- **Logged as refinement candidates (none blocked assembly)**: #1 Side-effects field — seams only or world-effects generally?; #2 gates needed under both load paths get double-encoded (Graph decoration + in-verb); #3 artifact directory unspecified; #4 flags invented by analogy; #5 frontmatter guidance thin; #6 "constant Exit line" vs whole-Exit-section reading (agent froze the whole section — satisfies both); #8 no example of dispatch routing prose (agent synthesized correctly from scattered statements).

Scratch materialization is AC9b-sanctioned; ships nothing.

## T015 — Deploy + tidy (LAST, per PL-12) — DONE

1. **`just install-skills-from-source`** → all skills reinstalled to the canonical store; `the-flow` ✓ (universal: Codex/OpenCode/Copilot; symlinked: Claude Code/Pi).
2. **PL-06 tidy**: `61-implement-companion.md` **not present** in `~/.agents/skills/the-flow/references/stages/` — this `npx skills` run replaced the skill directory wholesale, so the anticipated orphan never materialized (deviation in our favor; the `rm` guard ran and found nothing). Deployed stages dir = exactly the 10 source sub-skills.
3. **Tree parity**: `diff -r skills/SDD/the-flow ~/.agents/skills/the-flow` → byte-identical; `~/.claude/skills/the-flow` → symlink into canonical. **The restructured skill is live for the next skill load.**
4. **`just skills-orphans`**: nothing the-flow-related in any target (no retired `plan-*` slugs, no 61). Flagged entries are the external eng-harness family + hand-installed local-only skills (pack-code, shopping-hunter, …) — legitimate per the report's own note; not tidied (not ours to delete).
5. **`just doctor-skills`**: canonical store ✅ (24 skills); no legacy orphan stores; no dangling symlinks. One **pre-existing, out-of-scope** warning: `engineering-harness-setup` is a real dir in `~/.claude/skills` duplicating canonical (hand-install pre-dating this plan; fix line printed by doctor if ever wanted).

**AC12 satisfied.** Per the plan note: the next guided `/the-flow` turn of this session is the **first live run** of the new Graph + slotted coach — T012's 031-case walkthrough was the paper check; the live one happens at the phase-complete handoff.

## T0zz — Harness phase-end seam (`--event phase-end`) — calm noop, as expected

Seam: `/eng-harness-flow --event phase-end --plan-dir "docs/plans/031-skills-flow-architecture" --json --prompt-optional=false`

Signals re-derived (the router is stateless): router installed ✓; harness CLI resolves ✓ (S0); `.harness/` **absent** → S2 governance **absent**, S4 boot **absent** → adoption gate unmet → the engineering dispatch (phase-end → retro `--drain`/`--harvest`) is not entered; there is also no observe buffer to drain (no `.harness/temp/`).

**Envelope**: `decision: noop` (`requested: phase-end`, `actual: adopt-track`, `missing_rung: S2`). `--prompt-optional=false` honoured — no setup re-offer; identical posture to the T000 pre-implement seam. Best-effort, nothing blocks; standard testing carried the phase (which it did: the lint, byte-diffs, and grep censuses above).

---

## ✅ PHASE COMPLETE — all 17 task rows `[x]`, 14/14 ACs ticked

Build summary: pattern doc + lint script shipped and proven (T014 fresh-agent assembly, exit 0); the-flow restructured to the pattern (L1 163 → 0; lint exit 0, 0 warnings); frozen surfaces byte-verified (5 seam-event strings, PROCEED gate phrase, State-write ownership, invariant #4); coach slot-converted with PL-14 parity; getting-started regenerated as a banner-marked view; external docs updated; resume safety proven for all 12 retired slugs + typed aliases across 5 cases; deployed to the canonical store (tree byte-identical to source); `check-flow` wired into `ci`. Git untouched since `bb6de93` (read-only rule) — working tree holds the entire build, uncommitted.

## Review fix pass — REQUEST_CHANGES (reviews/review.md) → all 5 fix tasks applied

**FT-001 (HIGH, lint)**: L1's next-step detection was case-sensitive singular (`^Next step|^## Next step`) — `## Next Steps` (title-case plural) sailed through. The next-step/next-routing family moved into the case-insensitive grep: `\*\*next (routing|steps?)\*\*|^#{1,6} next (routing|steps?)\b|^next steps?\b`. **Honesty note**: both leaks predate this build and were equally invisible to the T001 baseline (same blind pattern) — the true baseline was ≈165, not 163, and "L1 = 0" at T008 was true only for the patterns then checked.

**FT-002 (HIGH, content)**: `10-explore.md:894` `## Next Steps` → `## Artifact Handoff` (deepresearch sub-steps kept as in-verb work; consumer notes neutralized — no successor verb named). `80-merge.md:980` `## Next Steps` → `## PROCEED/ABORT execution gate`; the resume block split out as `## Recovery commands`. Gate phrases intact: `Type "PROCEED" to begin…` now :917 **byte-identical** vs HEAD:913; `Decision gate: … type "PROCEED" to execute, or "ABORT" to cancel.` now :1035, frozen phrase unchanged.

**FT-003 (MEDIUM, lint)**: L3 extraction now catches id-led *and* verb-led literals. Verb-led candidates are flagged only when the token is a real Registry verb (guards prose like "…`/the-flow` and…"; silent in warn-mode per D-C). In banner-marked views the printed form must be id+verb with the pair validated against the Registry — id-only is now a violation. Caught for real: `getting-started.md:20`'s teaching literal `/the-flow implement …` — reworded to state the rule without a verb-led command string.

**FT-004 (MEDIUM, prose)**: `60-implement.md:233` "Suggest next step." → "Routing is the flow's job."; `20-specify.md:62` "fires in Next steps" → "is the parent flow's to fire once the spec is written"; `62-progress.md:83` sibling filenames (`60-implement.md`/`61-implement-companion.md`) → "the implement verb fires the phase-end seam; the merge verb fires plan-complete" (also fixes a factual error — plan-complete was never implement's); `coach.md:25–26` "stage 80's analysis" → "the merge verb's analysis", "Stage 60/61 (heavy build)" → "Implement (heavy build, plain or `--companion`)".

**FT-005 (MEDIUM, docs)**: spec AC13 + plan AC13 reworded to name all four authorized literal classes the census actually records (Grammar definition · banner-marked views · marker-exempt frozen quotations · durable-state worked-example data). Pattern doc § Forbidden content now states next-step matching is case-insensitive and plural-aware.

**Negative self-tests** (transient fixtures on a copy of the T014 `/shipnote` flow, removed after): planted `## Next Steps` in a sub-skill → **L1 ERROR**; verb-led `/shipnote polish` in a banner-marked view → **L3 ERROR (verb-led)**; id-only `/shipnote 20` in the same view → **L3 ERROR (missing the Registry verb)**. Clean fixture still passes (exit 0).

**Verification**: `just check-flow` → exit 0, 0 warnings. Re-review checklist grep (`^## Next Steps|\*\*Next steps?\*\*|Stage 60/61|61-implement-companion` across the skill) → 0 hits. Seam invocation strings byte-intact in every edited file (20-specify's diff vs HEAD = the documented T008 re-homing delta only). Redeployed: canonical store byte-identical to source.


---

## Flow close-out — 2026-06-12

**User**: "commit and push please" → "close our the flow"

- **Commit**: all plan-031 work (build + review fix pass + skill removals) committed directly to `main` as `b07ad7d` (36 files, +5510/−1890) and pushed — first explicit git ask since `bb6de93`.
- **Re-review**: waived by user — flow closed after the fix pass was verified (lint exit 0 / 0 warnings; planted-leak self-tests; gate phrases byte-intact; redeployed byte-identical).
- **Merge stage**: not executed — this repo works on main only (no branches), so stage 8 had nothing to merge; the PROCEED gate never applied. Recorded as an administrative close on the merge node.
- **Plan-complete harness seam** (`/eng-harness-flow --event plan-complete --plan-dir "docs/plans/031-skills-flow-architecture" --json --prompt-optional=false`): router installed, repo unprovisioned (no `.harness/`, no governance doc) → adoption gate S2/S4 missing → `decision: noop`, narrated calmly. Fifth and final seam of this flow; all five noop'd as the plan expected.
- **State**: `.the-flow-state.json` → `status: complete` (milestones 6/6, pending_command null); `the-flow.json` review + merge nodes → done; `the-flow.md` regenerated from JSON.

**FLOW CLOSED.**
