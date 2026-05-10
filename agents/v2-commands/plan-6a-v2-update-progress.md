---
description: Update plan progress with task status and domain context. V2 standalone rewrite.
---


# plan-6a-v2-update-progress

Update plan and dossier progress tracking with task status. Adds domain context to change tracking. **Phase-end retrospective harvest** when called with `--retrospective` on the last task of a phase.

```md
User input:

$ARGUMENTS
# Expected flags:
# --plan "<abs path to plan.md>"
# --task "<task ID, e.g., T001>"
# --status "completed|in_progress|blocked"
# --changes "file1.md,file2.sh" (files changed)
# --domain "<domain slug>" (optional — inferred from task table if not provided)
# Optional:
# --phase "<Phase N: Title>" (Full Mode)
# --subtask "<subtask-key>" (if updating subtask)
# --inline (Simple Mode — update inline task table in plan)
# --retrospective '<json>' (orchestrator retro — see Step 8 below; only fires
#   when status=completed AND this is the last task of the phase)
# --companion-run-id "<run id>" (optional — if provided, signals that a
#   code-review-companion ran in parallel during the phase; triggers
#   Step 9 companion debrief on the last task)
# --companion-slug "<slug>" (optional, default: "code-review-companion" —
#   only used in conjunction with --companion-run-id)

## Steps

1) Resolve paths:
   - PLAN, PLAN_DIR from --plan
   - If --inline: update task table within PLAN itself
   - If --phase: locate dossier at PLAN_DIR/tasks/${PHASE_SLUG}/tasks.md
   - If --subtask: locate subtask dossier

2) Parse --changes as a list of changed file paths.

3) Determine domain:
   - If --domain provided, use it
   - Otherwise, read task table and extract Domain column for the task
   - If no domain found, use "unknown"

4) Update task status:
   - In task table (dossier or inline): update Status column
     * `completed` → `[x]`
     * `in_progress` → `[~]`
     * `blocked` → `[!]`
   - Update Architecture Map nodes if present

5) Update progress tracking in PLAN:
   - Locate progress section
   - Update phase/task status

6) Record changes with domain context:
   - Log which domain(s) were affected and what changed
   - Note any new components added to domain composition
   - Note any contract changes
   - Flag if `docs/domains/domain-map.md` needs updating (new contracts, new edges, new domains)
   - If contract changes recorded → flag "domain.md § Concepts update needed for <domain>"
   - If new domain created → flag "domain.md § Concepts creation needed for <domain>"

7) Update plan-level Flight Plan (if it exists):
   - Locate `${PLAN_DIR}/<slug>.fltplan.md`
   - If `--status completed` and this is the last task in a phase:
     * Update Journey Map: phase node class → `done`
     * Update Phases Overview table: status → Complete
     * Append Flight Log entry with phase summary and key changes
   - If `--status in_progress` and this is the first task in a phase:
     * Update Journey Map: phase node class → `active`
     * Update Phases Overview table: status → In Progress
     * Update plan-level Status: "Ready" → "In Progress" (if first phase starting)
   - Check off any acceptance criteria this phase satisfies

8) Orchestrator retrospective (phase-end harvest — fires ONLY when
   `--status completed` AND this is the last task of the phase):

   This step closes the compounding-value loop. The agent/companion's
   retrospective is auto-harvested via the runner; this is its mirror
   for the orchestrator (you, the agent driving plan-6).

   a) **If `--retrospective` flag was provided**:
      Parse the JSON. Expected shape (mirrors agent-side schema for symmetry):
      ```json
      {
        "magicWand": "If you could change one thing about this phase, the agent harness, or the engineering harness substrate that drove it, what would it be?",
        "magicWandTarget": "agent-harness | engineering-harness | project | coordination | testing | docs",
        "difficulties": [
          {
            "id": "OH-001",
            "category": "agent-harness | engineering-harness | review-flow | tooling | coordination | debug | docs",
            "description": "...",
            "workaround": "...",
            "severity": "blocker | annoying | minor"
          }
        ],
        "workedWell": "Optional — what went smoothly that should be preserved.",
        "notes": "Optional — anything else."
      }
      ```

      Both `magicWandTarget` and `difficulties[].category` distinguish
      `agent-harness` (Boot/Interact/Observe loop, governance doc, minih
      runtime) from `engineering-harness` (justfile/Makefile/dev script,
      test runner, seed scripts). Bare `harness` is not a valid value —
      future readers should be able to route the feedback to the right
      home without re-deriving which layer is meant.
      Use OH-XXX prefix for orchestrator difficulty IDs (mirrors MH-XXX
      for agent-side).

   b) **If `--retrospective` flag was NOT provided**:
      Prompt the caller (or, in interactive mode, the user) with these
      five questions:
        1. magicWand — one thing you'd change about this phase, the
           agent harness, or the engineering harness substrate
        2. magicWandTarget — which surface (agent-harness /
           engineering-harness / project / coordination / testing / docs)
           does the wand point at. Bare "harness" is not a valid value;
           pick the layer.
        3. difficulties[] — concrete friction you hit (with workaround
           + severity); same agent-harness vs engineering-harness
           distinction applies to the `category` field
        4. workedWell — what went smoothly that should be preserved
           (optional but encouraged)
        5. notes — anything else (optional)
      Skip the prompt only if the caller explicitly opts out via
      `--retrospective skip` (rare; logs a deviation note).

   c) **Append the retrospective to TWO destinations** (atomic per file):

      i. **Phase Flight Log entry** (just emitted in Step 7):
         Add a `### Orchestrator Retrospective` subsection to the entry
         with magicWand, magicWandTarget, difficulties[], workedWell.
         Cross-link to the agent/companion farewell when present
         (companion farewell already lands in `docs/retros/<agent-slug>.md`
         via auto-harvest).

      ii. **`docs/retros/<plan-slug>.md`** ledger:
         Append a phase entry alongside any agent/companion retros for
         the same plan-phase pair. Format:
         ```markdown
         ## <plan-id> Phase <N> — <ISO date>

         ### Orchestrator (model + skill)
         **magicWand**: <quote>
         **magicWandTarget**: <surface>
         **difficulties**:
         - OH-001 (<category>, <severity>): <description> — workaround: <workaround>
         **workedWell**: <quote>

         ### Agent / Companion (auto-harvested — see runs/<runId>/output/report.json)
         _Cross-link only; the runner already wrote this entry below or above._
         ```
         If the file does not exist, create it with a header pointing
         at this skill as the writer.

   d) **Surface significant findings as follow-up candidates**:
      If `magicWandTarget` is `agent-harness` or `engineering-harness`,
      or any `difficulty.severity == "blocker"`,
      print a stderr note recommending the caller file a fix dossier
      via `/plan-5-v2-phase-tasks-and-brief --fix "<summary>"`.
      Do NOT auto-create dossiers; surface only.

9) Companion debrief (phase-end conditional — fires ONLY when ALL of:
   `--status completed`, last-task-in-phase, AND `--companion-run-id`
   was provided):

   **If `--companion-run-id` was NOT provided → skip this entire step.**
   This is the "no companion ran" branch — Step 8's orchestrator retro
   stands alone, no debrief needed, no farewell to harvest.

   **If `--companion-run-id` WAS provided** (signals a companion ran in
   parallel during the phase, e.g. from `/plan-6-v2-implement-phase-companion`):

   a) **Drain ping** (give the companion a final-sweep opportunity):
      ```bash
      COMPANION_SLUG="${companion_slug:-code-review-companion}"
      FINAL_SHA=$(git rev-parse --short HEAD)
      minih outside inbox send "$COMPANION_SLUG" --run "$RUN_ID" \
        --type task \
        --subject "review-request: final $FINAL_SHA — DONE" \
        --body "Final commit for <Phase Title>. Please scan the entire
                phase commit range for: end-to-end correctness, anything
                you noticed across multiple commits, missing tests,
                unhandled edge cases. control:stop incoming after your
                reply."
      ```
      Wait 30-60 seconds for the companion to respond. Read inbox for
      any final findings. Address HIGH/CRITICAL inline if possible
      (this may produce one more commit + ping cycle BEFORE the stop).

   b) **Send control:stop**:
      ```bash
      minih outside inbox send "$COMPANION_SLUG" --run "$RUN_ID" \
        --type control \
        --subject "stop — phase done" \
        --body "stop — phase complete. Please write your farewell
                envelope and exit."
      ```

   c) **Read the farewell envelope via the dogfood path** (NOT by `cat`-ing
      output/report.json directly):
      ```bash
      # Preferred: aggregate retros across runs (in case minih harvested already)
      minih retros --slug "$COMPANION_SLUG" 2>/dev/null

      # Or: validate the latest run's output
      LAST_RUN_DIR=$(minih last-run "$COMPANION_SLUG" 2>/dev/null | jq -r '.data.runDir')
      minih validate "$COMPANION_SLUG" --file "$LAST_RUN_DIR/output/report.json" 2>/dev/null
      ```
      The farewell contains: `findings[]`, `summary`, `retrospective.magicWand`,
      `retrospective.coordination`, `retrospective.difficulties[]`.

   d) **Reconcile findings**: walk every finding from the farewell + any
      `finding`-typed messages received during the phase. For each:
      - **ADDRESSED INLINE** — fixed during the phase. Note the fix sha.
      - **DEFERRED WITH REASONING** — out-of-scope; document the deferral
        in execution.log.md and (if appropriate) a follow-up dossier.
      - **DISAGREE** — companion was wrong. Briefly justify and move on.
      Never ignore a finding silently. The disposition appears in the
      execution log + the user-facing final summary.

   e) **Append the companion's retro to `docs/retros/<plan-slug>.md`**
      alongside the orchestrator retro from Step 8c.ii. Format:
      ```markdown
      ### Companion (run <runId>)
      **summary**: <quote>
      **magicWand**: <quote>
      **magicWandTarget**: <surface>
      **difficulties**:
      - MH-001 (<category>, <severity>): <description> — workaround: <workaround>
      **coordination**:
      - peerUpdatesSent: <n>
      - unresolvedPeerRequests: <n>
      - statePublished: <bool>
      - notes: <quote>
      **findings reconciliation**: <X addressed inline, Y deferred, Z disagreed>
      ```
      The runner already auto-harvested the companion's retro into
      `docs/retros/<companion-slug>.md` — this entry is the **plan-scoped
      cross-link** that pairs the companion's view with the orchestrator's
      view for the same phase, so future plans can read both sides at once.

   f) **Surface the companion's magicWand as follow-up candidate**: if
      the magicWand is non-trivial, print a stderr note recommending the
      caller file a fix dossier via
      `/plan-5-v2-phase-tasks-and-brief --fix "<companion magicWand>"`.
      Do NOT auto-create dossiers; surface only.

10) Report what was updated:
    - Files touched (task table, plan progress, flight plan, retros ledger)
    - Whether orchestrator retrospective was harvested (yes/no/skipped)
    - Whether companion debrief fired (yes — runId / no — flag absent)
    - Any follow-up candidates surfaced
```

This command is the **single source of truth** for progress updates AND phase-end retrospective harvest AND companion debrief. Always delegate all three to this command rather than manually editing task tables, retro files, or hand-running drain/stop sequences.

**Why retros + companion debrief live here**: 6a already owns the "last task in phase" branch and writes the plan-level Flight Log entry. Adding the orchestrator retrospective (Step 8) and the conditional companion debrief (Step 9) means both `/plan-6-v2-implement-phase` and `/plan-6-v2-implement-phase-companion` get full phase-end ceremony coverage for free with zero duplication. The agent-side retro is auto-harvested by the runner per-run; 6a closes the orchestrator side and (if a companion ran) pairs the two streams in `docs/retros/<plan-slug>.md`.

**Call signature symmetry**:
- Non-companion plan-6: `/plan-6a-v2-update-progress --task <T> --status completed --plan <P> [--retrospective <json>]` — Step 9 skipped (no flag).
- Companion plan-6: `/plan-6a-v2-update-progress --task <T> --status completed --plan <P> --retrospective <json> --companion-run-id <RUN>` — Step 9 fires.