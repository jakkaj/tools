# Stage 61 — Implement Phase (Companion)
*(absorbed from `plan-6-v2-implement-phase-companion`; loaded lazily via `/the-flow 6c companion` or `/the-flow companion` — dispatch: `../../SKILL.md`)*

**Purpose**: Implement exactly one approved phase with a parallel `code-review-companion` agent (Power-On-Mode) that reviews every commit live — inline review supersedes the post-hoc review stage (`/the-flow 7 review`).
**Entry conditions**: Same as stage 60 (plan READY, tasks dossier or inline tasks, human GO) **plus** `minih` on `$PATH` and a bootable companion agent slug. `--no-companion` (or a failed boot) falls back to the standard implement flow.
**Inputs**: Flags `--phase "<Phase N: Title>"` (Full Mode) or omitted (Simple Mode), `--plan "<abs path to plan.md>"`, optional `--subtask "<ORD-subtask-slug>"`, optional `--companion-slug "<slug>"` (default: `code-review-companion`), optional `--no-companion`. Reads the plan's Testing Strategy, task table, Context Brief / Key Findings, domain context.
**Output contract**: Everything stage 60 produces (code + tests, execution log, domain.md updates, diffs, evidence, suggested commit message) **plus** companion artifacts: per-commit review-request pings logged with finding dispositions, the companion findings reconciliation table, farewell envelope summary, and the companion's magicWand surfaced as a follow-up candidate (the debrief itself runs in `references/stages/62-progress.md` Step 9).
**Next routing**: Another phase remains → `/the-flow 5 tasks --phase "<Phase N+1: Title>" --plan "<PLAN_PATH>"` (module `references/stages/50-phase-tasks.md`), then re-run this stage. Final phase → `/the-flow 8 merge --plan "<PLAN_PATH>"` (module `references/stages/80-merge.md` — stage 80 owns the `plan-complete` harness seam, fired after merge execution). `/the-flow 7 review` is **NOT** required after this stage. Final-task progress + companion debrief delegate to sibling module `references/stages/62-progress.md` (also `/the-flow 6a progress`).

---

## Procedure

Implement **exactly one** approved phase or subtask **with a parallel `code-review-companion` agent** running in Power-On-Mode. The companion reviews every commit live, fires findings asynchronously, and writes a farewell envelope you read before reporting completion.

This stage is a sibling of the standard implement stage (`/the-flow 6 implement`, module `references/stages/60-implement.md`) — same domain placement rules, same testing approach, same progress-tracking discipline — but with **inline review by a companion** instead of a separate post-hoc `/the-flow 7 review` review pass.


## 🎯 Why a companion (read this first)

> **A companion is the cheapest review you'll ever buy.** It's already running. It's already paid for. It's watching.

Post-hoc review (`/the-flow 7 review`) catches issues *after* a phase lands — by which point the cost of a fix is much higher: context is gone, you've moved on, the fix needs its own commit, its own review pass, its own integration. You pay the cost of being wrong twice.

A **code-review-companion** running in parallel:

1. **Reviews each commit at commit time** — when context is fresh, fixes are cheap, and the diff is small.
2. **Runs in its own SDK session, in its own process** — it's a *real* second pair of eyes, not a self-review by the same agent.
3. **Fire-and-forget** — pings cost milliseconds; the companion only replies if it finds issues. Zero latency on the hot path.
4. **Asynchronous parallelism** — the main agent commits T002 while the companion is still reviewing T001. Throughput stays high; review depth stays deep.
5. **Closes the loop deterministically** — at phase end, a `control:stop` triggers a farewell envelope that captures everything the companion saw across the phase. You fold those findings into your final report.
6. **Closes with a farewell debrief** — findings are reconciled into the final report and the companion's magicWand is surfaced as a follow-up candidate. Long-horizon harness reflection (retros, harvest) happens at the `plan-complete` seam, which stage 80 (merge) fires after merge execution — never this stage.

The companion replaces the post-hoc review stage (`/the-flow 7 review`) for projects that have one. **Do not run `/the-flow 7 review` after this stage.** The companion has already done that work, more thoroughly, with cheaper fixes.


## 🛟 If you don't know minih

This skill drives the companion through `minih` (the canonical companion runtime). If you're unfamiliar with minih, self-onboard with these resources — *do this BEFORE Step 0*:

| Resource | URL / command | When |
|---|---|---|
| **Full agent-author guide** | https://github.com/AI-Substrate/minih/blob/main/AGENTS_README.md | Read this if minih's surface area is new to you. |
| **Same guide, in-CLI** | `minih agent-readme` | Offline / fast — dumps the AGENTS_README to stdout. **Prefer this over the URL.** |
| **Companion-mode protocol** | https://github.com/AI-Substrate/minih/blob/main/docs/how/companion-mode.md | Power-On-Mode protocol details, farewell envelope shape, control signals. |
| **Top-level help** | `minih --help` | Confirm `minih` is on `$PATH` and lists the subcommands this skill uses. |
| **Install (if missing)** | https://github.com/AI-Substrate/minih.git | Clone + follow the README's install instructions if `minih` isn't installed. |

**If `minih --version` fails** (not on `$PATH`):
- First, point the user at `https://github.com/AI-Substrate/minih` to install.
- If install isn't an option for this session, **fall back to running without companion** — log the deviation in the execution log and proceed with the standard implement flow (`references/stages/60-implement.md`) (you may then run `/the-flow 7 review` afterward as a recovery review). Do NOT block the phase.

When this skill writes references in execution logs, surfaces companion findings, or briefs users — **link the canonical URLs above** so future readers can self-onboard the same way.


## 📝 LOG DISCOVERIES AS YOU GO

Throughout implementation, capture discoveries in:
1. **Execution Log** (`execution.log.md`) — detailed narrative, including companion ping timings + finding IDs as they arrive
2. **Discoveries Table** (`## Discoveries & Learnings` in tasks.md or plan) — structured record

Log when you encounter: something unexpected, needed research, hit a trouble spot, found a gotcha, made a decision, introduced debt, or gained an insight. **Always log companion findings** with their `ackOf` mapping back to the review-request you sent.


## 🛑 MANDATORY: UPDATE PROGRESS AFTER EVERY TASK — NO EXCEPTIONS

The user watches the task table and execution log for live progress. Keeping them current is **highest priority**.

After EACH task you MUST update these locations before proceeding to the next task:

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Per-Task Progress Checklist — use this EVERY time, NO EXCEPTIONS    ┃
┃                                                                     ┃
┃ STARTING T00X:                                                      ┃
┃ [ ] Tasks Table: [ ] → [~]                                          ┃
┃ [ ] Architecture Map: T00X node → :::inprogress (orange)            ┃
┃                                                                     ┃
┃ COMPLETING T00X:                                                    ┃
┃ [ ] Tasks Table: [~] → [x]                                          ┃
┃ [ ] Architecture Map: T00X node → :::completed (green)              ┃
┃ [ ] Architecture Map: File nodes touched → :::completed             ┃
┃ [ ] Execution Log: append task entry with evidence                  ┃
┃ [ ] Discoveries table: add any gotchas/insights found               ┃
┃ [ ] 📡 COMPANION: ping review-request: T00X <sha> (fire-and-forget)  ┃
┃ [ ] 📡 COMPANION: skim inbox for findings on prior review-requests   ┃
┃                                                                     ┃
┃ IF BLOCKED:                                                         ┃
┃ [ ] Tasks Table: mark task [!]; note the reason in the Execution Log┃
┃ [ ] (When unblocked: change back to [~] and continue)               ┃
┃                                                                     ┃
┃ ALL TASKS COMPLETE:                                                 ┃
┃ [ ] Tasks Table: confirm every phase task is [x]                    ┃
┃ [ ] Execution Log: append a phase-complete summary                  ┃
┃ [ ] PLAN progress section (if present): mark the phase complete     ┃
┃ [ ] 📡 COMPANION: drain ping → control:stop → read farewell          ┃
┃                                                                     ┃
┃ ✓ ALL UPDATES DONE → Proceed to next task                           ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Progress lives in the **task table** (in `tasks.md`, or inline in the plan for Simple Mode) and the **execution log** — there is no separate flight-plan file. The journey-level view (`the-flow.md`) is regenerated by `/the-flow` itself; this skill never writes it.

DO NOT start the next task until ALL updates above are done — **including the companion ping**.


```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>" (Full Mode) or omitted (Simple Mode)
# --plan "<abs path to plan.md>"
# --subtask "<ORD-subtask-slug>" (optional)
# --companion-slug "<slug>" (optional, default: code-review-companion)
# --no-companion (optional escape hatch — falls back to the standard implement
#   flow (/the-flow 6 implement) + /the-flow 7 review)

## Step 0: Boot or attach the companion

Skip this step if `--no-companion` was provided.

a) **Check for an active companion run:**

   ```bash
   COMPANION_SLUG="${companion_slug:-code-review-companion}"
   RUN_ID=$(minih status "$COMPANION_SLUG" 2>/dev/null | jq -r '.data | select(.verdict == "active") | .runId')
   ```

   The `verdict: 'active'` filter is load-bearing — `minih status` defaults to "latest run" which may be a completed one from a prior session.

b) **If no active run, boot one:**

   ```bash
   if [ -z "$RUN_ID" ]; then
     export GH_TOKEN=$(gh auth token)   # required; the spawning shell needs this
     minih run "$COMPANION_SLUG" &
     sleep 12
     RUN_ID=$(minih status "$COMPANION_SLUG" 2>/dev/null | jq -r '.data | select(.verdict == "active") | .runId')
   fi
   echo "Companion run: $RUN_ID"
   ```

   **Boot failure modes:**
   - `E122 GH_TOKEN not set` → `export GH_TOKEN=$(gh auth token)` and retry. The Copilot CLI runtime doesn't reliably inherit; explicit export is required.
   - Boot times out / no active run after 12s → wait another 30s, re-check. If still no active run after two attempts, **fall back to no-companion mode**: log the deviation in execution.log.md, proceed without companion, and run `/the-flow 7 review` afterward.
   - Agent slug doesn't exist → halt and ask user. Do NOT silently fabricate a slug.

c) **Verify the companion is alive:**

   ```bash
   minih status "$COMPANION_SLUG" 2>/dev/null | jq '.data | {verdict, currentlyRunningTool, selfReportedState}'
   ```

   If `verdict: 'dead'` after >30min silent — known false-positive when the companion is mid-tool-call. Check `currentlyRunningTool` and `selfReportedState` — both non-null = alive. Don't kill it.

## Step 0a: Brief the companion (one-shot, type=briefing)

Send ONE briefing message at session start:

```bash
minih outside inbox send "$COMPANION_SLUG" --run "$RUN_ID" \
  --type briefing \
  --subject "Plan <PLAN_SLUG>: <Phase Title> — Power On Mode start" \
  --body "Plan: <abs path to plan.md>
Spec: <abs path to spec.md>
Phase: <Phase N: Title>
Tasks doc: <abs path to tasks.md>

Protocol:
- I will ping at every per-task commit boundary as type=task with subject 'review-request: T### <sha>'
- Fire-and-forget; reply only if you find issues
- I'll send a final drain ping then control:stop when the phase is done

Hazards (from Key Findings):
- <hazard 1>
- <hazard 2>

Domain context:
- <domain 1> + <expectations from domain.md>
- <domain 2> + <expectations>

Please watch for: domain compliance violations, contract drift, anti-reinvention overlaps, scope creep beyond the task table."
```

Brief once. Don't re-brief mid-phase unless the scope materially changes (in which case send a `--type briefing` update with a new subject).

## 1) Resolve paths

   PLAN = provided --plan
   PLAN_DIR = dirname(PLAN)

   **Mode Detection**: Read PLAN for `**Mode**: Simple` or `**Mode**: Full`

   **Full Mode**:
   - PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}
   - PHASE_DOC = ${PHASE_DIR}/tasks.md
   - EXEC_LOG = ${PHASE_DIR}/execution.log.md
   - If --subtask: PHASE_DOC = ${PHASE_DIR}/${SUBTASK_KEY}.md

   **Simple Mode**:
   - Check for optional dossier: ${PLAN_DIR}/tasks/implementation/tasks.md
   - If exists → PHASE_DOC = that file
   - If not → PHASE_DOC = PLAN itself (inline tasks from § Implementation)
   - EXEC_LOG = ${PLAN_DIR}/execution.log.md

## 2) Load context

   - Read Testing Strategy from plan (approach + mock usage)
   - Read task table from PHASE_DOC
   - Read Context Brief / Key Findings for hazards to watch for
   - **Load domain context** per `references/00-routing.md` § Domain context loading
   - **Harness availability** (router-only): probe `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/eng-harness-flow/SKILL.md`) — the harness is reached exclusively through the `/eng-harness-flow` router; never read governance docs or run health checks yourself

## 2a) Pre-Phase Harness Seam — `--event pre-implement` (router-only)

   **Router not installed** (probe above misses) → if the flow already warned, proceed silently with standard testing; otherwise print exactly once, verbatim:

   > ⚠️ No engineering harness detected — the eng-harness skills aren't installed. Continuing without one: standard testing applies, nothing else changes. (To add the harness loop: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.)

   …then silently omit every harness touchpoint for the rest of the phase (record the outcome once in EXEC_LOG; never re-warn).

   **Router installed** → before starting ANY task, fire the seam:

   `/eng-harness-flow --event pre-implement --phase "<Phase N: Title>" --plan-dir "<PLAN_DIR>" --json`

   Act on the envelope (`decision: route|redirect|noop|ambiguous`): `route` → print-then-offer the returned command; setup-routing/`noop` → one calm line the first time (*"No engineering harness in this repo — proceeding without one; say 'set up a harness' anytime."*), then pass `--prompt-optional=false` on later seam calls. Boot verdicts are narrated **verbatim from the envelope** — vocabulary: `healthy / SLOW / UNHEALTHY / UNAVAILABLE`:
   - `healthy` → proceed to tasks
   - `SLOW` → proceed with note
   - `UNHEALTHY` → **stop and ask human**: "Retry" / "Continue without harness" / "Abort"
   - `UNAVAILABLE` → note and proceed with standard testing

   Log the seam outcome (envelope decision + verdict) to EXEC_LOG. If the human overrides an unhealthy harness, log the override reason. **Never copy the router's internal signals into this skill — delegate, don't reimplement.** Never call the router's child skills directly — children are private and may move.

## 3) Execute tasks

   Follow task order. Apply testing approach from plan:

   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
   ┃ 🛑 STOP! RE-READ "MANDATORY: UPDATE PROGRESS" SECTION ABOVE 🛑       ┃
   ┃                                                                    ┃
   ┃ After EACH task you MUST update ALL locations before proceeding:   ┃
   ┃   1. Tasks Table checkbox                                          ┃
   ┃   2. Architecture Map diagram nodes                                ┃
   ┃   3. Execution log entry                                           ┃
   ┃   4. 📡 COMPANION: review-request ping for T### at <sha>            ┃
   ┃   5. 📡 COMPANION: drain inbox for findings on prior tasks          ┃
   ┃                                                                    ┃
   ┃ Watch the task table + log — update them FIRST, then ping.         ┃
   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

   **Full TDD**: RED-GREEN-REFACTOR loop per task
   **Lightweight**: Minimal validation tests for core functionality
   **Manual**: Document verification steps, execute manually
   **Hybrid**: Apply approach per task annotation

   ### Per-task companion ping (after commit, before next task)

   For each task that produces a commit:

   ```bash
   SHA=$(git rev-parse --short HEAD)
   minih outside inbox send "$COMPANION_SLUG" --run "$RUN_ID" \
     --type task \
     --subject "review-request: T### $SHA" \
     --body "Diff: git show $SHA. Watch for: <task-specific concerns, e.g., domain boundary, contract change, scope drift>. Reply if you find issues."
   ```

   **Fire-and-forget.** Do NOT wait for a reply before starting the next task. The companion replies asynchronously only if it finds issues.

   ### Skim companion inbox between tasks (cheap)

   Before starting the next task, glance at the outside inbox for any findings:

   ```bash
   minih outside inbox list "$COMPANION_SLUG" --run "$RUN_ID" --since "<last check ts>" 2>/dev/null
   ```

   - **No new messages** → proceed to next task immediately.
   - **New `finding`-typed message** → read it. If `severity: HIGH|CRITICAL`, address inline before next task. If `MEDIUM|LOW`, queue for end-of-phase or address opportunistically. Either way, log the finding in execution.log.md with its `ackOf` mapping.
   - **New `summary` APPROVE** → great, log it; proceed.

   ### Handling companion findings inline

   When a finding lands:
   1. Read the full finding (file:line, category, recommendation).
   2. Decide: fix now, fix at end of phase, or document deferral with reasoning.
   3. If fixing: make the fix, commit it (typically as a `fix:` commit), and ping the new sha as another `review-request: <topic> <new-sha>`. The companion verifies the fix.
   4. If deferring: log the finding ID + reasoning in execution.log.md so the verdict reconciliation step (Step 6) can surface it.

   ### Domain Placement Rules

   1. Every new file MUST go under its declared domain's source directory
   2. Contract files (public interfaces) go in the domain's contracts/ directory
   3. Cross-domain imports MUST use the target domain's public contracts only
      (never import from another domain's internals)
   4. Dependency direction:
      - business → infrastructure: ✅ allowed
      - infrastructure → business: ❌ never
      - business → business: ⚠️ contracts only
   5. When creating a NEW domain (domain setup task):
      - Create `docs/domains/<slug>/domain.md` using format from /extract-domain
      - Create source directory structure
      - Update `docs/domains/registry.md`

## 4) After ALL tasks complete — update domain files

   For each domain touched by this phase:

   a) **Update domain.md § History**:
      ```markdown
      | [plan-ordinal-slug] | [What changed — 1 line summary] | [today] |
      ```

   b) **Update domain.md § Composition** (if new services/adapters/repos created):
      Add new rows to the composition table.

   c) **Update domain.md § Contracts** (if public interface changed):
      Add/modify contract entries.

   d) **Update domain.md § Dependencies** (if new domain relationships formed):
      Add to "This Domain Depends On" or "Domains That Depend On This".

   e) **Update domain.md § Source Location** (if new files added):
      Add file paths to source location listing.

   f) **Update docs/domains/registry.md** if domain status changed.

   g) **Update docs/domains/domain-map.md** if:
      - New domain was created → add node with exposed contracts
      - New contracts were added to existing domain → update node label
      - New cross-domain dependency formed → add labeled edge
      - Domain contracts changed → update the Health Summary table

   h) **Update domain.md § Concepts** (if contracts changed or new domain):

      For NEW domains:
        - Create Concepts table from implemented contracts
        - Group related contracts into named concepts (verb phrases)
        - Add narrative + code example per concept (base on actual implemented code)

      For CHANGED contracts:
        - Add new concepts to table if new capabilities introduced
        - Update existing concept narratives if entry points changed
        - Update code examples to match new signatures

      For UNCHANGED contracts: no Concepts updates needed.

## 5) Phase-end ceremony — delegate to the progress module (`references/stages/62-progress.md`)

   Skip this step if `--no-companion` was used (the progress module is
   still followed per task and on the last task — but Step 9 of
   `62-progress.md`, the companion debrief, is skipped because
   `--companion-run-id` is omitted).

   At end of phase (after the last task's commit + ping has settled),
   read `references/stages/62-progress.md` and follow it ONE MORE TIME
   for the final task with the companion debrief flags:

      ```bash
      --plan "<PLAN_PATH>" \
      --phase "<Phase N: Title>" \
      --task "<final-task-id>" \
      --status completed \
      --companion-run-id "$RUN_ID" \
      --companion-slug "$COMPANION_SLUG"
      ```

      `62-progress.md` Step 9 then handles the entire companion debrief
      automatically:
      - Drain ping → wait → control:stop → read farewell envelope
      - Reconcile findings (using execution-log disposition table you
        kept up-to-date during the phase per Step 3's "Handling companion
        findings inline")
      - Surface companion magicWand as follow-up candidate

   You don't run the drain ping, stop, or farewell read yourself — they
   live in the progress module (`references/stages/62-progress.md`).
   This is the single source of truth.

   **If the companion died mid-phase** (verdict became `stale` or
   `completed` before the final ping): pass `--companion-run-id` anyway.
   The progress module's Step 9 will detect the dead session via
   `minih status`, log the deviation, and skip the drain/stop steps but
   still attempt the farewell read (if the companion wrote one before
   exiting).

   Then fire the **phase-end harness seam** (router-only; skip silently
   if the router isn't installed — the one-time warning already fired):

   `/eng-harness-flow --event phase-end --plan-dir "<PLAN_DIR>" --json`

   …and act on the envelope. Best-effort, never blocks. (The
   `plan-complete` seam is **not** fired here — stage 80 owns it,
   after merge execution. If this was the final phase, the next step
   is merge analysis: `/the-flow 8 merge --plan "<PLAN_PATH>"`.)

## 6) Output

   - Execution Log with per-task entries (write incrementally throughout)
   - Unified diffs for all touched files
   - Evidence (test output, verification results)
   - Domain files updated (domain.md changes listed)
   - Final status mapped to acceptance criteria
   - **Companion findings reconciliation table** — prepared in execution
     log during the phase; surfaced in final summary by `62-progress.md`
     Step 9
   - **Companion farewell summary** — surfaced by `62-progress.md` Step 9
   - **Companion magicWand** (if present) — surfaced by `62-progress.md`
     Step 9
   - Suggested commit message

STOP: Report phase complete. Suggest next step.
```


**Phase complete.** Live review was handled by the `code-review-companion` running in parallel — every commit was reviewed at commit time, findings were folded back inline, and the farewell envelope is on file.

**`/the-flow 7 review` is NOT required after this stage** — it would duplicate the review the companion already performed (and you already addressed). Running it would re-litigate findings already resolved and add latency without value.

**Next step** — branch on remaining phases:

- **Another phase remains**: run `/the-flow 5 tasks --phase "<Phase N+1: Title>" --plan "<PLAN_PATH>"` (module `references/stages/50-phase-tasks.md`) to generate that phase's tasks dossier, then re-run this stage (`/the-flow 6c companion`).
- **That was the final phase**: run `/the-flow 8 merge --plan "<PLAN_PATH>"` (module `references/stages/80-merge.md`) for the merge analysis. Stage 80 owns the `plan-complete` harness seam, fired after merge execution.

If the companion produced a **magicWand** in its farewell, consider filing it as a fix dossier or backlog item *before* starting the next phase — that's how the harness improves itself.
---

## Harness seams (router-only)

This skill fires two harness seams, both through the single entry point `/eng-harness-flow` (children never called directly — they are private and may move):

- **Phase start** — § 2a fires `--event pre-implement --phase --plan-dir` before any task.
- **Phase end** — § 5 fires `--event phase-end --plan-dir` after the companion debrief settles.

The `plan-complete` seam is owned by stage 80 (merge) and fires after merge execution — never from this stage.

The minih companion machinery (pings, farewell envelope, findings reconciliation) is **code review**, not harness — it stays exactly as specified above. The router owns everything harness-side: state, verdicts, friction capture, retros. Best-effort throughout — no router installed means standard testing, one calm warning, and silence.
