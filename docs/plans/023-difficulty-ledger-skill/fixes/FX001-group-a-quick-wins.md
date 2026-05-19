# Fix FX001: Group A — Quick Wins from Post-Launch Review

**Created**: 2026-05-18
**Implemented**: 2026-05-19
**Status**: Implemented (awaiting commit + closure retro)
**Plan**: [023-difficulty-ledger-skill](../difficulty-ledger-skill-plan.md)
**Source**: Workshop 007 § Group A (review fixes RV-001, RV-002, RV-003 from external compound + harness skill-pack review)
**Domain(s)**: `engineering-harness` (modify) + `compound` (modify) + `scripts` (extend)

---

## Problem

External review of the just-shipped compound + engineering-harness skill family surfaced 7 concrete fixes (workshop 007). Three of them are cheap, aligned with our principles, and immediately shippable as a single batch:

1. **Confirmed bug**: `engineering-harness-v2`'s boot-time relevance filter admits only `engineering-harness | tooling | infra` targets, but fixture entries emit `build | config | tooling | minih | project`. Three of five fixture targets get silently dropped from Known Difficulties seeding — boot-time agents miss the most actionable friction. Verified at `skills/SDD/engineering-harness-v2/SKILL.md:218` vs `grep "target:" skills/compound/schemas/fixtures/*.retro.md`.

2. **Missing stable read interface**: `compound-3-harvest` computes a useful view transiently and prints it; there is no machine-readable surface, so future skills, hooks, or `just` recipes can't consume the loop status. The KISS rule from workshop 006 (no on-disk index) is right, but it shouldn't preclude a read-time `--json` render.

3. **"Encoded" is ambiguous**: When `compound-2-bubble [e]ncode` stages a diff into `scratch/encode-*.diff`, reviewers see the patch but have to infer how to verify it. The action means "we wrote a patch" rather than "we changed the loop AND can prove it."

## Proposed Fix

Three coordinated changes shipping as one batch:

1. **RV-001**: Widen the target filter to `engineering-harness | tooling | infra | build | config | dependencies | env | auth | tests | observe`.
2. **RV-002**: Document a `--json` output schema for `compound-3-harvest`; add `scripts/compound-value.sh` (stdin JSON pretty-printer); add `just compound-value` recipe.
3. **RV-003**: Add a `## Validation` footer template to the `compound-2-bubble [e]ncode` flow so staged diffs always include Run / Expected / Lifecycle blocks.

All three preserve the workshop 006 KISS rule (no on-disk index — view computed at read time and printed). All three are additive — no schema bump, no breaking change. Group B (RV-004, RV-005) and Group C (RV-006, RV-007) are tracked separately and ship as FX002/FX003 later.

---

## Domain Impact

| Domain | Relationship | What Changes |
|--------|-------------|-------------|
| engineering-harness | modify | Boot-time relevance filter widens — more compound entries surface in `## Known Difficulties` |
| compound | modify | `compound-3-harvest` adds `--json` flag spec; `compound-2-bubble` adds validation footer to encode-flow template |
| scripts | extend | New `scripts/compound-value.sh` — stdin JSON pretty-printer, no state |
| justfile | extend | New `compound-value` recipe wiring the script |

**No inter-domain contract changes.** No schema-version bump (compound retro schema stays at v1.0.0; FX002 bumps to v1.1.0). No new dependencies. However, the engineering-harness-v2 **output surface** does grow — `## Known Difficulties` will now show entries for 7 additional target classes (build/config/dependencies/env/auth/tests/observe). Downstream consumers that pattern-match on the old 3-target output should re-baseline.

---

## Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | FX001-1 | Expand the boot-time relevance filter from `engineering-harness \| tooling \| infra` to `engineering-harness \| tooling \| infra \| build \| config \| dependencies \| env \| auth \| tests \| observe`. Update **L156** (the HTML comment listing the filter targets) AND **L218** (the Step 4a algorithm bullet — second clause of the relevance filter rule). | engineering-harness | `/Users/jordanknight/github/tools/skills/SDD/engineering-harness-v2/SKILL.md` | See Acceptance § FX001-1 below (mktemp + fixture-copy + grep). | Workshop 007 RV-001 — **confirmed bug**. Closure retro `RV-001` written per Compound Tracking § Canonical retro shape. |
| [x] | FX001-2 | (a) Document the `--json` output schema in `compound-3-harvest/SKILL.md` verbatim per workshop 007 § RV-002 (fields: `schema_version`, `generated_at`, `retros`, `entries.{total/open/suggested/encoded/wontfix/dismissed/escalated/stale}`, `top_clusters[].{kind,target,count,oldest,representative}`, `harness.{maturity,last_validation,boot_ms,verdict}`). (b) Create `scripts/compound-value.sh` with this rendering contract: reads JSON on stdin via `jq`; emits **exactly 6 lines** = `Harness: <maturity>, last validation <verdict-upper>, boot <boot_ms÷1000>s` / `Compound: <total> entries — <open> open, <encoded> encoded, <suggested> suggested` / blank / `Top friction:` / top-2 clusters (truncate `representative` at 60 chars, format `  N. <target>/<kind> — <count> entries — <representative>`) / `Next encoding: <auto-pick-from-top-cluster-or-fallback>`. Missing-fields default: harness→`Unknown`, empty clusters→print `Top friction: (none)`. (c) Add `compound-value` recipe to `justfile` that runs `cat | scripts/compound-value.sh`. (d) Append a line to the `help` recipe's printed listing under the Skills block: `just compound-value         - Render compound loop status from --json (stdin)`. (e) Run `./scripts/sync-to-dist.sh` after the SKILL.md and script edits land so `src/jk_tools/scripts/compound-value.sh` exists in the distribution mirror. | compound + scripts + justfile | `/Users/jordanknight/github/tools/skills/compound/compound-3-harvest/SKILL.md` (modify) ; `/Users/jordanknight/github/tools/scripts/compound-value.sh` (new, chmod +x) ; `/Users/jordanknight/github/tools/justfile` (modify) ; `/Users/jordanknight/github/tools/src/jk_tools/scripts/compound-value.sh` (auto-synced) | See Acceptance § FX001-2. Plus: `just help \| grep -q compound-value` and `ls src/jk_tools/scripts/compound-value.sh` both succeed. | Workshop 007 RV-002. Q2 RESOLVED → option (b) stdin pretty-printer (cross-CLI portable). Closure retro `RV-002` written. Preserves workshop 006 KISS rule (no persisted index — view computed at read time). |
| [x] | FX001-3 | Add a `## Validation` footer template to the `[e]ncode` action section in `compound-2-bubble/SKILL.md`. Every staged diff at `scratch/encode-<id>-<target>.diff` must end with a literal block of the form: `## Validation\n\nRun:\n  <validation command>\n\nExpected:\n  <observable outcome>\n\nCompound lifecycle:\n  <id> transitions <system.compound.status from> → <system.compound.status to> when this diff lands.` The skill prompts the user (or fills automatically from the buffer entry's `suggested_encoding` field) for the three sub-section values. | compound | `/Users/jordanknight/github/tools/skills/compound/compound-2-bubble/SKILL.md` | See Acceptance § FX001-3 (seed buffer + invoke bubble + grep). | Workshop 007 RV-003. Closure retro `RV-003` written. Purely additive to encode-flow template. Note: the footer documents the lifecycle transition that compound-3-harvest will later execute (`suggested` → `encoded` via the `system.compound.status` field). |

---

## Workshops Consumed

- **Primary**: [`workshops/007-post-launch-review-fixes.md`](../workshops/007-post-launch-review-fixes.md) — Group A authoritative source (RV-001 / RV-002 / RV-003 blocks)
- **Referenced**: [`workshops/006-compound-folder-layout.md`](../workshops/006-compound-folder-layout.md) — KISS "no on-disk index" rule that RV-002 must preserve
- **Referenced**: [`workshops/005-universal-retro-contract.md`](../workshops/005-universal-retro-contract.md) — universal envelope + the `system.compound.*` namespace extension where `status` and `resolved_by` actually live (Entry root rejects them per `additionalProperties: false`)

---

## Acceptance

- [ ] **FX001-1**: Stage the 5 fixtures into a temp compound ledger, run engineering-harness-v2 against them, verify boot-relevant targets surface:
  ```bash
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR/docs/compound/agents/test-agent/2026-05-18"
  cp skills/compound/schemas/fixtures/*.retro.md "$TMPDIR/docs/compound/agents/test-agent/2026-05-18/"
  cd "$TMPDIR" && <invoke engineering-harness-v2 via your active CLI>
  grep -E "^- .* target: (build|config)" docs/project-rules/engineering-harness.md
  # Expected: ≥1 line per target
  ```
- [ ] **FX001-2**: `echo '<full JSON payload>' | just compound-value` renders a 6-line terminal view. Use the **full schema payload** documented in `compound-3-harvest/SKILL.md` (NOT the abbreviated one below — that's a subset for illustration). Reference full shape: `schema_version`, `generated_at`, `retros`, `entries.{total,open,suggested,encoded,wontfix,dismissed,escalated,stale}`, `top_clusters[].{kind,target,count,oldest,representative}`, `harness.{maturity,last_validation,boot_ms,verdict}` — per workshop 007 § RV-002 L140-173.
  Illustrative subset (will work end-to-end with default-handling):
  ```bash
  echo '{"schema_version":"1.0.0","generated_at":"2026-05-18T17:30:00Z","retros":27,"entries":{"total":47,"open":28,"suggested":2,"encoded":17,"wontfix":0,"dismissed":0,"escalated":0,"stale":0},"top_clusters":[{"kind":"difficulty","target":"tooling","count":4,"oldest":"2026-05-14T11:22:00Z","representative":"grep on src/ took 47s"}],"harness":{"maturity":"L2","last_validation":"2026-05-18","boot_ms":18000,"verdict":"healthy"}}' | just compound-value
  ```
  Expected first line: `Harness: L2, last validation HEALTHY, boot 18s`.
- [ ] **FX001-3**: Seed a buffer entry, run `compound-2-bubble`, pick `[e]ncode`, verify diff:
  ```bash
  AGENT_SLUG=$(echo "test-agent" | tr -c 'a-z0-9-' '-' | sed 's/-*$//')
  mkdir -p docs/compound/_buffers/
  cat > docs/compound/_buffers/$AGENT_SLUG.session-buffer.md <<'EOF'
  - id: TEST-001
    kind: improvement-suggestion
    target: compound
    description: Test entry for validation footer render.
  EOF
  # Invoke /compound-2-bubble via your active CLI; pick [e]ncode for TEST-001
  grep -A 8 "^## Validation" scratch/encode-TEST-001-*.diff
  # Expected: Run: / Expected: / Compound lifecycle: lines all populated
  ```
- [ ] **Cross-cutting**: `just install-skills-from-source` succeeds with exit 0 and no error output:
  ```bash
  just install-skills-from-source 2>&1 | tee /tmp/install.log
  echo "exit=$?"  # Expected: 0
  grep -iE "error|failed" /tmp/install.log
  # Expected: no matches (or only matches inside SKILL.md description prose, not status output)
  ```
- [ ] **Compound loop closure (signals a/b/d only)**: A `.retro.md` exists with entries containing `id: RV-001/002/003`, `kind: improvement-suggestion`, and `system.compound.status: encoded` + `system.compound.resolved_by: <commit-sha>`:
  ```bash
  find docs/compound/agents -name '*.retro.md' -newer .git/HEAD \
    | xargs grep -l 'id: RV-001\|id: RV-002\|id: RV-003'
  # Expected: ≥1 retro file with all 3 entries (or 3 files, one per RV)
  # Verify shape:
  yq '.entries[] | select(.id | test("^RV-00[123]$")) | .system.compound.status' \
    <(find docs/compound/agents -name '*.retro.md' | head -1)
  # Expected: encoded × 3
  ```
  Signal (c) — subsequent session surfaces the entries — is verified by the **next session** that reads `docs/compound/agents/**/*.retro.md` via plan-1a Subagent 7 or by re-running engineering-harness-v2.

---

## Out of Scope (tracked elsewhere)

| RV-ID | Topic | Where it goes | Handoff assumption from FX001 |
|-------|-------|--------------|-------------------------------|
| RV-004 | Optional `evidence:` pointers + schema v1.1.0 bump | **FX002** (Group B — schema bump batch) | FX001 ships with `schema_version: "1.0.0"` in all retros. FX002 bumps to v1.1.0 (additive only — v1.0.0 retros remain valid). The 3 RV-001/002/003 retros written by FX001 stay valid under both schema versions. |
| RV-005 | Reduce mandatory confirmation in engineering-harness-v2 CREATE mode | **FX002** (Group B — same batch as RV-004) | FX001 makes no changes to the CREATE-mode UX. The 3-trigger ambiguity guardrails (boot command unclear / port collision / destructive cleanup) defined in workshop 007 RV-005 are FX002's authoritative spec. |
| RV-006 | Cluster → regression-proof pattern (opt-in only, 4 guardrails) | **FX003** or plan 025 — defer until plan 023 T028 dogfood signal | "Dogfood signal" = ≥4 weeks of real usage produces real clusters (per workshop 007). When the user (you) judges signal-achieved, FX003 starts. The 4 anti-vibe guardrails in workshop 007 RV-006 are inviolable in any later implementation. |
| RV-007 | Move deterministic harvest logic to scripts | **FX003** or plan 025 — gated on Q1 (does `npx skills` preserve `scripts/` subdirs under a skill?) | Q1 must be tested **before** FX003 work begins: `npx skills add . --skill compound-3-harvest --list` against a branch containing a stub `skills/compound/compound-3-harvest/scripts/` directory. If subdirs are flattened, RV-007 needs an alternative layout (vendor scripts inside SKILL.md or at repo-level `scripts/`). |

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| RV-001 filter widening surfaces noisy/irrelevant entries | Low | Low | The 7 new targets are all genuinely boot-relevant per workshop 007. If real dogfood shows noise, narrow back in FX002. |
| `scripts/compound-value.sh` duplicates harvest logic | Low | Low | The script is a pretty-printer only — it consumes JSON, doesn't compute. Real harvest stays in the skill. RV-007 (FX003) will properly extract harvest logic if needed. |
| Validation footer template adds review friction | Low | Low | Footer is on the staged diff in scratch — the reviewer sees it once. If real usage shows it's noise, simplify in FX002. |
| `npx skills` install breaks on the SKILL.md edits | Very low | Medium | Run `just install-skills-from-source` as part of acceptance. Existing recipe surfaces install errors. |

---

## Compound Tracking

When this fix lands and is committed, three retro entries must be written — one per RV — under `docs/compound/agents/<your-agent-slug>/2026-05-1X/T<HH-MM-SS>Z-<hash>.retro.md`. The retros use the **universal envelope** plus the **compound namespace extension** at `entry.system.compound.*` (the `status` and `resolved_by` fields belong under `system.compound`, NOT at Entry root — Entry root has `additionalProperties: false`).

### Canonical retro shape (per `retro.schema.json` + `system.compound.schema.json`)

```yaml
# Universal envelope — required fields per retro.schema.json
schema_version: "1.0.0"
retro_id: "2026-05-1XTHH-MM-SSZ-<slug>-<hash>"
agent: "<agent-slug>"
plan_id: "023-difficulty-ledger-skill"
started_at: "2026-05-1XTHH:MM:SSZ"
ended_at: "2026-05-1XTHH:MM:SSZ"
duration_ms: <int>

entries:
  - id: RV-001
    kind: improvement-suggestion
    target: engineering-harness
    description: |
      Widened boot-time relevance filter to capture build/config/dependencies/env/auth/tests/observe targets.
      Prior filter dropped 3 of 5 fixture target classes silently.
    references:
      - "fx-id:FX001"
      - "workshop-id:WS007"
    system:
      compound:
        status: encoded
        resolved_by: "<commit-sha>"
        source: user
        first_seen_at: "2026-05-18T17:12:00Z"

  - id: RV-002
    kind: improvement-suggestion
    target: compound
    description: |
      Added --json flag spec to compound-3-harvest + scripts/compound-value.sh stdin pretty-printer + just compound-value recipe.
      Preserves workshop 006 KISS rule (no on-disk index — view at read time).
    references:
      - "fx-id:FX001"
      - "workshop-id:WS007"
    system:
      compound:
        status: encoded
        resolved_by: "<commit-sha>"
        source: user
        first_seen_at: "2026-05-18T17:12:00Z"

  - id: RV-003
    kind: improvement-suggestion
    target: compound
    description: |
      Added ## Validation footer template to compound-2-bubble [e]ncode flow.
      Encoded diffs now include Run / Expected / Compound lifecycle blocks.
    references:
      - "fx-id:FX001"
      - "workshop-id:WS007"
    system:
      compound:
        status: encoded
        resolved_by: "<commit-sha>"
        source: user
        first_seen_at: "2026-05-18T17:12:00Z"
```

### Emission mechanism (canonical path)

**Option A — Manual write (recommended for fix workflows)**: After the FX001 commit lands, hand-author a single `.retro.md` containing all 3 entries above. This is the most deterministic path because plan-6a's orchestrator retrospective harvests only `kind: difficulty | magic-wand | gift` (Step 8a) — it does not natively emit `improvement-suggestion` kind retros for the fix workflow. Hand-write is canonical here.

**Option B — Bubble + harvest lifecycle (full loop)**: Seed `docs/compound/_buffers/<agent-slug>.session-buffer.md` with the 3 entries before the FX001 commit; run `/compound-2-bubble` and pick `[e]ncode` for each (this writes retros with `system.compound.status: suggested` + `resolved_by: scratch/encode-*.diff`); after the commit, run `/compound-3-harvest` and apply lifecycle action `[e]` on each entry to transition `suggested → encoded` and update `resolved_by` to the commit SHA. Use this path when you also want to exercise the bubble/harvest skills end-to-end.

### What FX001 landing actually demonstrates

Three of the four Compounding Test signals from plan 023 spec are demonstrated **by FX001 landing alone**:

1. **Signal (a) — action chosen at bubble-up**: ✅ The `[e]ncode` choice (Option A or B above) is the action. The workshop+dossier+fix chain captures it.
2. **Signal (b) — entry marked `system.compound.status: encoded`**: ✅ The 3 retros above are written with that status post-commit.
3. **Signal (d) — user did not disable the system**: ✅ The absence of `docs/compound/.disabled` is observable.

The fourth signal — **Signal (c), a subsequent session starts by reading the ledger** — is **not** demonstrated by FX001 landing in isolation. It is verified by the **first post-FX001 session**: when an agent starts and reads `docs/compound/agents/**/*.retro.md` (via plan-1a Subagent 7) or `## Known Difficulties` (via engineering-harness-v2), and the 3 RV entries surface in either output, signal (c) is demonstrated.

**This is the literal compounding test for plan 023.** The dossier delivers signals (a)/(b)/(d) directly; signal (c) is delivered by the next session that opens this repo.

---

## Discoveries & Learnings

_Populated during implementation._

| Date | Task | Type | Discovery | Resolution |
|------|------|------|-----------|------------|
| | | | | |

---

## Validation Record (2026-05-19)

### Validation Thesis

**Raison d'être**: Lock the 3 immediately-shippable review fixes (RV-001/002/003) into an executable batch that closes the compounding loop on plan 023 itself.

**Value claim**: Executor opens dossier, follows the 3-row task table, doesn't need to re-read review/workshop. The fix landing serves as live demonstration of plan 023's promise.

**Artifact promise**: 3 RV items → 3 task rows → 1 retro (3 entries) → Compounding Test signals (a)/(b)/(d) demonstrated by FX001 landing; signal (c) by the next session.

**Intended beneficiaries**: `/plan-6-v2 --fix FX001` executor (primary), `/plan-7-v2 --fix` reviewer (secondary), plan 023 T028 verification (tertiary).

**Proof target**: Implementation Ready.

**Evidence standard**: Files exist + line numbers match + validation commands are mechanically runnable + retro shape matches `retro.schema.json` + `system.compound.schema.json`.

**Thesis source**: Workshop 007 § Group A + user instruction "we're gonna do them all" + plan-5-v2 Fix Mode template.

**Thesis verdict**: Partially advanced (pre-fix) → Advanced (post-fix).

**Main thesis risk**: Pre-fix risk — executor completes the 3 file edits, validations pass, but retros never emit because the YAML shape contradicts the schema and the emission mechanism is unspecified. Post-fix mitigation — retro shape uses `system.compound.*` namespace; emission mechanism documented (Options A manual + B bubble/harvest); validation commands are mechanically runnable.

---

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Source Truth + Cross-Reference | Source Truth, Cross-Reference, Concept Documentation | 2 HIGH fixed, 1 MEDIUM fixed | ⚠️ → ✅ |
| Completeness + Domain | Completeness, Edge Cases, Domain Boundaries, Hidden Assumptions | 1 HIGH fixed, 4 MEDIUM fixed, 1 LOW fixed | ⚠️ → ✅ |
| Thesis Alignment | Thesis Alignment | 1 CRITICAL fixed, 1 HIGH fixed, 4 MEDIUM fixed, 1 LOW fixed | ❌ → ✅ |
| Forward-Compatibility | Forward-Compatibility | 1 CRITICAL fixed, 3 HIGH fixed, 2 MEDIUM fixed (1 deferred to plan-6 SKILL.md own work) | ❌ → ✅ |

### Forward-Compatibility Matrix (post-fix)

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| `/plan-6-v2-implement-phase --fix "FX001"` | 7-col task table + flight plan with 4-class `stateDiagram-v2` | shape mismatch | ✅ | Dossier tasks table has 7 columns; flight plan stages now use action-phrase format per plan-5b convention; plan-6 SKILL.md L59 acknowledges `FX###.fltplan.md` for fixes |
| `/plan-6a-v2-update-progress` (Step 8c.ii) | Emit retro shape matching universal schema (status / resolved_by inside `system.compound.*`) | shape mismatch + contract drift | ✅ | Compound Tracking section rewritten to nest under `system.compound`; Option A (manual write) flagged as canonical for improvement-suggestion kind since plan-6a Step 8a only harvests difficulty/magic-wand/gift |
| `/plan-7-v2-code-review --fix "FX001"` | Files-changed list + mechanically testable acceptance criteria | contract drift | ✅ | Acceptance § FX001-1/2/3 each have a runnable script block with explicit seeding + grep verification |
| Plan 023 T028 verification | 3 retros exist with `system.compound.status: encoded` + `resolved_by: <sha>` matching RV-001/002/003 | lifecycle ownership + test boundary | ✅ | Acceptance § Compound loop closure uses mechanical `find` + `yq` commands; signals (a)(b)(d) demonstrated by FX001 landing; signal (c) explicitly attributed to next session |
| FX002 (Group B) queued | Schema-version assumption + RV-004/005 scope handoff | contract drift | ✅ | Out-of-Scope table now has a "Handoff assumption from FX001" column locking schema at v1.0.0 + naming workshop 007 RV-005 as authoritative for the CREATE-mode UX spec |
| FX003 (Group C) queued | Dogfood-signal definition + Q1 (subdir flatten) test gate | contract drift | ✅ | Out-of-Scope handoff names the Q1 test as gating and "≥4 weeks of real usage" as the signal definition |

**Thesis alignment**: Value claim now fully advanced at the Implementation Ready proof level — retro emission shape matches schema, mechanism is documented (Options A/B), and acceptance criteria are mechanically runnable. Main remaining risk: if the user picks Option B (bubble + harvest lifecycle), they must successfully run `/compound-2-bubble` `[e]ncode` for each entry then `/compound-3-harvest` lifecycle `[e]` — only the actively-developed bubble/harvest skills can confirm this works end-to-end on first dogfood, but this is a dogfood-test risk not a dossier defect.

**Outcome alignment**: FX001 as fixed advances the workshop 007 outcome — "These three encoded retros are the proof-by-existence that the compounding loop from plan 023 works" — because the dossier now specifies (1) the exact schema shape the 3 closure retros must have, (2) two concrete emission paths (manual write vs bubble+harvest lifecycle), (3) mechanical acceptance commands using `find` + `yq` that downstream consumers (`/plan-7-v2`, plan 023 T028) can run without guessing.

**Standalone?**: No — concrete downstream consumers exist (plan-6-v2, plan-6a-v2, plan-7-v2, plan 023 T028, FX002, FX003), and the user-value chain ("loop closure proof for plan 023") depends on this artifact's exact shape.

**Overall**: ⚠️ VALIDATED WITH FIXES — all CRITICAL + HIGH issues from 4-agent parallel validation fixed in-place. Two MEDIUM items deferred (one to the plan-6 SKILL.md's own work — formal `--fix` flag documentation; one to FX003's own gate test — Q1 subdir flatten check).
