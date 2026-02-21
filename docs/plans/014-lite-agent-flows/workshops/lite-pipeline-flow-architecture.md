# Workshop: Lite Pipeline Flow & Architecture

**Type**: CLI Flow + State Machine
**Plan**: 014-lite-agent-flows
**Spec**: [lite-agent-flows-spec.md](../lite-agent-flows-spec.md)
**Created**: 2026-02-20T23:20:00Z
**Status**: Draft

**Related Documents**:
- [Research Dossier](../research-dossier.md) — full audit of non-pure concepts
- [Plan-6 Progress Tracking Workshop](./plan-6-inline-progress-tracking.md) — 3-step inline tracking design
- [Plan-3 Research Subagent Workshop](./plan-3-research-subagent-rewrite.md) — grep/glob/view subagent design
- Full pipeline reference: `agents/commands/README.md`, `agents/commands/GETTING-STARTED.md`

---

## Purpose

Visualize the complete lite agent pipeline end-to-end. This is the reference blueprint for what the lite extraction produces — every command, every connection, every artifact, every state transition. If it's not in this workshop, it's not in lite.

## Key Questions Addressed

- What does the lite pipeline look like as a whole?
- How does each command connect to the next?
- What does a per-phase implementation cycle look like without plan-6a?
- What files and folders does the lite pipeline create?
- How does traceability work without footnotes or FlowSpace?
- What does plan-3's research look like with standard tools?
- How does lite compare to the full pipeline?

---

## 1. The Big Picture

```mermaid
flowchart TB
    subgraph specify["SPECIFY (Once per feature)"]
        P1A["/plan-1a<br/>Explore"]
        P1B["/plan-1b<br/>Specify"]
        P2C["/plan-2c<br/>Workshop"]
        P3["/plan-3<br/>Architect"]
    end

    subgraph implement["IMPLEMENT (Per phase)"]
        P5["/plan-5<br/>Phase Tasks"]
        P5B["/plan-5b<br/>Flight Plan"]
        P6["/plan-6<br/>Implement"]
        P7["/plan-7<br/>Review"]
    end

    subgraph utilities["UTILITIES (Anytime)"]
        DYK["/didyouknow<br/>Build Understanding"]
        DR["/deepresearch<br/>External Knowledge"]
    end

    P1A -.-> P1B
    P1B -.-> P2C
    P2C -.-> P3
    P1B --> P3

    P3 --> P5
    P5 -->|auto| P5B
    P5 --> P6
    P6 --> P7

    P7 -->|Next phase| P5
    P7 -.->|fixes| P6

    DYK -.-> P5
    DYK -.-> P6
    DR -.-> P1A
    DR -.-> P3

    style P1A fill:#fff3e0
    style P1B fill:#e3f2fd
    style P2C fill:#fff3e0
    style P3 fill:#fff9c4
    style P5 fill:#e8f5e9
    style P5B fill:#e8f5e9
    style P6 fill:#c8e6c9
    style P7 fill:#fce4ec
    style DYK fill:#e1f5fe
    style DR fill:#e1f5fe
```

**10 commands. Zero infrastructure dependencies. Standard tools only.**

---

## 2. Detailed Command Flow

```mermaid
graph TD
    Start([Start Feature]) --> P1A["🔍 plan-1a-explore<br/>Codebase research<br/><i>optional</i>"]
    Start --> P1B["📋 plan-1b-specify<br/>Feature specification"]
    P1A --> P1B

    P1B -.-> P2C["🔬 plan-2c-workshop<br/>Deep design docs<br/><i>optional</i>"]
    P2C -.-> P3
    P1B --> P3["🏗️ plan-3-architect<br/>Implementation plan<br/><i>4 research subagents</i>"]

    P3 --> PhaseLoop{For each phase}

    PhaseLoop --> P5["📝 plan-5<br/>Phase tasks + brief"]
    P5 -->|auto-generates| P5B["✈️ plan-5b-flightplan<br/>Phase summary"]

    P5 --> DYK["💡 didyouknow<br/><i>recommended</i>"]
    DYK --> P6
    P5 --> P6["⚡ plan-6-implement<br/>Write code + track progress<br/><i>3-step inline updates</i>"]

    P6 --> P7["🔍 plan-7-code-review<br/>Diff review + verdict"]

    P7 --> NextPhase{More phases?}
    NextPhase -->|Yes| PhaseLoop
    NextPhase -->|No| End([Feature Complete])

    P7 -->|REQUEST_CHANGES| P6

    DR["📚 deepresearch<br/><i>anytime</i>"] -.->|feeds| P1A
    DR -.->|feeds| P3

    style Start fill:#c8e6c9
    style End fill:#c8e6c9
    style P1A fill:#fff3e0
    style P1B fill:#e3f2fd
    style P2C fill:#fff3e0
    style P3 fill:#fff9c4
    style P5 fill:#e8f5e9
    style P5B fill:#e8f5e9
    style DYK fill:#e1f5fe
    style P6 fill:#c8e6c9
    style P7 fill:#fce4ec
    style DR fill:#e1f5fe
```

---

## 3. Lite vs Full Pipeline Comparison

```mermaid
flowchart LR
    subgraph lite["LITE (10 commands)"]
        direction TB
        L1["Spec"] --> L3["Architect"]
        L3 --> L5["Phase Tasks"] --> L6["Implement"] --> L7["Review"]
        L7 -->|next| L5
    end

    subgraph full["FULL (24 commands)"]
        direction TB
        F0["Constitution"] --> F1["Spec"] --> F2["Clarify"] --> F3["Architect"]
        F3 --> F4["Validate"] --> F5["Phase Tasks"] --> F6["Implement"]
        F6 -->|"auto-6a"| F6
        F6 --> F7["Review"]
        F7 -->|next| F5
    end

    style lite fill:#e8f5e9
    style full fill:#fff3e0
```

### What Lite Drops

| Full Pipeline | Lite | Why |
|--------------|------|-----|
| plan-0-constitution | ❌ Dropped | CS rubric inlined into plan-3 |
| plan-2-clarify | ❌ Dropped | Key questions absorbed into plan-3 gate |
| plan-2b-prep-issue | ❌ Dropped | External tracker — not core flow |
| plan-3a-adr | ❌ Dropped | ADR docs optional, can be done manually |
| plan-4-complete-the-plan | ❌ Dropped | Readiness gate — plan-3 goes direct to plan-5 |
| plan-5c-requirements-flow | ❌ Dropped | AC tracing — plan-7 catches gaps |
| plan-6a-update-progress | ❌ Inlined | 3-step inline tracking replaces 8-subagent delegation |
| plan-6b-worked-example | ❌ Dropped | Optional examples — not core flow |
| plan-8-merge | ❌ Dropped | Git merge — manual when needed |
| planpak | ❌ Dropped | Feature-based file org — always Legacy in lite |
| tad | ❌ Dropped | TAD guide — testing approach still available |
| util-0-handover | ❌ Dropped | Handover docs — not core flow |
| code-concept-search | ❌ Dropped | FlowSpace-dependent concept search |
| flowspace-research | ❌ Dropped | FlowSpace-dependent research worker |

---

## 4. Command-by-Command Flow

### 4a. Specification Phase

```mermaid
stateDiagram-v2
    [*] --> Explore: /plan-1a-explore (optional)

    state Explore {
        [*] --> AutoDetect: Auto-detect or create plan folder
        AutoDetect --> LaunchSubagents: Launch 7 research subagents
        LaunchSubagents --> Synthesize: Deduplicate & prioritize
        Synthesize --> WriteDossier: Write research-dossier.md
    }

    Explore --> Specify: /plan-1b-specify

    state Specify {
        [*] --> ReadContext: Read dossier (if exists)
        ReadContext --> WriteSpec: Generate spec (WHAT & WHY only)
        WriteSpec --> AssessCS: Score complexity (CS 1-5)
        AssessCS --> IdentifyWorkshops: Flag Workshop Opportunities
    }

    Specify --> Workshop: /plan-2c-workshop (if workshops identified)
    Workshop --> Architect
    Specify --> Architect: /plan-3-architect

    state Architect {
        [*] --> EntryGate: Check spec quality
        EntryGate --> AskQuestions: Ask 2-3 key questions inline
        AskQuestions --> Research: Launch 4 research subagents
        Research --> GeneratePlan: Synthesize findings → plan
        GeneratePlan --> [*]
    }

    Architect --> [*]: Plan ready → /plan-5
```

### 4b. Implementation Cycle (Per Phase)

```mermaid
stateDiagram-v2
    [*] --> PhaseTasks: /plan-5

    state PhaseTasks {
        [*] --> ReadPlan: Load plan + phase definition
        ReadPlan --> PreImplAudit: Pre-implementation audit
        PreImplAudit --> GenerateTasks: Create tasks + alignment brief
        GenerateTasks --> GenerateFlightPlan: Auto-call /plan-5b
    }

    PhaseTasks --> DidYouKnow: /didyouknow (recommended)
    PhaseTasks --> Implement: /plan-6

    DidYouKnow --> Implement

    state Implement {
        [*] --> PickTask: Pick next pending task
        PickTask --> WriteCode: Write code for task
        WriteCode --> InlineTrack: 3-step progress update
        InlineTrack --> MoreTasks: More tasks?
        MoreTasks --> PickTask: Yes
        MoreTasks --> CompletionCheck: No — all done
        CompletionCheck --> [*]
    }

    Implement --> Review: /plan-7

    state Review {
        [*] --> LoadDiff: Load git diff + plan context
        LoadDiff --> LaunchValidators: Launch review subagents
        LaunchValidators --> SynthesizeFindings: Compile findings
        SynthesizeFindings --> Verdict: APPROVE or REQUEST_CHANGES
    }

    Review --> PhaseTasks: APPROVE → next phase
    Review --> Implement: REQUEST_CHANGES → fix

    Review --> [*]: Last phase → Feature Complete
```

---

## 5. Plan-3 Research Architecture

```mermaid
graph TD
    P3["plan-3-architect<br/><i>orchestrator</i>"] --> GATE["Entry Gate<br/>Check spec + ask 2-3 Qs"]

    GATE --> LAUNCH["Launch 4 Parallel Subagents"]

    LAUNCH --> S1["S1: Codebase Pattern Analyst<br/>glob → grep → view<br/><i>8-12 findings</i>"]
    LAUNCH --> S2["S2: Technical Investigator<br/>grep → view → glob<br/><i>6-10 findings</i>"]
    LAUNCH --> S3["S3: Discovery Documenter<br/>grep → view → glob<br/><i>6-10 findings</i>"]
    LAUNCH --> S4["S4: Dependency Mapper<br/>grep → glob → view<br/><i>6-10 findings</i>"]

    S1 --> SYNC["Synthesis"]
    S2 --> SYNC
    S3 --> SYNC
    S4 --> SYNC

    SYNC --> DEDUP["Deduplicate<br/>across subagents"]
    DEDUP --> PRIORITIZE["Prioritize<br/>by impact"]
    PRIORITIZE --> GROUP["Group into:<br/>Architecture · Constraints · Testing · Risks"]
    GROUP --> PLAN["Feed into plan generation<br/>phases, tasks, ACs"]

    style P3 fill:#fff9c4
    style GATE fill:#f3e5f5
    style LAUNCH fill:#e1f5fe
    style S1 fill:#e8f5e9
    style S2 fill:#e8f5e9
    style S3 fill:#e8f5e9
    style S4 fill:#e8f5e9
    style SYNC fill:#fff3e0
    style PLAN fill:#c8e6c9
```

### What Each Subagent Does

```
┌──────────────────────────────────────────────────────┐
│  S1: CODEBASE PATTERN ANALYST                        │
│                                                      │
│  "How does the code work?"                           │
│                                                      │
│  • Glob: find source files in feature domain         │
│  • Grep: naming conventions, existing patterns       │
│  • View: examine key files, understand structure     │
│                                                      │
│  Output: Conventions, integration points, file org   │
├──────────────────────────────────────────────────────┤
│  S2: TECHNICAL INVESTIGATOR                          │
│                                                      │
│  "What could go wrong?"                              │
│                                                      │
│  • Grep: error handling, validation, config patterns │
│  • View: API definitions, schema files, CI configs   │
│  • Glob: test files, dependency manifests            │
│                                                      │
│  Output: Constraints, gotchas, API limits            │
├──────────────────────────────────────────────────────┤
│  S3: DISCOVERY DOCUMENTER                            │
│                                                      │
│  "What's missing from the spec?"                     │
│                                                      │
│  • Grep: edge case handling, validation rules        │
│  • View: test files for expected behavior            │
│  • Glob: docs, READMEs, architecture notes           │
│                                                      │
│  Output: Gaps, edge cases, conflicting assumptions   │
├──────────────────────────────────────────────────────┤
│  S4: DEPENDENCY MAPPER                               │
│                                                      │
│  "What connects to what?"                            │
│                                                      │
│  • Grep: imports, function calls, module references  │
│  • Glob: all files in target directories             │
│  • View: module interfaces, public APIs              │
│                                                      │
│  Output: Dependency graph, boundaries, shared state  │
└──────────────────────────────────────────────────────┘
```

---

## 6. Plan-6 Implementation & Progress Tracking

### Per-Task Cycle

```mermaid
graph TD
    START["Pick task from plan"] --> CODE["Write code for task"]
    CODE --> STEP1["STEP 1: Update checkbox<br/>[ ] → [x] in task table"]
    STEP1 --> STEP2["STEP 2: Add log anchor<br/>log#task-t00N-slug in Notes"]
    STEP2 --> STEP3["STEP 3: Append exec log entry<br/>## Task T00N in execution.log.md"]
    STEP3 --> MORE{More tasks?}
    MORE -->|Yes| START
    MORE -->|No| DONE["Verify all 3 steps per task<br/>Suggest /plan-7-code-review"]

    style START fill:#e3f2fd
    style CODE fill:#fff9c4
    style STEP1 fill:#e8f5e9
    style STEP2 fill:#e8f5e9
    style STEP3 fill:#e8f5e9
    style DONE fill:#c8e6c9
```

### Task Table State Machine

```mermaid
stateDiagram-v2
    [*] --> Pending: Task created by plan-5

    Pending --> InProgress: Start working
    InProgress --> Completed: Code done + 3-step update
    InProgress --> Blocked: Dependency unresolved
    Blocked --> InProgress: Blocker resolved
    Completed --> [*]

    note right of Pending: [ ] empty checkbox
    note right of InProgress: [~] tilde checkbox
    note right of Completed: [x] checked + log#anchor in Notes
    note right of Blocked: [!] bang + BLOCKED reason in Notes
```

### What Gets Written

```
┌─────────────────────────────────────────────────────────────┐
│  IN THE PLAN FILE (## Implementation > ### Tasks)           │
│                                                             │
│  | Status | ID   | Task         | Notes                  | │
│  |--------|------|--------------|------------------------| │
│  | [x]    | T001 | Setup config | log#task-t001-setup    | │
│  | [x]    | T002 | Add endpoint | log#task-t002-endpoint | │
│  | [ ]    | T003 | Add tests    |                        | │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  IN execution.log.md (sibling to plan file)                 │
│                                                             │
│  ## Task T001: Setup config                                 │
│  **Status**: Completed                                      │
│                                                             │
│  ### Changes Made:                                          │
│  - Created `src/config.py` with default loader              │
│  - Added `src/defaults.yaml` with default settings          │
│                                                             │
│  ### Test Results:                                          │
│  ```                                                        │
│  3 passed, 0 failed                                         │
│  ```                                                        │
│                                                             │
│  ### Notes:                                                 │
│  Used YAML over JSON for readability.                       │
│                                                             │
│  ---                                                        │
│                                                             │
│  ## Task T002: Add endpoint                                 │
│  **Status**: Completed                                      │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Plan-7 Code Review

```mermaid
graph TD
    P7["plan-7-code-review<br/><i>orchestrator</i>"] --> LOAD["Load Context<br/>Plan + Tasks + Diff + Exec Log"]

    LOAD --> VALIDATORS["Launch Review Subagents"]

    VALIDATORS --> V1["V1: Diff Analyst<br/>Code quality, patterns,<br/>architecture alignment"]
    VALIDATORS --> V2["V2: Test Validator<br/>Test coverage, test quality,<br/>testing approach compliance"]
    VALIDATORS --> V3["V3: Task↔Log Validator<br/>Every [x] has matching<br/>execution log entry"]
    VALIDATORS --> V4["V4: Task↔Diff Validator<br/>Log changes match<br/>actual git diff"]

    V1 --> SYNTHESIS["Synthesize Findings"]
    V2 --> SYNTHESIS
    V3 --> SYNTHESIS
    V4 --> SYNTHESIS

    SYNTHESIS --> VERDICT{Verdict}

    VERDICT -->|Clean| APPROVE["✅ APPROVE<br/>Advance to next phase"]
    VERDICT -->|Issues found| REQUEST["⚠️ REQUEST_CHANGES<br/>Generate fix-tasks.md"]

    APPROVE --> NEXT["/plan-5 for next phase"]
    REQUEST --> FIX["/plan-6 to address fixes"]

    style P7 fill:#fce4ec
    style LOAD fill:#e3f2fd
    style V1 fill:#fff3e0
    style V2 fill:#fff3e0
    style V3 fill:#fff3e0
    style V4 fill:#fff3e0
    style SYNTHESIS fill:#f3e5f5
    style APPROVE fill:#c8e6c9
    style REQUEST fill:#ffebee
```

---

## 8. Traceability Model (No Footnotes, No FlowSpace)

```mermaid
graph TD
    TASK["Task T001<br/>in plan task table<br/><i>[x] checked</i>"] <--> LOG["Log Entry<br/>execution.log.md<br/><i>## Task T001</i>"]

    LOG --> FILES["Changed Files<br/><i>listed in Changes Made</i>"]
    FILES <--> DIFF["Git Diff<br/><i>actual changes</i>"]

    TASK --> NOTES["Notes Column<br/><i>log#task-t001-slug</i>"]
    NOTES --> LOG

    PLAN["Plan Structure<br/><i>## Implementation</i>"] --> TASK
    PLAN --> AC["Acceptance Criteria<br/><i>Validation column</i>"]

    style TASK fill:#e3f2fd
    style LOG fill:#fce4ec
    style FILES fill:#e8f5e9
    style DIFF fill:#e8f5e9
    style NOTES fill:#fff3e0
    style PLAN fill:#fff9c4
    style AC fill:#f3e5f5
```

### Traceability Chain

```
Plan task table    →  Checkbox [x] proves completion
  └── Notes column →  log#anchor links to execution log
       └── Exec log →  Changes Made lists files modified
            └── Git diff →  Actual code changes (ground truth)
```

**No footnotes. No FlowSpace node IDs. No separate dossier.**
The execution log IS the detailed record. The task table IS the index.

---

## 9. Directory Structure Evolution

```mermaid
graph TD
    P1A["plan-1a-explore"] --> D1A["Creates:<br/>docs/plans/001-feature/"]
    D1A --> F1A["research-dossier.md"]

    P1B["plan-1b-specify"] --> D1B["Creates (or uses):<br/>docs/plans/001-feature/"]
    D1B --> F1B["feature-spec.md"]

    P2C["plan-2c-workshop"] --> D2C["Creates:<br/>workshops/"]
    D2C --> F2C["topic-name.md"]

    P3["plan-3-architect"] --> D3["Adds:"]
    D3 --> F3["feature-plan.md"]

    P6["plan-6-implement"] --> D6["Adds:"]
    D6 --> F6["execution.log.md"]

    P7["plan-7-review"] --> D7["Creates:<br/>reviews/"]
    D7 --> F7["review.md<br/>fix-tasks.md"]

    style P1A fill:#fff3e0
    style P1B fill:#e3f2fd
    style P2C fill:#fff3e0
    style P3 fill:#fff9c4
    style P6 fill:#c8e6c9
    style P7 fill:#fce4ec
```

### Final Directory Tree

```
docs/plans/
└── 001-my-feature/
    ├── research-dossier.md          ← plan-1a (optional)
    ├── my-feature-spec.md           ← plan-1b
    ├── my-feature-plan.md           ← plan-3 (with inline tasks)
    ├── execution.log.md             ← plan-6 (progress record)
    ├── workshops/                   ← plan-2c (optional)
    │   ├── data-model.md
    │   └── cli-flows.md
    └── reviews/                     ← plan-7 (optional)
        ├── review.md
        └── fix-tasks.md
```

**That's it.** 3-6 files in 1-2 subdirectories. Compare to the full pipeline's ~15+ files across 7 directories.

---

## 10. Testing Strategy (Simplified)

```mermaid
graph TD
    P3["plan-3-architect<br/>Entry Gate"] --> Q["Ask: Testing Approach?"]

    Q --> STD["Standard<br/>Unit + integration tests"]
    Q --> LIGHT["Lightweight<br/>Core validation only"]
    Q --> NONE["None<br/>Manual verification"]

    STD --> PLAN["Encode in plan<br/><i>Testing: Standard</i>"]
    LIGHT --> PLAN
    NONE --> PLAN

    PLAN --> P6["plan-6 reads approach<br/>applies per task"]
    P6 --> P7["plan-7 validates<br/>tests match approach"]

    style P3 fill:#fff9c4
    style Q fill:#f3e5f5
    style STD fill:#e3f2fd
    style LIGHT fill:#e8f5e9
    style NONE fill:#fff3e0
    style P6 fill:#c8e6c9
    style P7 fill:#fce4ec
```

**No TDD/TAD/Hybrid complexity.** Three clear choices. plan-3 asks during its entry gate, writes the answer into the plan, and plan-6 + plan-7 respect it.

---

## 11. Standalone Utilities

```mermaid
graph LR
    subgraph anytime["Use anytime — no pipeline position required"]
        DYK["💡 /didyouknow<br/><br/>Surface 5 insights<br/>from any context<br/><br/><i>Best after: spec,<br/>plan, or tasks</i>"]

        DR["📚 /deepresearch<br/><br/>Structured prompt<br/>for external research<br/><br/><i>Best for: gaps<br/>code can't answer</i>"]

        WS["🔬 /plan-2c-workshop<br/><br/>Deep design doc<br/>for complex concepts<br/><br/><i>Best before:<br/>plan-3-architect</i>"]
    end

    style DYK fill:#e1f5fe
    style DR fill:#e1f5fe
    style WS fill:#fff3e0
```

---

## 12. Complete Pipeline Sequence Diagram

```mermaid
sequenceDiagram
    actor User
    participant 1a as plan-1a<br/>explore
    participant 1b as plan-1b<br/>specify
    participant 3 as plan-3<br/>architect
    participant 5 as plan-5<br/>phase tasks
    participant 6 as plan-6<br/>implement
    participant 7 as plan-7<br/>review

    User->>1a: /plan-1a-explore (optional)
    1a->>1a: Launch 7 research subagents
    1a-->>User: research-dossier.md

    User->>1b: /plan-1b-specify
    1b->>1b: Generate spec (WHAT/WHY)
    1b-->>User: feature-spec.md

    Note over User: Optional: /plan-2c-workshop, /didyouknow

    User->>3: /plan-3-architect
    3->>3: Entry gate (check spec, ask Qs)
    3->>3: Launch 4 research subagents
    3->>3: Synthesize → generate plan
    3-->>User: feature-plan.md

    loop Each Phase
        User->>5: /plan-5 --phase "Phase N"
        5->>5: Generate tasks + brief
        5->>5: Auto-generate flight plan
        5-->>User: Tasks ready

        Note over User: Recommended: /didyouknow

        User->>6: /plan-6 --phase "Phase N"
        loop Each Task
            6->>6: Write code
            6->>6: Step 1: Update checkbox [x]
            6->>6: Step 2: Add log#anchor to Notes
            6->>6: Step 3: Append execution log
        end
        6-->>User: Phase implemented

        User->>7: /plan-7 --plan "..."
        7->>7: Load diff + context
        7->>7: Launch review subagents
        alt APPROVE
            7-->>User: ✅ Next phase
        else REQUEST_CHANGES
            7-->>User: ⚠️ fix-tasks.md → back to /plan-6
        end
    end

    Note over User: Feature Complete 🎉
```

---

## 13. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    LITE PIPELINE CHEATSHEET                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SPECIFY                                                    │
│    /plan-1a-explore          Research codebase (optional)   │
│    /plan-1b-specify          Write feature spec             │
│    /plan-2c-workshop         Deep design docs (optional)    │
│    /plan-3-architect         Generate implementation plan   │
│                                                             │
│  IMPLEMENT (repeat per phase)                               │
│    /plan-5                   Generate phase tasks            │
│    /plan-5b-flightplan       Phase summary (auto)           │
│    /plan-6-implement-phase   Write code + track progress    │
│    /plan-7-code-review       Review → APPROVE or FIX        │
│                                                             │
│  UTILITIES (anytime)                                        │
│    /didyouknow               5 insights from any context    │
│    /deepresearch             External research prompts      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PROGRESS TRACKING (inline in plan-6, no delegation)        │
│    1. [x] checkbox in task table                            │
│    2. log#anchor in Notes column                            │
│    3. ## Task entry in execution.log.md                     │
│                                                             │
│  TESTING (chosen in plan-3 entry gate)                      │
│    Standard · Lightweight · None                            │
│                                                             │
│  FILES CREATED                                              │
│    docs/plans/<ord>-<slug>/                                 │
│      ├── research-dossier.md    (plan-1a)                   │
│      ├── <slug>-spec.md         (plan-1b)                   │
│      ├── <slug>-plan.md         (plan-3)                    │
│      ├── execution.log.md       (plan-6)                    │
│      ├── workshops/*.md         (plan-2c)                   │
│      └── reviews/*.md           (plan-7)                    │
│                                                             │
│  TOOLS REQUIRED                                             │
│    grep · glob · view · bash    (standard — no FlowSpace)   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Resolved Questions

### Q: What does the lite pipeline look like as a whole?
**RESOLVED**: 10 commands in 3 groups — Specify (4), Implement (4), Utilities (2). Linear flow with a per-phase loop. See §1-2.

### Q: How does traceability work without footnotes or FlowSpace?
**RESOLVED**: Task checkbox → log anchor → execution log entry → git diff. Four-link chain, all plain text. See §8.

### Q: What does plan-3's research look like with standard tools?
**RESOLVED**: 4 parallel subagents using grep/glob/view. Same roles as full pipeline, ~80% finding volume. See §5.

### Q: How does the per-phase cycle work without plan-6a?
**RESOLVED**: 3-step inline tracking per task (checkbox, log anchor, exec log entry). No delegation, no footnotes, no subagents. See §6.
