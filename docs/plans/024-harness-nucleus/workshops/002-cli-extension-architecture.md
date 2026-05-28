# Workshop: CLI + Extension Architecture

**Type**: CLI Flow / API Contract
**Plan**: 024-harness-nucleus
**Spec**: [../harness-nucleus-spec.md](../harness-nucleus-spec.md)
**Created**: 2026-05-28
**Status**: Draft

**Value Thesis**: This workshop makes the future plan-025+ extraction track cheaper and safer by narrowing the design space for the standalone harness-nucleus CLI before any code is written — it picks an implementation language, fixes a `harness <verb>` command surface that maps 1:1 onto the loop stages, and defines an extension boundary that third parties can target without forking the nucleus.
**Target Proof Level**: Preferred Direction
**Current Proof Level**: Decision Space

**Selected Value Axes**:
- **Strategic Value**: The CLI is how teams outside `jakkaj/tools` adopt the harness; its shape decides whether the nucleus is a product or an internal script. Getting the verb surface and extension boundary right is the difference between "a repo we extracted" and "a thing other people install."
- **Agent Readiness**: Every verb must be invokable by an agent mid-session with a stable, parseable contract (especially `--json`), so the loop runs without a human in the terminal.
- **Safety to Change**: An extension boundary defined now means new evaluators/skills (e.g. backpressure — workshop 003) can be added later without editing the nucleus, preserving the frozen contracts.
- **Cross-Domain Coordination**: The CLI sits between the markdown SKILL.md layer and the on-disk ledger; the workshop must make the wrap-vs-call relationship explicit so neither side surprises the other.

**Related Documents**:
- [001-new-repo-extraction.md](./001-new-repo-extraction.md) — repo boundary / what-moves (DEFERRED here)
- [003-harness-backpressure-eval.md](./003-harness-backpressure-eval.md) — the backpressure evaluator's own logic (treated here only as an example extension)
- [004-harness-compound-domains.md](./004-harness-compound-domains.md) — domain registry (DEFERRED here)

---

## Purpose

Design the `harness <verb>` command surface for the future standalone harness-nucleus repo and the extension boundary that lets third parties grow the loop without forking the nucleus. This workshop drives three decisions: (1) the implementation language for the CLI, (2) the verb-to-loop-stage mapping, and (3) the extension discovery + load mechanism. It explicitly seeds the plan-025+ extraction track — it is **not** an implementation spec, and it does **not** claim Implementation Ready.

## Fresh Entrant Outcome

A fresh human or agent should be able to use this workshop to reach **Preferred Direction** with no additional context.

They should be able to:

- Recite the full `harness <verb>` command surface and say which loop stage / surviving skill each verb drives.
- State the recommended CLI implementation language and the two rejected alternatives with their trade-offs.
- Describe how a third-party extension is discovered, declared, and loaded — and write a minimal example extension against the published interface table.
- Explain the relationship between the CLI and the markdown SKILL.md files (who wraps whom) without re-deriving it.
- Confirm that `harness retro --harvest --json` preserves the frozen `harness.maturity` / `harness.verdict` / `harness.boot_ms` JSON shape that `scripts/compound-value.sh` parses.

## Key Questions Addressed

- (a) Python entry points vs shell hooks vs in-repo skill files for the CLI + its extensions?
- (b) What is the `harness <verb>` command surface, and how does each verb map to the loop stages / surviving skills / existing scripts?
- (c) What is the extension discovery + load mechanism?

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | Preferred Direction | plan-025+ needs a recommended language + verb surface + extension model to argue with — not a finished spec. A direction unblocks the extraction track without over-committing. |
| Primary Value Axis | Strategic Value | The CLI is the adoption surface for the standalone nucleus; its shape is load-bearing for whether the nucleus becomes a product. |
| Supporting Value Axes | Agent Readiness, Safety to Change, Cross-Domain Coordination | The verbs must be agent-invokable; the extension boundary must let the loop grow without nucleus edits; the CLI/skill relationship must be explicit. |
| Downstream Loop Improved | Implementation (plan-025+) + Onboarding (third-party harness authors) | plan-025+ skips re-deriving the verb surface and language choice; extension authors target a published interface instead of reading nucleus internals. |

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| `harness <verb>` command table | § Command Surface | Decision (b) — verb surface | Draft |
| ASCII loop-flow + verb mapping | § Loop Flow and Verb Mapping | Decision (b) — verbs map to loop stages | Draft |
| `harness boot` terminal sample | § harness boot | Contract — boot output shape | Draft |
| `harness retro --harvest --json` sample | § harness retro --harvest (JSON) | Frozen contract — `harness.maturity/verdict/boot_ms` | Draft |
| Frozen JSON shape cross-check vs `scripts/compound-value.sh` | § JSON Contract (Frozen) | Risk — CF-02 silent breakage | Ready (shape copied from live script) |
| Language Decision Space table | § Decision Space — CLI Language | Decision (a) — implementation language | Draft |
| Extension interface table + example | § Extension Model (API Contract) | Decision (c) — discovery + load | Draft |
| CLI ↔ SKILL.md relationship | § CLI and the SKILL.md Files | Cross-domain coordination | Draft |
| Error code table | § Error Codes | Operability of the verb surface | Draft |

## Decision Space — CLI Implementation Language

The dossier (DB-06) names three reusable CLI starting points in this repo: `jk-tools-setup` (Python + rich + orchestrator), `scripts/plan-ordinal.py` (single-file argparse), and the `justfile` (human-readable dispatch). The repo already mixes Python (the `jk-tools-setup` console script in `pyproject.toml`), Node (the `npx skills` distribution path), and shell (`install/*.sh`, `scripts/*.sh`). The CLI must pick a primary host.

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A — Python console-script** (uvx / `pyproject.toml` entry point) | `harness` is a Python console script, mirroring `jk-tools-setup`. Subcommands via argparse/click. Extensions via Python entry-points (`harness.evaluators` group) + filesystem convention. | Matches the existing `jk-tools-setup` precedent and `scripts/*.py` utilities; uvx install needs no clone; entry-points give a first-class, well-understood extension mechanism; rich already a dependency for pretty terminal output; argparse handles `--json` cleanly. | Adds a Python runtime requirement to a repo whose *distribution* is Node (`npx skills`); two language ecosystems to keep healthy. | **Selected (recommended)** |
| **B — Node CLI** (npm bin, matches `npx skills`) | `harness` ships as an npm package with a `bin`, mirroring the `npx skills` distribution path. Extensions via npm packages + a `package.json` manifest key. | Single ecosystem with skills distribution; `npx harness` parallels `npx skills`; npm is already the publish channel for the skill catalog. | No existing Node CLI precedent in-repo to copy (the repo's CLIs are all Python/shell); reinvents argparse/rich ergonomics; skills distribution being Node does not imply the *loop driver* should be. | Rejected |
| **C — Thin POSIX shell wrapper** | `harness` is a `bash` dispatcher (like an expanded `justfile`) shelling out to `scripts/*.sh` / `scripts/*.py` per verb. | Lowest dependency floor; trivially portable; the loop already communicates only through files (DE-03), so a thin dispatcher is "enough"; `compound-value.sh` + `doctor-skills` already exist as shell. | Weak extension story (sourcing arbitrary `.sh` is a discovery + safety hazard); JSON assembly in bash is painful and the frozen `--json` shape lives here; no typed interface for third parties; poor argument parsing/UX. | Rejected (but viable as a fallback installer shim) |

**Recommended direction: Option A (Python console-script).** Rationale: the extension boundary (Decision c) is the highest-value part of this CLI, and Python entry-points give a first-class, discoverable, no-fork extension mechanism that neither a Node bin nor a shell wrapper matches for free. Python also has the strongest in-repo precedent (`jk-tools-setup`, `plan-ordinal.py`) so plan-025+ copies a known pattern rather than inventing one. The Node ecosystem stays where it earns its keep — *distributing the SKILL.md files via `npx skills`* — and the CLI does not need to live there to drive the loop, because the loop integrates only through files. Option C's shell dispatcher is retained as a **fallback install shim** (a `harness` shell stub that bootstraps the Python entry point), not as the primary host.

**Why not just `just`?** The `justfile` stays as the *contributor* dispatch inside `jakkaj/tools` (it already wraps `compound-value` and `doctor-skills`). The standalone nucleus needs a real installable CLI with an extension API; `just` is a developer convenience, not a distributable product surface.

## Loop Flow and Verb Mapping

The harness loop is **Boot -> Do Work -> Observe -> Retro -> Improve**. The CLI exposes one verb per loop stage plus a diagnostic verb. Each verb drives one of the three surviving skills (or mirrors an existing script).

```
                          harness boot
                               │   (-> harness-1-boot: health + maturity)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ BOOT          verify harness healthy, report maturity         │
│   • read docs/project-rules/engineering-harness.md            │
│     (3-deep fallback: engineering-harness.md ->               │
│      agent-harness.md -> harness.md)                          │
│   • report UNAVAILABLE gracefully if absent                   │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
                      ( agent does work )
                               │
                               ▼   harness observe
┌─────────────────────────────────────────────────────────────┐
│ OBSERVE       silent friction capture (-> harness-2-observe)  │
│   • append entry to                                           │
│     docs/compound/_buffers/<agent>.session-buffer.md          │
│   • no user output; no-op if docs/compound/ missing           │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼   harness retro --drain
┌─────────────────────────────────────────────────────────────┐
│ RETRO (drain) session-end (-> harness-3-retro --drain)        │
│   • [s/t/p/e/d/a] action menu                                 │
│   • write .retro.md to                                        │
│     docs/compound/agents/<agent>/<date>/                      │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼   harness retro --harvest
┌─────────────────────────────────────────────────────────────┐
│ RETRO (harvest) at merge (-> harness-3-retro --harvest)       │
│   • cluster + age + top-N                                     │
│   • --json emits frozen harness.* shape (CF-02)               │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
                          ( improve: human encodes )
```

`harness doctor` runs out-of-band (any time), mirroring `just doctor-skills`:

```
$ harness doctor
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ DOCTOR        deployment + ledger health (no loop stage)      │
│   • validate canonical store ~/.agents/skills + symlinks      │
│   • flag orphan real-dir skill stores at legacy paths         │
│   • check docs/compound/ tree + .disabled sentinel            │
└─────────────────────────────────────────────────────────────┘
```

### Command Surface

| Command | Loop Stage | Drives | Mirrors today |
|---------|------------|--------|---------------|
| `harness boot` | Boot | `harness-1-boot` (VALIDATE + STATUS) | `engineering-harness-v2 --validate/--status` |
| `harness observe "<note>"` | Observe | `harness-2-observe` (silent producer) | `compound-1-track` |
| `harness retro --drain` | Retro (session end) | `harness-3-retro --drain` | `compound-2-bubble` |
| `harness retro --harvest` | Retro (merge) | `harness-3-retro --harvest` | `compound-3-harvest` |
| `harness retro --harvest --json` | Retro (merge) | `harness-3-retro --harvest --json` | `compound-3-harvest --json` (frozen shape) |
| `harness doctor` | — (diagnostic) | deployment + ledger health | `just doctor-skills` |
| `harness doctor --json` | — (diagnostic) | machine-readable health | (new) |

**Why `retro` carries modes instead of separate `drain`/`harvest` verbs**: the spec already locked `harness-3-retro` as a single skill with `--drain` / `--harvest` modes (Round 2, Q2). The CLI mirrors the skill shape 1:1 so there is no impedance mismatch between verb and skill.

**Why `observe` takes a note argument**: the silent producer appends a single entry per call; the agent passes the friction text inline. With no argument, `harness observe` is a no-op status print (reports buffer line count) rather than an interactive prompt — keeping it agent-safe.

## harness boot

```
$ harness boot

┌─────────────────────────────────────────────────────────────┐
│ STEP 1: locate governance doc                               │
│   • try docs/project-rules/engineering-harness.md           │
│   • fallback agent-harness.md, then harness.md (3-deep)      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: validate + report maturity                          │
│   • read ## Known Difficulties + maturity markers           │
│   • check docs/compound/ tree + .disabled sentinel          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ OUTPUT                                                      │
│                                                             │
│   Harness: Developing (validation PASS, boot 1s)            │
│   Governance doc: docs/project-rules/engineering-harness.md │
│   Ledger: docs/compound/ present (1 retro, 0 open)          │
│   Sentinel: docs/compound/.disabled absent (loop ACTIVE)    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

When the governance doc is absent (a fresh repo, before the separate setup effort runs):

```
$ harness boot

Harness: UNAVAILABLE — no governance doc found
  (looked for docs/project-rules/{engineering-harness,agent-harness,harness}.md)
Ledger: docs/compound/ present
Sentinel: absent (loop ACTIVE)

Boot succeeds with status UNAVAILABLE; run your engineering-harness setup to scaffold the doc.
```

`UNAVAILABLE` is a reported *status*, not an error — exit code 0. This proves the dropped CREATE mode left no hard dependency (spec AC8).

## harness retro --harvest (JSON)

This is the **frozen contract** (CF-02). The shape below is copied verbatim from the jq filters in `scripts/compound-value.sh` — `.harness.maturity`, `.harness.verdict`, `.harness.boot_ms`, plus `.entries.*` and `.top_clusters[]`. The CLI MUST emit this exact shape; the standalone `compound-value` pretty-printer keeps working unchanged.

```
$ harness retro --harvest --json

{
  "harness": {
    "maturity": "Developing",
    "verdict": "pass",
    "boot_ms": 1180
  },
  "entries": {
    "total": 3,
    "open": 0,
    "encoded": 3,
    "suggested": 0
  },
  "top_clusters": [
    {
      "target": "engineering-harness-v2",
      "kind": "bug",
      "count": 1,
      "representative": "boot-time filter admitted only 3/10 target classes"
    }
  ]
}
```

### JSON Contract (Frozen)

| jq path | Type | Meaning | Consumer |
|---------|------|---------|----------|
| `.harness.maturity` | string | Maturity label (e.g. `Developing`) | `scripts/compound-value.sh` line ~30 |
| `.harness.verdict` | string | Last validation verdict (`pass`/`fail`/`unknown`) | `scripts/compound-value.sh` (uppercased) |
| `.harness.boot_ms` | number | Boot duration in ms (rendered as seconds) | `scripts/compound-value.sh` (`/1000 \| floor`) |
| `.entries.total/open/encoded/suggested` | number | Ledger entry counts | `scripts/compound-value.sh` |
| `.top_clusters[].target/kind/count/representative` | mixed | Clustered friction, top-N | `scripts/compound-value.sh` (first 2) |

**Why frozen**: changing any of the three `.harness.*` paths silently produces empty output from the pretty-printer (CF-02, R3). The CLI's `--json` writer is contractually bound to these names regardless of internal refactors.

## Error Codes

| Code | Message | Cause | Exit |
|------|---------|-------|------|
| (none) | `Harness: UNAVAILABLE` | Governance doc absent — reported status, not failure | 0 |
| E10 | `unknown verb: <verb>` | Typo / unsupported subcommand | 2 |
| E11 | `docs/compound/ not found — observe/retro no-op` | Ledger tree missing; observe/retro silently no-op (still exit 0 unless `--strict`) | 0 |
| E12 | `loop disabled (docs/compound/.disabled present)` | Sentinel set; verb short-circuits | 0 |
| E20 | `extension load failed: <name>` | A discovered extension raised on import/registration | 1 |
| E21 | `jq required but not in PATH` | `--json` rendering path needs jq (inherited from `compound-value.sh`) | 2 |

## Extension Model (API Contract)

The highest-value design decision. Third parties must be able to add new loop-stage participants (new skills) or new **evaluators** (e.g. the backpressure evaluator — workshop 003, treated here only as an example) without forking the nucleus.

### Discovery: two complementary mechanisms

| Mechanism | What it discovers | When to use |
|-----------|-------------------|-------------|
| **Python entry-points** (group `harness.evaluators`) | Installed Python packages that register an evaluator class | A pip/uvx-installable third-party evaluator (the primary, recommended path under Option A) |
| **Filesystem skill convention** (`skills/harness/<slug>/SKILL.md`) | Markdown loop-stage skills discovered by `npx skills` and read by the agent | A new loop-stage *skill* (markdown behavior, no Python) — discovered exactly as the 3 surviving skills are |

There is **no manifest file and no on-disk registry index** (KISS — recompute discovery at invocation time, print to terminal). Entry-points are queried live; skill folders are globbed live. This matches the repo's "no derived/rollup state" rule.

### Interface table — `HarnessEvaluator` (the entry-point contract)

An evaluator is a Python class registered under the `harness.evaluators` entry-point group. The CLI loads all registered evaluators at the relevant loop stage and lets each contribute to the report. Evaluators communicate **only through files and the report dict** — never by calling skills directly (DE-03).

| Member | Signature | Required | Contract |
|--------|-----------|----------|----------|
| `name` | `str` (class attribute) | yes | Stable identifier; appears in `harness doctor` and report output |
| `stage` | `Literal["boot","observe","retro"]` | yes | Which loop stage the CLI invokes this evaluator at |
| `evaluate(ctx)` | `(ctx: HarnessContext) -> dict` | yes | Pure-ish: reads ledger/governance via `ctx`, returns a JSON-serializable fragment merged under `report["extensions"][name]` |
| `disabled_when(ctx)` | `(ctx: HarnessContext) -> bool` | no | Opt-out hook; default checks `docs/compound/.disabled` |

| `HarnessContext` member | Type | Provides |
|-------------------------|------|----------|
| `ctx.repo_root` | `Path` | Repo root for resolving frozen paths |
| `ctx.ledger_dir` | `Path` | `docs/compound/` (frozen root) |
| `ctx.governance_doc` | `Path \| None` | Resolved governance doc via 3-deep fallback, or `None` |
| `ctx.agent` | `str` | Active agent slug (for `_buffers/<agent>...`) |
| `ctx.disabled` | `bool` | Whether `docs/compound/.disabled` is present |

**Contract rule**: an evaluator's fragment is merged under `report["extensions"][<name>]`, never at the top level. The frozen `.harness.*` / `.entries.*` / `.top_clusters` keys are reserved for the nucleus — extensions cannot collide with the CF-02 shape. This keeps `scripts/compound-value.sh` immune to third-party additions.

### Minimal example extension (backpressure evaluator — illustrative only)

```python
# my_harness_backpressure/evaluator.py
from harness_nucleus.api import HarnessEvaluator, HarnessContext

class BackpressureEvaluator(HarnessEvaluator):
    name = "backpressure"
    stage = "retro"   # runs at harness retro --harvest

    def evaluate(self, ctx: HarnessContext) -> dict:
        # workshop 003 owns the actual logic; here we only show the boundary
        open_count = count_open_entries(ctx.ledger_dir)
        return {"open_friction": open_count, "signal": "high" if open_count > 20 else "ok"}
```

Registered via the package's `pyproject.toml` (no nucleus edit required):

```toml
[project.entry-points."harness.evaluators"]
backpressure = "my_harness_backpressure.evaluator:BackpressureEvaluator"
```

After `uvx pip install my-harness-backpressure`, the nucleus discovers it live:

```
$ harness doctor
...
Evaluators (harness.evaluators):
  • backpressure (stage=retro)  [my-harness-backpressure 0.1.0]

$ harness retro --harvest --json
{
  "harness": { "maturity": "Developing", "verdict": "pass", "boot_ms": 1180 },
  "entries": { "total": 3, "open": 0, "encoded": 3, "suggested": 0 },
  "top_clusters": [ ... ],
  "extensions": {
    "backpressure": { "open_friction": 3, "signal": "ok" }
  }
}
```

The `extensions` block is additive and namespaced — `compound-value.sh` ignores it, so the frozen contract holds.

## CLI and the SKILL.md Files

The relationship is **both**, with a clean split of responsibility:

| Direction | Who calls whom | What flows |
|-----------|----------------|------------|
| **Skill -> CLI** | A SKILL.md body instructs the agent to run `harness <verb>` for deterministic, file-touching work (drain a buffer, render `--json`, resolve the governance doc via the 3-deep fallback). | Determinism + portability: the fallback logic, JSON assembly, and ledger writes live in one tested place, not duplicated across markdown bodies. |
| **CLI -> Skill** | The CLI's verbs are *named after* and *mirror* the surviving skills; `harness boot` is the executable embodiment of `harness-1-boot`'s VALIDATE+STATUS modes. The CLI does not parse or execute SKILL.md prose. | The skill remains the agent-facing behavior + judgement layer (the `[s/t/p/e/d/a]` menu, magic-wand reflex); the CLI is the mechanical layer underneath it. |

**Boundary rule**: judgement and prompting stay in the SKILL.md (agent reads them). Deterministic file operations, path resolution, JSON emission, and extension loading move into the CLI (agent invokes them). The two communicate only through files and CLI exit/stdout — never through the CLI reading skill markdown. This preserves DE-03 (file-only integration) and means a non-Claude CLI can drive the same loop by shelling `harness`.

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Implementation (plan-025+) | Must re-decide language, invent the verb surface, and design the extension boundary from scratch | Recommended language (Python console-script) + full verb table + entry-point extension contract are pre-decided to argue with |
| Onboarding (3rd-party harness authors) | Must read nucleus internals to add an evaluator | Targets a published `HarnessEvaluator` interface table + a working minimal example; no fork |
| Agent execution | Each skill re-implements path fallback + JSON shape in prose | One `harness <verb>` surface; deterministic ops centralized; `--json` shape frozen and documented |
| Review | Reviewer must reconstruct how CLI relates to skills + whether `--json` still feeds `compound-value.sh` | Wrap-vs-call boundary + frozen-contract cross-check are explicit tables |

## Validation / Acceptance

This workshop reaches its target proof level (Preferred Direction) when:

- A reader can name the recommended CLI language and both rejected alternatives with their trade-offs (§ Decision Space — CLI Language).
- The full `harness <verb>` surface is enumerated and each verb maps to a loop stage + surviving skill / existing script (§ Command Surface).
- `harness retro --harvest --json` is shown emitting the exact `.harness.maturity` / `.harness.verdict` / `.harness.boot_ms` paths that `scripts/compound-value.sh` parses, with the namespacing rule that protects them from extensions (§ JSON Contract).
- The extension model defines discovery (entry-points + filesystem convention, no manifest/index), a load mechanism, and an interface table, demonstrated by a minimal example extension (§ Extension Model).
- The CLI ↔ SKILL.md relationship is stated as a boundary rule, not left ambiguous (§ CLI and the SKILL.md Files).

## Open Questions

### Q1: Is the extension boundary entry-points-only, or also a thin shell hook?

**OPEN**: Recommendation leans entry-points (Option A). A shell-hook escape hatch (drop an executable in `~/.harness/hooks/<stage>/`) would let non-Python extensions participate but reintroduces Option C's discovery + safety hazards. Decide in plan-025+ once a real non-Python extension demand exists.

### Q2: Does `harness observe` write directly, or always defer to the skill?

**OPEN**: The CLI could append to the buffer itself (deterministic, agent-safe) OR remain a no-op status verb that only the skill's prose drives. Leaning "CLI writes" for determinism, but this is the one verb where the skill's judgement (what counts as friction) is most load-bearing — confirm with the harness-2-observe body during plan-025+.

### Q3: Where does the nucleus publish the `HarnessEvaluator` API — same package as the CLI, or a separate `harness-nucleus-api` package?

**OPEN**: A separate API package keeps third-party extensions from depending on the whole CLI; cross-references workshop 001 (new-repo extraction) and the future `@ai-substrate/retro-schema` npm extraction. Defer to the extraction track.

### Q4: Does `harness doctor --json` get its own frozen shape now?

**OPEN**: `doctor`'s human output mirrors `just doctor-skills`; a `--json` form is new (no current consumer). Leaving its shape unfrozen until a consumer exists, per "no derived state / recompute on demand."

### Deferred (cross-referenced, not designed here)

- Repo boundary / what-moves -> [001-new-repo-extraction.md](./001-new-repo-extraction.md)
- Backpressure evaluator's internal logic -> [003-harness-backpressure-eval.md](./003-harness-backpressure-eval.md)
- Domain registry -> [004-harness-compound-domains.md](./004-harness-compound-domains.md)
