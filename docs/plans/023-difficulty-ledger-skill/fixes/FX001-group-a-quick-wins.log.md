# Execution Log: Fix FX001 — Group A Quick Wins

**Fix**: [FX001-group-a-quick-wins.md](./FX001-group-a-quick-wins.md)
**Status**: Implemented 2026-05-19 (code only; closure retro pending commit SHA)

---

## Pre-flight (2026-05-19)

- Sentinel: ✅ `docs/compound/.disabled` absent
- Buffer: ✅ `docs/compound/_buffers/` contains only README.md (no carryover entries)
- Engineering harness: 🔴 UNAVAILABLE — `docs/project-rules/engineering-harness.md` absent. Per skill convention: note and proceed with standard testing. (This fix doesn't depend on a project-level harness; it modifies the skills themselves.)

## FX001-1 — Widen target taxonomy filter (RV-001)

**Files touched**:
- `skills/SDD/engineering-harness-v2/SKILL.md` — line 156 (HTML comment) and line 218 (Step 4a algorithm bullet)

**Change**: Filter widened from `engineering-harness | tooling | infra` (3 targets) to `engineering-harness | tooling | infra | build | config | dependencies | env | auth | tests | observe` (10 targets). Comment on the algorithm bullet explicitly states *"these are the target classes a fresh agent hits during boot/install/health-check; entries outside this set are not boot-time concerns"* — the dossier wanted the rationale inline so future readers don't re-debate scope.

**Evidence**: `grep -n "engineering-harness | tooling | infra" skills/SDD/engineering-harness-v2/SKILL.md` returns the **new** widened string on both L156 and L218 — confirms both locations updated. No other occurrences of the narrow filter remain.

**Closes**: retro `RV-001` (target: engineering-harness).

## FX001-2 — `--json` flag + script + recipes + sync (RV-002)

**Files touched**:
- `skills/compound/compound-3-harvest/SKILL.md` — inserted full `--json` output schema spec immediately after Step 5's default-format section. Documented schema_version + generated_at + retros + entries (8-value status breakdown) + top_clusters[].{kind,target,count,oldest,representative} + harness.{maturity,last_validation,boot_ms,verdict} + missing-field semantics + sentinel-disabled exit-code behavior. Cross-references `scripts/compound-value.sh` as the canonical consumer.
- `scripts/compound-value.sh` (new, 35 lines) — bash + jq pretty-printer. Reads JSON on stdin, emits compact terminal view: harness line / compound counts / blank / top-friction header / up to 2 cluster rows. Handles empty clusters via `Top friction: (none)`. Missing-field defaults render `Unknown` / `0`. `chmod +x` applied.
- `justfile` — added `compound-value` recipe (`@scripts/compound-value.sh`) plus a `Compound loop:` section in the `help` recipe listing it.
- `src/jk_tools/scripts/compound-value.sh` — auto-synced by `scripts/sync-to-dist.sh` (run as part of this task).

**Evidence**:
- Direct script test: `echo '<sample-json>' | scripts/compound-value.sh` produces 6 lines beginning `Harness: L2, last validation HEALTHY, boot 18s` — matches acceptance § FX001-2.
- Recipe test: `just compound-value` (with stdin piped) produces same output.
- Help listing: `just help | grep -A 2 "Compound loop"` shows the entry.
- Distribution: `ls src/jk_tools/scripts/compound-value.sh` confirms post-sync presence (1449 bytes, executable).

**Closes**: retro `RV-002` (target: compound).

**Decision logged**: workshop 007 Q2 was already RESOLVED → option (b) stdin pretty-printer (cross-CLI portable). Implemented option (b) verbatim. No CLI-specific binding in the recipe — any agent can produce JSON and pipe.

## FX001-3 — Validation footer template (RV-003)

**Files touched**:
- `skills/compound/compound-2-bubble/SKILL.md` — `[e]ncode` action section. Added new step 2 ("Append the Validation footer") to the existing 1-2-3 flow (now 1-2-3-4); added a new `#### Validation footer template (mandatory on every encoded diff)` subsection with: literal markdown template (Run/Expected/Compound-lifecycle sub-sections), per-section sourcing rules (suggested_encoding → agent best-effort → "(manual review only)" escape), and a one-sentence justification connecting back to *"encoded means the loop changed AND we can prove it, not just we wrote a patch."*

**Evidence**: Grep confirms `## Validation` template appears in `skills/compound/compound-2-bubble/SKILL.md`. Footer template includes all three required sub-sections (Run, Expected, Compound lifecycle).

**Closes**: retro `RV-003` (target: compound).

## Cross-cutting: install smoke test

`just install-skills-from-source 2>&1 | tee /tmp/install.log` → **exit 0**. `grep -iE "error|failed" /tmp/install.log` → no matches. All 33 skills installed across the 5 supported CLIs (Claude Code, Codex, OpenCode, GitHub Copilot, Pi). The edited skills (engineering-harness-v2, compound-3-harvest, compound-2-bubble) installed cleanly.

## Closure retros (pending)

Three `improvement-suggestion` entries (RV-001/002/003) will be written into a single `.retro.md` file under `docs/compound/agents/claude-code/2026-05-19/T*.retro.md` once the code commit lands. Each entry uses the canonical schema shape (per `retro.schema.json` + `system.compound.schema.json`): root-level `id` / `kind` / `target` / `description` / `references`, with lifecycle metadata at `system.compound.status: encoded` and `system.compound.resolved_by: <commit-sha>`. Hand-written per Option A (canonical for fix workflows — plan-6a Step 8a only harvests difficulty/magic-wand/gift kinds, so improvement-suggestion entries don't flow through orchestrator retrospective).

## Compounding Test signals demonstrated

- ✅ **Signal (a) — action chosen at bubble-up**: The `[e]ncode` choice took the form of the workshop → dossier → fix-implementation chain. Manual write path (Option A) is the chosen action.
- ✅ **Signal (b) — entries marked `system.compound.status: encoded`**: 3 entries to be written with that status post-commit.
- ⏳ **Signal (c) — subsequent session reads ledger**: To be demonstrated by the **next** session that starts in this repo. Either plan-1a Subagent 7 (research) or engineering-harness-v2 (boot-time Known Difficulties) will surface RV-001/002/003 entries.
- ✅ **Signal (d) — user did not disable**: `docs/compound/.disabled` absent.

## Discoveries during implementation

| Date | Task | Type | Discovery | Resolution |
|------|------|------|-----------|------------|
| 2026-05-19 | FX001-2 | gotcha | Workshop 007's example output for `just compound-value` showed 9 lines (3 clusters + Next encoding), but the dossier I wrote earlier specified "exactly 6 lines". | Stuck with 6-line compact form per dossier acceptance. Script handles "no clusters" by collapsing to 4 lines (no padding). `Next encoding:` line deferred to a future enhancement — not needed for v1 utility. |
| 2026-05-19 | FX001-2 | decision | sync-to-dist.sh does NOT mirror `skills/` content (per CLAUDE.md). Only `scripts/` + `agents/` + `install/` + `setup_manager.py` are mirrored. | SKILL.md edits don't need sync. Only `scripts/compound-value.sh` needed the sync run. Sync ran in <1s. |
| 2026-05-19 | FX001-1 | insight | Per validate-v2's source-truth agent earlier this session, the filter taxonomy bug had been independently flagged twice — once in the external review (workshop 007 RV-001), once in the validate-v2 source-truth agent. Two independent confirmations before landing the fix. | Confidence-high on the change. Documented inline in the SKILL.md L218 comment so future readers understand the target-set rationale without revisiting workshop 007. |
