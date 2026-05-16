# Self-Improving Difficulty Ledger Skill (`self-improve-v2` + `plan-8a-compound-harvest`)

**Mode**: Simple

> **Skill names** (resolved 2026-05-16): the producer is **`self-improve-v2`** (placed under `skills/SDD/`). The paired **harvest companion** is **`plan-8a-compound-harvest`** — a sub-step in the SDD pipeline that sits between `plan-7-v2-code-review` and `plan-8-v2-merge`. It reads accumulated ledger entries (typically after a code-review cycle, but invocable any time), ensures ledgers stay current, and surfaces prioritised improvement suggestions. Earlier drafts of this spec used the working name `gifts-v2` for the producer; retired in favour of `self-improve-v2` (per Clarification Q2 of session 2026-05-16). The harvest companion was added mid-clarification (Q4) and named in Q7. The dossier and workshop documents still reference `gifts-v2` and pre-date the harvest companion — they should be read with both renames in mind.
>
> **Naming convention note**: the rest of the SDD pipeline uses a `-v2-` infix (e.g. `plan-7-v2-code-review`). The user's literal answer for the harvest skill was `/plan-8a-compound-harvest` without `-v2-`. The spec uses the user's literal spelling. If the v2 suffix is desired for consistency, flag in a follow-up clarification.

📚 This specification incorporates findings from [`research-dossier.md`](./research-dossier.md) and authoritative design decisions from [`workshops/001-self-improvement-vibe.md`](./workshops/001-self-improvement-vibe.md).

---

## Research Context

The compounding-velocity promise in `harness-is-the-product-v2` Principle 2 ("every difficulty catalogued is a gift to future sessions") is currently broken in this repository. Two existing producers — `plan-6a-v2-update-progress` (orchestrator + companion retros) and minih's auto-harvest — write structured retrospectives to `docs/retros/<plan-slug>.md` and `docs/retros/<agent-slug>.md`. **No skill in the SDD pipeline reads from `docs/retros/`.** The legacy `## Discoveries & Learnings` table convention has one reader (`plan-1a-v2-explore` Subagent 7), but it does not see the new ledger. Twenty-five of the twenty-nine SDD skills neither write nor read difficulty entries. The most common agent session — anything outside `plan-6` invocation — emits zero ledger entries.

The vibe workshop locked seven design decisions plus an eighth on agent self-introspection (when does the agent silently ask itself the magic-wand check, and at what cadence). The schema, exact CLI prompt rendering, and AGENTS.md voice are intentionally deferred to follow-up workshops. This spec is scoped at the *capability* level — what the skill must do and how it must behave, not the precise YAML field names or the literal prompt text.

---

## Summary

Two paired, portable, self-improving skills that close both ends of the difficulty-ledger loop:

1. **`self-improve-v2`** *(producer; runs in every session)* — turns every agent session — planning, coding, reviewing, refactoring, debugging, exploring — into a contributor to a repo-wide difficulty ledger at `docs/retros/`. The skill silently captures both **user-source friction** (things the user mutters or types) and **agent-source friction** (the agent's own observations, plus a periodic "if I had a magic wand right now?" self-check at natural pauses). At session end, a single soft prompt surfaces all entries with one-keystroke options to save, escalate to a fix-task, escalate to a full plan, convert into encoded knowledge (a justfile recipe / AGENTS.md addition / SKILL.md edit / script staged as a reviewable diff in `scratch/`), or dismiss.

2. **Harvest companion skill** *(consumer; aimed to run after code-review cycles)* — pairs with `self-improve-v2`. Reads accumulated ledger entries (across the per-plan and per-session files), curates them (deduplicates, clusters by category/target, age-orders), ensures the ledger stays current (flags stale `open` entries, prompts for status updates on `suggested` entries), and surfaces a prioritised improvement-suggestion summary the user can convert into fix-tasks or full plans. Designed to run after `plan-7-v2-code-review` but invocable any time. The SDD equivalent of minih's `feedback-digest` agent. Working name and pipeline slot pending Open Q1 / Open Q2.

The skills ship as a **bundle**: the two skills themselves + reader-side updates (mandatory: `plan-1a-v2-explore` Subagent 7; in v1: `agent-harness-v2` template seeds `## Known Difficulties` from the ledger). AGENTS.md and CLAUDE.md gain a Self-Improvement Loop section describing the operational contract. The justfile gains pointer recipes. None of the encoded fixes is auto-applied; every escalation requires user assent.

Both skills are portable across Claude Code, Codex CLI, Copilot CLI, Pi, and OpenCode (no minih runtime dependency). They interoperate with minih's auto-harvest by writing to / reading from the same `docs/retros/` directory; an importer for minih's structured retros is explicitly deferred to a follow-up plan.

---

## Goals

### Producer (`self-improve-v2`)
- **Turn every session into a ledger contributor**, not just `plan-6` invocations. Any agent in any supported CLI can log entries.
- **Capture the agent-source signal** — the most honest friction signal the harness gets, because agents don't adapt the way humans do (per minih's "every agent that uses your tools is a user study you didn't have to schedule").
- **Stay silent during work, soft at the end** — no mid-session interruptions; one batched prompt at session close.
- **Make escalation cheap** — convert any entry to a fix-task / full-plan / encoded change with one keystroke; never auto-apply.

### Harvest companion (consumer)
- **Periodically curate the ledger** — read accumulated entries across the per-plan and per-session files, deduplicate, cluster by category/target, age-order.
- **Keep the ledger current** — surface stale `open` entries (no activity for N weeks) and `suggested` entries that never got encoded; prompt the user to advance status or wontfix them.
- **Drive improvement suggestions** — present a prioritised summary (e.g. "top 5 magic-wands by frequency", "3 difficulties recurring across plans", "2 encoded fixes that didn't take") with one-keystroke routes to fix-tasks or full plans.
- **Run after code-review cycles** — natural fit at the end of `plan-7-v2-code-review`, but also invocable on demand.

### Cross-cutting
- **Close the read-side gap** — at least `plan-1a-v2-explore` Subagent 7 reads the new ledger before drafting research; `agent-harness-v2`'s template seeds `## Known Difficulties` from the ledger.
- **Stay portable** — works in any CLI that consumes Anthropic SKILL.md; no runtime dependency on minih.
- **Document the loop as an operational contract** in AGENTS.md / CLAUDE.md so a fresh agent or human grasps it in under 60 seconds.
- **Cost less attention than the friction it captures** — if logging + bubbling + harvesting exceeds the cognitive cost of the friction itself, the loop is net-negative and must be revised.

---

## Non-Goals

- **Not a runtime.** The skill does not boot processes, does not own session state outside its append-only buffer file, and does not require a daemon.
- **Not a replacement for minih's auto-harvest.** Minih continues to auto-write to `docs/retros/<agent-slug>.md` when present. The new skill writes to a different scope (per-plan or per-session), in the same directory, with a compatible-by-superset format.
- **Not a minih importer in v1.** Converting minih's structured `retrospective.difficulties[]` into the portable schema is deferred to a follow-up plan.
- **Not auto-applying any fix.** Every encoded change is staged for the user to review and apply (`git apply scratch/encode-DL-001-justfile.diff`).
- **Not mid-session prompting.** The bubble-up at session end is the only user-facing surface. The agent's silent self-introspection does not count as a prompt — it never reaches the user.
- **Not a schema validator.** The schema is YAML-fenced markdown, machine-parseable but not enforced by a JSON Schema runtime in v1.
- **Not a ledger dashboard / aggregation tool** beyond the auto-rebuilt `docs/retros/_LEDGER.md` index. Cross-plan analytics and `feedback-digest`-style aggregation are deferred to a follow-up plan.
- **Not a bureaucratic ceremony.** No rating prompts, no satisfaction surveys, no required free-form fields, no "rate your session" UX. Anti-vibes 1–7 from the workshop are explicit rejections.
- **Not a forced behavior.** A `docs/retros/.disabled` sentinel file makes `log` mode a no-op for projects that don't want the loop.

---

## Target Domains

This repository does not use the formal `docs/domains/` system (no `docs/domains/registry.md`). Per the plan-1b convention for repos without a domain registry, the table below maps the feature's **scope areas** in lieu of formal domain boundaries. None require new `domain.md` files.

| Area | Status | Relationship | Role in This Feature |
|------|--------|-------------|---------------------|
| `skills/SDD/self-improve-v2/` | **NEW** | **create** | The producer skill — `log` (silent append to buffer), `bubble` (soft prompt at session end), `init` (first-run scaffold of `docs/retros/`) |
| `skills/SDD/plan-8a-compound-harvest/` | **NEW** | **create** | The harvest companion skill — reads accumulated ledger entries, curates them, surfaces prioritised improvement suggestions. Pipeline slot **8a** (between `plan-7-v2-code-review` and `plan-8-v2-merge`) per Clarification Q7. |
| `docs/retros/` | **NEW** | **create** | New ledger directory with `README.md` (convention guide), `_session-buffer.md` (per-session scratch), `_LEDGER.md` (auto-rebuilt dashboard), and `sessions/` subdirectory for per-session permanent entries |
| `skills/SDD/plan-1a-v2-explore/` | existing | **modify** | Subagent 7 ("Prior Learnings Scout") extends to read `docs/retros/<plan-slug>.md` and `docs/retros/sessions/*.md` in addition to the legacy `## Discoveries & Learnings` tables |
| `skills/SDD/agent-harness-v2/` | existing | **modify** | Generated `agent-harness.md` template gains a `## Known Difficulties` table seeded from the ledger (locked in v1 per Clarification Q4) |
| `AGENTS.md` · `CLAUDE.md` | existing | **modify** | Add a "Self-Improvement Loop" operational-contract section (D7 voice; ≤15 lines each; mirror content) |
| `README_AGENTS.md` | existing | **modify** | Add `self-improve-v2` and the harvest companion to the public skill catalog |
| `justfile` | existing | **modify** | Add `retro` recipe(s) — likely doc-pointer recipes (`just retro` prints "run `/self-improve-v2 bubble` in your agent CLI") since `just` is shell-side and the skill is agent-side |
| `skills/SDD/plan-3-v2-architect/` | existing | *(deferred)* | Optional reader (read top-N magic-wands before phase design) — **deferred to a follow-up plan** per Clarification Q4 |
| `skills/SDD/plan-7-v2-code-review/` | existing | *(deferred)* | Optional cross-check (phase against open OH/MH/DL entries) — **deferred** per Clarification Q4. The harvest companion is intended to run *after* plan-7, not modify it. |

### New Domain Sketches

#### `self-improve-v2` skill (NEW — producer)

- **Purpose**: Provide a portable, repo-wide producer for difficulty / magic-wand / gift / insight entries with a single soft bubble-up at session end. Replace the silent-journal failure mode with an active escalation loop.
- **Boundary Owns**: the `log` operation (append entry to `_session-buffer.md`); the `bubble` operation (read buffer, present prompt, route per user choice); the `init` operation (scaffold `docs/retros/` and seed `README.md` + AGENTS.md / justfile / CLAUDE.md inserts as suggested edits); the portable YAML-in-markdown schema; the `[s/t/p/e/d/a]` action menu and its routing logic; the agent self-introspection contract (when the magic-wand check fires; what gets logged).
- **Boundary Excludes**: the harvest/curation operations (those belong to the harvest companion); the minih runtime; minih → portable schema import (deferred); JSON Schema validation (no validator in v1); cross-session analytics beyond `_LEDGER.md` index (deferred); auto-applying any encoded fix (every change is staged as a diff for user review); the bodies of pipeline skills' modifications (those skills own their own contents; `self-improve-v2` only specifies *contracts* like "Subagent 7 reads `docs/retros/`").

#### Harvest companion skill (NEW — consumer)

- **Purpose**: Pair with `self-improve-v2` to close the read-side of the loop. Periodically read accumulated ledger entries, curate them (deduplicate, cluster, age-order), keep them current (flag stale entries, prompt for status updates), and surface a prioritised improvement-suggestion summary the user can convert into fix-tasks or full plans. Designed to run after `plan-7-v2-code-review` cycles.
- **Boundary Owns**: the read pass over `docs/retros/` (per-plan + per-session + per-agent files); deduplication and clustering logic; staleness heuristics (e.g. "open ≥4 weeks → flag"; "suggested but no resolved-by → flag"); the prioritised summary surface; one-keystroke routes from a harvested entry into `/plan-1b-v2-specify` or a fix-task; ledger-hygiene operations (mark `wontfix`, advance status, link `resolved-by`).
- **Boundary Excludes**: the per-session producer behavior (that's `self-improve-v2`); generating plans / specs / fix-tasks (it only emits invocations); analytics dashboards (deferred); auto-applying any change; the legacy `## Discoveries & Learnings` tables (it reads only `docs/retros/`); enforcing schema validation.

#### `docs/retros/` directory (NEW structural concept)

- **Purpose**: Single, repo-wide home for all difficulty-ledger entries from any source — the new skill, `plan-6a-v2-update-progress`'s paired writes, and minih's auto-harvest (where minih is in use).
- **Boundary Owns**: the directory layout (`README.md`, `_session-buffer.md`, `_LEDGER.md`, `<plan-slug>.md`, `<agent-slug>.md`, `sessions/<date>-<branch>.md`); the convention guide (`README.md`); the auto-rebuilt ledger index (`_LEDGER.md`); the `.disabled` sentinel semantics.
- **Boundary Excludes**: which entries to write (each producer owns its own writes); how entries get consumed downstream (each reader skill owns its own read logic); git history of the ledger (committed by default, project may opt to gitignore via convention guide).

---

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2, I=0, D=1, N=1, F=0, T=1 → **P=5 → CS-3**
  - **Surface Area (S=2)**: many files cross-cutting — 1 new skill, 4 existing skills modified, 3 docs files modified (AGENTS.md / CLAUDE.md / README_AGENTS.md), justfile, new `docs/retros/` tree
  - **Integration (I=0)**: purely internal; minih interop is read-compatible only and the importer is deferred
  - **Data/State (D=1)**: new schema + file layout convention; no migrations needed (all greenfield)
  - **Novelty (N=1)**: the bubble-up + escalation menu UX has no precedent in our skill set; agent self-introspection is well-established in minih philosophy; workshop has resolved most ambiguity, the residual is around schema field names and CLI prompt rendering (deferred to follow-up workshops)
  - **Non-Functional (F=0)**: standard; user privacy via `.disabled` sentinel; no perf or security concerns
  - **Testing/Rollout (T=1)**: observational testing via the 1-week Compounding Test; no unit tests for markdown skills (convention in this repo)
- **Confidence**: 0.75
- **Assumptions**:
  - Skills written in Anthropic SKILL.md format are loaded into the agent's context at session start (verified for Claude Code, Codex CLI, Copilot CLI, Pi, OpenCode via `npx skills` install)
  - Agents will reliably comply with `log` mode instructions when they encounter friction (emergent behavior — calibrated by the Compounding Test at 1 week post-install)
  - `docs/retros/` writes are committed to git by default (consistent with plan 017-harness-integration and minih's auto-harvest convention)
  - The `[e]ncode` action's "stage diff in `scratch/`" pattern (D3) works across all supported CLIs (each can write a file and print a `git apply` instruction)
  - `scratch/` is `.gitignored` (verified per AGENTS.md "Scratch Directory" section)
  - Plan-aware destination detection (D4) can use the same heuristic as `plan-1a-v2-explore` step 1 (cwd inside `docs/plans/NNN-slug/` or branch matches `^\d{3}-` ordinal pattern)
- **Dependencies**:
  - No external dependencies
  - No blocking dependencies on other plans
  - Optional minih interop is read-compatible only; does not block v1
- **Risks** (complexity-related):
  - **Agent compliance with `log` instructions** is the highest-risk variable. If agents systematically forget to call `log`, the buffer stays empty and the skill is a no-op. Mitigated by D1 hybrid trigger (agent-self-invoked default + manual escape) and by including explicit `log`-mode invocations in the modified pipeline skills' bodies (low-cost reminders in plan-1a, plan-3, plan-6, plan-7).
  - **Self-introspection over-firing** (anti-vibe 7). Calibrated by the workshop's "≤1 check per 5min" rule and the concrete trigger heuristics. Watch the buffer entry count after 1 week; if entries-per-hour exceeds ~4 in normal sessions, the heuristics need tightening.
  - **Reader-side updates not landing well** could cascade — if `plan-1a` Subagent 7 reads the new ledger but doesn't surface entries usefully, the compounding loop still doesn't compound. Mitigated by including the reader-side updates in the same plan (D6 "full bundle") and by the 1-week Compounding Test signal #3 ("did any session start by reading the ledger?").
  - **AGENTS.md / CLAUDE.md / README_AGENTS.md three-file drift** — these mirrors must stay in sync. Mitigated by including all three in the spec scope and by adding a `scripts/check-mirrors.sh` style check (or equivalent) if drift becomes a recurring problem.
  - **Schema interop tension** — workshop's recommended YAML-in-markdown is a compromise between human-writable and machine-parseable. The schema workshop (queued) will resolve specifics; if the interop with minih's JSON proves clunky, the importer plan can adapt.
- **Phases** — Mode is **Simple** (resolved in Clarification Q1 of session 2026-05-16). Plan-3 will produce a single phase with grouped tasks rather than a multi-phase split. The work below is therefore presented as **task groups within one phase** rather than separate phases:
  - **Group A — Workshops** (foundation; locks deferred contracts before code lands): schema workshop, CLI-flow workshop, AGENTS.md-voice workshop, harvest-skill behavior workshop (the harvest companion needs its own design pass).
  - **Group B — Build `self-improve-v2`** (the producer): `log` / `bubble` / `init` modes, the `docs/retros/` scaffold, the `_LEDGER.md` rebuild logic.
  - **Group C — Build the harvest companion** (the consumer): read-pass over `docs/retros/`, dedup + cluster + age-order logic, staleness heuristics, prioritised summary surface, ledger-hygiene operations.
  - **Group D — Docs + harness**: AGENTS.md / CLAUDE.md / README_AGENTS.md / justfile updates; `agent-harness-v2` template gains `## Known Difficulties` (locked in v1).
  - **Group E — Reader-side updates**: `plan-1a-v2-explore` Subagent 7 reads `docs/retros/` (mandatory).
  - **Group F — Dogfood + Compounding Test evaluation**: calibrate self-introspection heuristics; calibrate harvest-staleness heuristics; file any vibe regressions as `self-improve-v2`-tagged entries to its own ledger (delicious recursion).
  - **Note on Mode tension**: Simple Mode in this repo means a single phase with inline tasks, plan-4 / plan-5 optional. Six task groups in one phase is wide. `/plan-3-v2-architect` may surface this and recommend Full Mode instead. The user's clarification Q1 explicitly chose Simple — the architect should respect that unless the wide-but-shallow shape proves unworkable.

---

## Acceptance Criteria

1. **No-op session is silent.** A user can run a fresh session in any supported CLI (Claude Code, Codex CLI, Copilot CLI, Pi, OpenCode) where the agent encounters no friction, and see no prompt from the skill at session end.

2. **Single soft bubble at session end.** A user can run a session where the agent observes 2+ friction moments, and at session end see one prompt listing those entries with `[s/t/p/e/d/a]` actions and per-entry one-line encoding hints. No per-entry prompts; no mid-session prompts.

3. **Agent self-introspection at natural pauses.** The agent silently runs the magic-wand self-check (`"if I had a magic wand right now, what would I change?"`) at the trigger moments locked in workshop D8c (tool call > 30s, zero-result search, 2nd retry of same command, backtrack from wrong assumption, test/build failure requiring guesswork, plus an optional task-boundary check). Entries logged with `source: agent-self`. Self-prompt rate stays at ≤1 per 5 minutes of session work in typical sessions; entries-per-session in normal use averages ≤5.

4. **Default action preserves information.** Pressing enter at the bubble-up prompt saves all entries to the appropriate scope file (active plan's `docs/retros/<plan-slug>.md` if a plan is detected from cwd or branch ordinal; else `docs/retros/sessions/<date>-<branch>.md`).

5. **`[e]ncode` stages a reviewable diff.** Choosing `[e]ncode` for an entry writes a candidate unified diff to `scratch/encode-<entry-id>-<target-shortname>.diff` and prints the `git apply scratch/encode-<entry-id>-<target-shortname>.diff` command. Nothing is auto-applied.

6. **`[t]ask` and `[p]lan` emit copy-pasteable invocations.** Choosing `[t]ask` prints a ready-to-run `/plan-5-v2-phase-tasks-and-brief --fix "<entry summary>"` invocation seeded from the entry's description and suggested encoding. Choosing `[p]lan` prints a `/plan-1b-v2-specify "<entry summary>"` invocation.

7. **First-run scaffold.** When `docs/retros/` does not exist on first invocation of any mode, the skill creates the directory with `README.md` (convention guide), `_session-buffer.md` (empty), and the `sessions/` subdirectory. The scaffolding act is itself logged as `type: gift, source: agent-self, suggested-encoding: { kind: doc-page, target-file: docs/retros/README.md }` so it surfaces at the bubble-up.

8. **AGENTS.md / CLAUDE.md describe the loop as a contract.** Both files contain a "Self-Improvement Loop" section (10–15 lines each, mirrored content) describing the loop in operational-contract voice (per workshop D7) — what `log` does, what `bubble` does, where entries land, when the agent self-introspects. No philosophical lecture; one-sentence story-mode preamble linking to `harness-is-the-product-v2`.

9. **`plan-1a-v2-explore` Subagent 7 reads the new ledger.** Subagent 7's "Prior Learnings Scout" is updated to read `docs/retros/<plan-slug>.md`, `docs/retros/sessions/*.md`, and `docs/retros/<agent-slug>.md` in addition to the legacy `## Discoveries & Learnings` tables. New entries from the ledger are surfaced in the research dossier's Prior Learnings section with the same `PL-NN` numbering scheme.

10. **Dogfood Compounding Test passes at 1 week post-install in this repo.**
    - Signal 1: ≥1 user action of `[t]`, `[p]`, or `[e]` chosen during the week.
    - Signal 2: ≥1 entry has its `status` field updated to `encoded` with a `resolved-by: <commit | PR | plan-NNN>` reference.
    - Signal 3: ≥1 subsequent session's research dossier surfaces an entry from `docs/retros/`.
    - Signal 4: the user has NOT added `self-improve-v2` (or its harvest companion) to a personal "skills I always disable" list.

11. **`.disabled` sentinel is honored.** A `docs/retros/.disabled` file (any contents) makes `log` mode a silent no-op (no append, no error) and `bubble` mode print one line: `self-improve-v2: logging disabled in this project (remove docs/retros/.disabled to re-enable)`. The harvest companion respects the same sentinel and prints an analogous line on invocation.

12. **Portable across CLIs (no minih dependency).** Both skills install via `npx skills@latest add jakkaj/tools --skill self-improve-v2 -a <client> -g` and `npx skills@latest add jakkaj/tools --skill plan-8a-compound-harvest -a <client> -g` for each of: claude-code, codex, github-copilot, opencode, pi. After install, `log` / `bubble` / harvest operations work in each CLI without any minih binary on `$PATH` and without any `MINIH_*` environment variable set.

13. **None of the seven anti-vibes is triggered by the v1 implementation.** Verified by walking each of the three imagined sessions (A: code review with two difficulties; B: planning research with one magic-wand; C: typo fix with no entries) against the implementation. For each anti-vibe (1–7 from workshop), document explicit evidence the implementation does NOT trigger it (e.g., "no mid-session prompt observed in Session A" → not nag-ware).

14. **Schema is YAML-fenced markdown, machine-parseable.** Every entry in any ledger file (buffer, scope, sessions) follows the canonical schema (locked by the schema workshop, deferred). A reader skill can grep for `^---$` fences, parse the YAML between them, and access entry fields by name without any runtime dependency beyond a YAML parser. No JSON Schema validation in v1.

15. **`docs/retros/_LEDGER.md` index is auto-rebuildable.** The index file is regenerated on demand from the per-scope files. The contents are a markdown table of open entries grouped by category, with magic-wand counts and `[e]ncode`-staged but unapplied diff counts. The skill provides a deterministic regeneration path; staleness is acceptable between regenerations.

### Harvest companion skill

16. **Harvest reads the full ledger.** Invoking the harvest skill reads every entry across `docs/retros/<plan-slug>.md`, `docs/retros/sessions/*.md`, and `docs/retros/<agent-slug>.md` (where minih has written) into a single in-memory view.

17. **Harvest curates entries.** The harvest output deduplicates entries that describe the same friction (heuristic match on `category` + `target` + description-similarity), clusters them by `category` and `target`, and age-orders within each cluster (newest first). Cluster summaries name the count and the most-frequent description-pattern.

18. **Harvest flags stale entries.** Entries with `status: open` and an age > 4 weeks (or with `status: suggested` and no `resolved-by` after 2 weeks) are flagged as "needs decision" with a one-keystroke menu to advance status (`[r]esolved` / `[w]ontfix` / `[s]till-active`).

19. **Harvest surfaces a prioritised improvement summary.** The output presents at most 10 actionable entries, prioritised by: recurrence count > severity > age. Each entry has the same `[t]/[p]/[e]/[d]` escalation menu as `self-improve-v2`'s bubble-up, plus the new `[r]/[w]/[s]` status-update actions.

20. **Harvest is invocable on demand.** The skill works invoked manually (`/plan-8a-compound-harvest`) regardless of whether `plan-7-v2-code-review` just ran. A natural prompt to invoke it appears at the end of `plan-7`'s output (in a follow-up plan; not modifying `plan-7` in v1).

21. **Harvest respects the `.disabled` sentinel.** Same semantics as `self-improve-v2` — sentinel makes harvest a no-op with a clear message.

### Reader-side updates (v1)

22. **`agent-harness-v2` template seeds `## Known Difficulties`.** The generated `agent-harness.md` template gains a `## Known Difficulties` section auto-populated with up to 10 most-relevant entries from `docs/retros/` (filtered by `target: agent-harness | engineering-harness | tooling`). New agent sessions reading `agent-harness.md` see the project's accumulated friction at boot.

---

## Risks & Assumptions

### Assumptions

- **A1 — SKILL.md loading**: skills in Anthropic SKILL.md format are loaded into the agent's context at session start by every supported CLI consumer.
- **A2 — Agent compliance with `log` instructions**: agents will follow the skill's `log`-mode instructions when they encounter friction, *most of the time*. The compliance rate need not be 100% to be useful; even 30% capture of agent-source friction is a step-change improvement over the current 0%.
- **A3 — `docs/retros/` is committed to git**: matches the existing convention in plan 017-harness-integration and in minih's auto-harvest. Projects can opt out via `.disabled` or by gitignoring the directory.
- **A4 — Plan-detection heuristic is reliable enough**: cwd-inside-`docs/plans/NNN-slug/` OR branch-name-matches-`^\d{3}-` (the heuristic from `plan-1a-v2-explore` step 1) is sufficient for D4 plan-aware destination routing.
- **A5 — `scratch/` is gitignored**: verified per AGENTS.md.
- **A6 — Diffs in `scratch/` are user-applicable**: `git apply` is in every developer's basic toolkit.
- **A7 — The seven anti-vibes are exhaustive enough for v1**: the workshop's anti-vibes were derived from concrete failure modes; new failure modes may surface during dogfood week and would be added in a follow-up workshop revision.

### Risks

- **R1 — Agent compliance is too low** (probability: medium; impact: high). If agents consistently forget to `log`, the buffer is empty and the skill is a journal nobody writes to. *Mitigation*: D1 hybrid trigger; pipeline-skill modifications include explicit `log` reminders at natural friction points; Compounding Test signal at 1 week measures this directly.
- **R2 — Self-introspection over-fires** (probability: low-medium; impact: medium → triggers anti-vibe 7). *Mitigation*: trigger heuristics in workshop are concrete (not vibes); calibration target ≤1 per 5min; explicit metric in AC#3.
- **R3 — Reader-side updates land but readers don't surface entries usefully** (probability: medium; impact: high). *Mitigation*: Phase 4 includes calibration of Subagent 7's surfacing logic; Compounding Test signal #3 measures this directly.
- **R4 — Schema/CLI/voice workshops over-engineer the deferred contracts** (probability: low; impact: medium). *Mitigation*: each workshop has a clear value frame and the vibe workshop's seven anti-vibes constrain the design space tightly enough that over-engineering should be self-evident at review.
- **R5 — Three-file mirror drift (AGENTS.md / CLAUDE.md / README_AGENTS.md)** (probability: medium; impact: low). *Mitigation*: explicit spec-time enumeration of all three; consider a `scripts/check-mirrors.sh` if drift recurs.
- **R6 — Minih interop tension surfaces during dogfood week** (probability: low; impact: low for v1). Some user runs minih in a project that also uses `self-improve-v2`. The two write to the same `docs/retros/` directory but in different formats. *Mitigation*: schema workshop validates the YAML format is at least readable alongside minih's auto-harvested files; the `self-improve-v2 import-minih` follow-up plan handles formal interop later.
- **R7 — User dismisses the bubble-up every time** (probability: medium; impact: high → anti-vibe 3 in motion). *Mitigation*: D5 "terse + encoding hint per entry" is the primary defense; if dismiss-rate is >80% after 1 week, the encoding hints are insufficiently compelling and need iteration.

---

## Clarifications

### Session 2026-05-16

#### Q1 — Workflow Mode

**Question**: Workflow mode for plan 023?
**Answer**: **Simple**.
**Effect**: Spec header updated to `**Mode**: Simple`. The Complexity § Phases section restructured to show six task **groups within one phase** rather than five separate phases (with a "Mode tension" note flagging that this is wide-but-shallow and `/plan-3-v2-architect` may surface this). Plan-4 / plan-5 are optional under Simple Mode.

#### Q2 — Skill name

**Question**: What should the new skill be called? (Options: gifts-v2 / difficulty-ledger-v2 / self-improve-v2 / magic-wand-v2.)
**Answer**: **`self-improve-v2`**.
**Effect**: Title, working-name note in header, and all spec body references updated from `gifts-v2` → `self-improve-v2`. Dossier and workshop documents retain the older `gifts-v2` working name for traceability; the rename note in the spec header points readers at this clarification. Filenames downstream (skill folder, `npx skills` install commands) all use `self-improve-v2`.

#### Q3 — Skill placement

**Question**: Which category should the new skill live under? (Options: skills/general/ vs skills/SDD/.)
**Answer**: **`skills/SDD/`**.
**Effect**: Target Domains table updated — both `self-improve-v2` and the new harvest companion live under `skills/SDD/`. Rationale per the user's selection: keeps the new skill next to its philosophical sibling `harness-is-the-product-v2` and the SDD pipeline neighbours.

#### Q4 — Reader-side scope (multi-select)

**Question**: Which reader-side updates should ship in v1?
**Answer**: **`plan-1a` Subagent 7 (mandatory)** + **`agent-harness-v2` template seeds Known Difficulties**. Other optional readers (`plan-3` magic-wand reader, `plan-7` cross-check) deferred from v1.

The user added a critical scope expansion in their notes: **a new paired skill is required** — a harvest/curator companion that runs after code-review cycles, reads the accumulated ledger, ensures ledgers stay current, and surfaces improvement suggestions. Suggested numbering hint was `/8` (but `plan-8-v2-merge` already occupies that slot).

**Effect**:
- Two skills now in v1 scope: `self-improve-v2` (producer) + harvest companion (consumer; name and slot resolved in Q7 below).
- Target Domains table updated to add the harvest companion as a NEW skill under `skills/SDD/plan-8a-compound-harvest/`.
- Summary, Goals, Non-Goals, Acceptance Criteria (added AC#16–22 for harvest), Risks, Workshop Opportunities (added a new "Harvest companion behavior" workshop), and Phases hint all updated to reflect the second skill.
- A new behavior workshop for the harvest companion is added to the queued workshops; it joins schema / CLI-flow / AGENTS.md-voice as a prerequisite to `/plan-3-v2-architect`.

#### Q5 — Testing Strategy

**Question**: Testing strategy for this work? (Deliverable is markdown skills + governance docs, not application code.)
**Answer**: **Manual + Compounding Test (recommended)**.
**Effect**: New `## Testing Strategy` section added (below). Approach is observational — the workshop's 1-week Compounding Test (4 signals) is the primary validation surface. No mocks needed (no application code to mock).

#### Q6 — Documentation Strategy

**Question**: Where should documentation live for this work?
**Answer**: **Hybrid: SKILL.md + AGENTS mirrors + `docs/retros/README.md` (recommended)**.
**Effect**: New `## Documentation Strategy` section added (below). Each skill's SKILL.md body carries the operating contract; AGENTS.md / CLAUDE.md gain Self-Improvement Loop sections; README_AGENTS.md gets catalog entries for both skills; `docs/retros/README.md` is the convention guide. No long-form `docs/how/` guide in v1.

#### Q7 — Harvest companion name + pipeline slot

**Question**: Name + pipeline slot for the harvest companion skill?
**Answer**: **`/plan-8a-compound-harvest`**.
**Effect**: Resolves what were Open Q1 and Q2. Pipeline slot **8a** sits between `plan-7-v2-code-review` and `plan-8-v2-merge` — natural fit since the harvest skill is "post-review pre-merge cleanup of the ledger." All harvest references in the spec updated to use the literal name. **Convention note**: the user's literal answer was `/plan-8a-compound-harvest` *without* the `-v2-` infix used by other SDD skills (e.g. `plan-7-v2-code-review`). The spec uses the literal name; if `-v2-` is desired for consistency, flag in a follow-up clarification — easy rename.

#### Q8 — Agent harness applicability

**Question**: Agent harness applicability for this work?
**Answer**: **N/A — feature doesn't need an agent harness (recommended)**.
**Effect**: No Phase 0 build. The deliverable is markdown skills + docs + reader updates; there's no running software for an agent to Boot/Interact/Observe against. The 1-week Compounding Test (per Q5 testing strategy) serves as the validation surface. `agent-harness-v2` is still being *modified* (template seeds Known Difficulties), but the project itself doesn't need a new agent harness.

---

## Testing Strategy

**Approach**: Manual + Compounding Test (resolved in Clarification Q5)

**Rationale**: The deliverable is markdown skills (loaded into agent context as SKILL.md) + governance docs (AGENTS.md / CLAUDE.md / README_AGENTS.md / `docs/retros/README.md`) + reader-side modifications to existing SKILL.md files. There is no application code to unit-test. The repo convention is observational testing for skill changes.

**Focus Areas**:
- **Compounding Test (1 week post-install)** — the workshop's 4 signals: (1) any `[t/p/e]` action chosen at bubble-up, (2) any entry marked `status: encoded`, (3) any session started by reading the ledger, (4) user did NOT disable the skill. Pass = vibe was right.
- **Anti-vibe walkthroughs** — manual check that the v1 implementation does NOT trigger any of the 7 anti-vibes from `workshops/001-self-improvement-vibe.md` (verified by walking the 3 imagined sessions A/B/C against the implementation; AC#13).
- **Portability check** — install via `npx skills@latest add jakkaj/tools --skill <name> -a <client> -g` for each of the 5 supported CLIs and confirm `log` / `bubble` / harvest operations work without minih (AC#12).
- **Dogfood week** — use both new skills in this repo for a week and observe the Compounding Test signals.

**Mock Usage**: N/A — no mocks needed. No application code that would have external dependencies to mock.

**Excluded** (not tested in v1):
- Cross-CLI hook integration (no auto-fire — D1 is hybrid agent-self-invoked + manual)
- `self-improve-v2 import-minih` interop (deferred to follow-up plan)
- JSON Schema validation of ledger entries (no validator in v1)
- Cross-plan analytics beyond what the harvest companion provides

---

## Documentation Strategy

**Location**: Hybrid — SKILL.md bodies + AGENTS mirrors + `docs/retros/README.md` (resolved in Clarification Q6)

**Rationale**: The skills themselves carry their operating contracts in their SKILL.md bodies (Anthropic convention). The AGENTS.md / CLAUDE.md / README_AGENTS.md mirror trio carries the operational contract for the loop *as a project norm* — what new contributors and new agents reading the repo for the first time should expect. The `docs/retros/README.md` convention guide is the file-layout + schema reference *colocated with the ledger itself* — readable independent of any skill.

**Locations and their purposes**:
| Location | Owner | Purpose |
|----------|-------|---------|
| `skills/SDD/self-improve-v2/SKILL.md` | self-improve-v2 | Producer's full operating contract: log/bubble/init modes, schema, action menu, agent self-introspection contract, anti-vibes |
| `skills/SDD/plan-8a-compound-harvest/SKILL.md` | plan-8a-compound-harvest | Harvest's full operating contract: read-pass, dedup/cluster/age-order logic, staleness heuristics, prioritised summary, ledger-hygiene operations |
| `AGENTS.md` § Self-Improvement Loop | new section | Operational contract for the loop as a project norm. ≤15 lines; D7 voice (operational with one-sentence story preamble). |
| `CLAUDE.md` § Self-Improvement Loop | mirror of AGENTS.md | Same content, Claude-convention filename |
| `README_AGENTS.md` | catalog entries | Both skills added to the public skill catalog with one-line descriptions matching the rest of the catalog |
| `docs/retros/README.md` | convention guide | Directory layout (`README.md`, `_session-buffer.md`, `_LEDGER.md`, `<plan-slug>.md`, `<agent-slug>.md`, `sessions/`); schema reference (links to spec); `.disabled` sentinel semantics |

**Excluded** (not in v1):
- Long-form `docs/how/self-improvement-loop.md` guide — deferred; SKILL.md bodies + AGENTS mirrors are sufficient for v1
- Standalone philosophy doc — `harness-is-the-product-v2` already plays that role; cross-referenced from both new SKILL.md bodies
- Per-CLI install guides — `INSTALL.md` already covers `npx skills` patterns; new skills inherit those install patterns automatically

---

## Open Questions

### Resolved in Clarification Session 2026-05-16

- ~~**[skill name]**~~ — RESOLVED: `self-improve-v2` (Q2). Earlier `gifts-v2` working name retired.
- ~~**[skill placement]**~~ — RESOLVED: `skills/SDD/self-improve-v2/` (Q3). Keeps the new skill next to `harness-is-the-product-v2` and the SDD pipeline.
- ~~**[reader-side scope]**~~ — RESOLVED: in v1 — mandatory `plan-1a-v2-explore` Subagent 7 + `agent-harness-v2` template seeds `## Known Difficulties` (Q4). Deferred from v1 — `plan-3-v2-architect` reader and `plan-7-v2-code-review` cross-check (the new harvest companion is intended to run *after* `plan-7`, not modify it).

### Newly opened (and resolved) in Clarification Session 2026-05-16

- ~~**[harvest companion name]**~~ — RESOLVED: **`plan-8a-compound-harvest`** (Q7). User's literal answer; v2 suffix omitted but flagged for future confirmation.
- ~~**[harvest companion pipeline slot]**~~ — RESOLVED: slot **8a** (Q7) — sub-step between `plan-7-v2-code-review` and `plan-8-v2-merge`. Honours the user's "/8"-ish hint.

### Carried forward (deferred to workshops or follow-up)

3. **[task-boundary self-prompt behavior]** — D8c includes "optional task-boundary check". Should the check fire only when the buffer is empty for the current task (avoids redundancy), or every task boundary regardless? Recommend: empty-buffer-only.

4. **[scaffolding consent]** — Does the skill scaffold `docs/retros/` automatically on first `log` invocation (AC#7 assumes this), or wait for explicit `/self-improve-v2 init`? Recommend: auto-scaffold but log the act as `type: gift` so the user sees it at bubble-up.

5. **[schema field shape — workshop deferred]** — The exact YAML field names, required-vs-optional split, and minih round-trip mapping are deferred to the schema workshop (queued). Spec assumes the schema sketched in the dossier survives substantively but does not lock field names.

6. **[bubble-up rendering — workshop deferred]** — Exact prompt copy, key-stroke handling, multi-entry per-action selection, and plan-detection prompt-output is deferred to the CLI-flow workshop (queued). Spec locks behavior (single soft prompt, `[s/t/p/e/d/a]` actions, default `[a]ll-save`) but not literal text.

7. **[AGENTS.md voice and exact text — workshop deferred]** — Exact 10–15 lines of AGENTS.md / CLAUDE.md text and precise placement is deferred to the AGENTS.md-voice workshop (queued). Spec locks D7 (operational-contract voice with one-sentence story preamble) but not literal text.

8. **[harvest companion behavior — workshop required]** — The new paired skill needs its own behavioral workshop: how does its output present? When is the staleness threshold (4 weeks for `open`? 2 weeks for `suggested`? configurable?)? Does it modify ledger files in place (e.g. flipping status to `wontfix`) or only suggest? Required before plan-3.

9. Workshop Q1 (carried forward): should bubble-up also offer "anything else you noticed?" prompt? Workshop recommendation: NO in v1; revisit after 1 month.

10. Workshop Q3 (carried forward): support `docs/retros/.disabled` sentinel? Workshop recommendation: YES; AC#11 assumes it.

---

## Workshop Opportunities

The vibe workshop (`workshops/001-self-improvement-vibe.md`) is complete. Per its "Next Steps" section, three more workshops are queued — all queued workshops are **prerequisites to `/plan-3-v2-architect`** because they lock contracts the architect needs.

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Difficulty ledger schema (YAML field shape, minih round-trip mapping) | Data Model | Schema is contract for both `self-improve-v2` writers and the harvest companion's reader; high inertia once written; ripples across every reader skill and any future analytics tool | Final field names? Required vs optional? Minih JSON → portable YAML mapping rules? `kind` field enum exhaustiveness? Per-scope vs global ID prefix scheme (DL-XXX in buffer, then re-numbered when saved to scope, vs `<scope>:DL-NNN`)? Auto-numbering reset rules? |
| Bubble-up CLI flow (prompt rendering, key-stroke handling, plan-detection, multi-entry selection) | CLI Flow | No precedent in our skill set; UX details determine whether escalation actually fires; high blast radius if wrong (anti-vibe 6 = schema-driven UX is one wrong step away) | Exact prompt copy? How is `[t]/[p]/[e]` invocation emitted (printed string? clipboard? written file?)? Plan-detection heuristics for D4? Multi-entry per-action selection (e.g. choosing `[t]` for 3 entries)? Behavior on terminal narrower than 80 cols? |
| AGENTS.md / CLAUDE.md / README_AGENTS.md voice and placement | Other | Three-file mirror; voice sets the tone for the whole self-improvement loop; sets norms for new contributors / new agents reading the repo for the first time | Where in AGENTS.md does the section land (after which heading)? Exact 10–15 lines for D7's operational-contract voice with one-sentence story preamble? README_AGENTS.md catalog entry — long form or one-liner? Linkage to `harness-is-the-product-v2` — link, embed, or both? |
| **Harvest companion behavior** (NEW — added by Clarification Q4) | Other (UX / interaction-pattern) | The new paired skill is conceptually clear (read ledger, curate, surface suggestions) but its UX, staleness heuristics, and ledger-mutation behavior are unspecified. Without this workshop the harvest skill design space is wide-open during plan-3. | When does it run (after plan-7? on demand? both)? Staleness thresholds (4 weeks `open` / 2 weeks `suggested`?)? Does it mutate ledger files (flip `status: wontfix` in place) or only suggest? How does its prioritised-summary output differ from `self-improve-v2`'s bubble-up? Does it call `self-improve-v2`'s schema or extend it (e.g. cluster IDs)? |

Optional follow-up workshops (probably out of v1 scope but listed for visibility):

| Topic | Type | Why It Might Workshop Later |
|-------|------|------------------------------|
| `self-improve-v2 import-minih` mapping | Data Model | If the schema workshop lands cleanly and minih interop tension surfaces during dogfood week, the importer may need its own design pass before the follow-up plan ships |
| `docs/retros/_LEDGER.md` rebuild logic | Data Model | If the auto-rebuild logic gets non-trivial (e.g. cross-scope rollups handled by the harvest companion), it deserves its own workshop |
| Reader-side surfacing UX in `plan-1a` Subagent 7 | Other | If the surfacing of new ledger entries in research dossiers feels off in dogfood week, this workshop tunes the presentation |

---

**Spec Complete**: 2026-05-16
**Last Clarified**: 2026-05-16 (Session 1: 8 questions, 8 answers, 0 critical markers remaining)
**Spec Location**: `docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-spec.md`

**Next steps**:
- **Required**: run the **four** queued workshops (schema, CLI flow, AGENTS.md voice, harvest companion behavior) before `/plan-3-v2-architect`. The harvest workshop was added by Clarification Q4.
- After workshops: `/plan-3-v2-architect` to produce the single-phase task table (Mode is Simple).
- The two Open Questions remaining (task-boundary self-prompt, scaffolding consent) have soft recommendations and can be confirmed during plan-3 or deferred to dogfood week.
