# Workshop: V2 Command Structure

**Type**: Integration Pattern
**Plan**: 015-plan-domain-system
**Created**: 2026-02-22
**Status**: Draft

**Related Documents**:
- [Domain System Design](./domain-system-design.md) — the domain system these commands implement
- [agents/commands/](../../../../agents/commands/) — v1 commands (unchanged)

---

## Purpose

Define which agent commands need v2 versions for the domain system, where they live, and how v1 and v2 coexist. The goal is **minimal duplication** — only create v2 commands where the domain system fundamentally changes the command's behavior.

## Key Questions Addressed

- Which commands need v2 versions and which stay as-is?
- How does the v2 directory relate to v1?
- How do v2 commands reference v1 behavior they inherit?
- What about the new `/extract-domain` command?
- How does the install/sync pipeline handle v2 commands?

---

## 1. Directory Structure

```
agents/
├── commands/              # v1 commands — UNTOUCHED
│   ├── plan-0-constitution.md
│   ├── plan-1a-explore.md
│   ├── plan-1b-specify.md
│   ├── plan-2-clarify.md
│   ├── plan-2b-prep-issue.md
│   ├── plan-2c-workshop.md
│   ├── plan-3-architect.md
│   ├── plan-3a-adr.md
│   ├── plan-4-complete-the-plan.md
│   ├── plan-5-phase-tasks-and-brief.md
│   ├── plan-5b-flightplan.md
│   ├── plan-5c-requirements-flow.md
│   ├── plan-6-implement-phase.md
│   ├── plan-6a-update-progress.md
│   ├── plan-6b-worked-example.md
│   ├── plan-7-code-review.md
│   ├── plan-8-merge.md
│   ├── planpak.md
│   ├── code-concept-search.md
│   ├── deepresearch.md
│   ├── didyouknow.md
│   ├── flowspace-research.md
│   ├── tad.md
│   └── util-0-handover.md
└── v2-commands/           # v2 commands — DOMAIN-AWARE
    ├── README.md          # Explains v2 relationship to v1
    ├── extract-domain.md  # NEW command (no v1 equivalent)
    ├── plan-1b-v2-specify.md
    ├── plan-2-v2-clarify.md
    ├── plan-3-v2-architect.md
    ├── plan-5-v2-phase-tasks-and-brief.md
    ├── plan-6-v2-implement-phase.md
    ├── plan-6a-v2-update-progress.md
    └── plan-7-v2-code-review.md
```

---

## 2. Impact Analysis — Which Commands Need V2?

### Classification Criteria

| Impact Level | Meaning | Action |
|-------------|---------|--------|
| **🔴 Structural** | Domain system changes the command's core output format, sections, or logic flow | Must have v2 |
| **🟡 Additive** | Domain system adds a new section or subagent but core flow is the same | V2 only if the addition is substantial enough that it can't be a small delta note |
| **🟢 Unchanged** | Command works as-is, or domain system doesn't affect it | No v2 needed |

### Full Command Assessment

| Command | Impact | Reason | V2? |
|---------|--------|--------|-----|
| `plan-0-constitution` | 🟢 Unchanged | Constitution defines project rules — domain system is a *project's* choice, not a constitution-level concern. Projects can document domain rules in their own `architecture.md`. | **No** |
| `plan-1a-explore` | 🟡 Additive | Adds one subagent focus area (scan `docs/domains/`). But the rest of the 7-subagent research is identical. Small enough to note in v2 architect as a preamble instruction. | **No** |
| `plan-1b-specify` | 🔴 Structural | Adds mandatory `## Target Domains` section with new/existing classification and new domain sketches. Changes the spec output format. | **Yes** |
| `plan-2-clarify` | 🔴 Structural | Replaces PlanPak vs Legacy question with Domain Review question. Changes clarification flow. | **Yes** |
| `plan-2b-prep-issue` | 🟢 Unchanged | Issue text generation doesn't change — it reads from spec/plan regardless of domain structure. | **No** |
| `plan-2c-workshop` | 🟢 Unchanged | Workshop creation is topic-driven, not organization-driven. Works identically. | **No** |
| `plan-3-architect` | 🔴 Structural | Major changes: domain-aware research, domain manifest replaces PlanPak manifest, SRP phase-per-domain design, domain setup tasks, removes all PlanPak conditional blocks. Heaviest v2 change. | **Yes** |
| `plan-3a-adr` | 🟢 Unchanged | ADR generation reads spec and generates decision records — domain system doesn't change ADR format. | **No** |
| `plan-4-complete-the-plan` | 🟢 Unchanged | Plan completeness validation — can check for domain manifest presence as part of existing validation checklist without a full v2. | **No** |
| `plan-5-phase-tasks-and-brief` | 🔴 Structural | Adds `Domain` column to task table, changes pre-implementation audit from plan-based to domain-based file validation, changes requirements flow tracing. | **Yes** |
| `plan-5b-flightplan` | 🟢 Unchanged | Flight plan summarizes tasks.md — picks up domain column automatically. | **No** |
| `plan-5c-requirements-flow` | 🟡 Additive | Traces through domains instead of just files — but this is driven by the task table input from plan-5-v2, not by its own logic change. | **No** |
| `plan-6-implement-phase` | 🔴 Structural | Replaces PlanPak's 5 placement rules with domain placement rules. Adds domain.md update requirements after implementation. | **Yes** |
| `plan-6a-update-progress` | 🔴 Structural | FlowSpace node IDs gain domain context. Footnote ledger format changes. | **Yes** |
| `plan-6b-worked-example` | 🟢 Unchanged | Worked examples demonstrate implementation — domain context comes from the plan/tasks, not from this command's logic. | **No** |
| `plan-7-code-review` | 🔴 Structural | Replaces PlanPak Compliance Validator subagent with Domain Compliance Validator. New validation rules for contract-only imports, dependency direction, domain.md currency. | **Yes** |
| `plan-8-merge` | 🟢 Unchanged | Merge analysis looks at upstream changes — domain system doesn't change merge logic. | **No** |
| `planpak` | 🟢 Deprecated by v2 | The domain system conceptually replaces PlanPak. `planpak.md` stays in v1 for backward compatibility. No v2 equivalent — its replacement is the domain system itself, spread across the v2 commands. | **No v2 — superseded** |
| `code-concept-search` | 🟢 Unchanged | Concept search works the same — in fact, v2 commands will *use* it more heavily for anti-reinvention checks. | **No** |
| `deepresearch` | 🟢 Unchanged | External research tooling, not affected. | **No** |
| `didyouknow` | 🟢 Unchanged | Clarity utility, not affected. | **No** |
| `flowspace-research` | 🟢 Unchanged | FlowSpace research tooling, not affected. | **No** |
| `tad` | 🟢 Unchanged | Test-assisted development workflow, not affected. | **No** |
| `util-0-handover` | 🟢 Unchanged | Handover generation, not affected. | **No** |

### Summary

| Category | Count | Commands |
|----------|-------|----------|
| **V2 needed** | 7 | plan-1b, plan-2, plan-3, plan-5, plan-6, plan-6a, plan-7 |
| **New command** | 1 | extract-domain |
| **Unchanged** | 17 | Everything else |
| **Superseded** | 1 | planpak (replaced by domain system) |

**Total v2-commands/: 8 files** (7 v2 versions + 1 new)

---

## 3. V2 Command Design Principles

### Inheritance Model

V2 commands **do not duplicate** v1 content. They use a layered approach:

```markdown
# plan-3-v2-architect

[Complete standalone rewrite — domain-aware, lean output]
[No reference to v1 — fully self-contained]
```

### Design Approach

V2 commands are **complete standalone rewrites**. They do not reference or inherit from v1. Each v2 command is a fully self-contained prompt that incorporates:
- Domain system concepts (from domain-system-design workshop)
- Lean output format (from lean-plan-task-design workshop)
- All necessary instructions without assuming v1 knowledge

### Why Standalone (Updated from Original Workshop)

- **Reliability**: LLMs don't reliably compose "read v1, apply overrides" — standalone commands work every time
- **Clarity**: Each v2 command is complete in itself — no cross-referencing needed
- **Lean opportunity**: Since we're rewriting, v2 commands incorporate the lean design from the start (plan-3 drops from 1446 to ~400-500 lines)
- **Independence**: V1 can evolve without breaking v2, and vice versa

---

## 4. Per-Command V2 Scope

### extract-domain.md (NEW — no v1 equivalent)

**Purpose**: Collaborative brownfield domain extraction — identify and formalize an existing code concept as a named domain without moving files.

**Sections**:
- Interactive exploration flow (research subagents scan codebase for concept)
- User collaboration prompts (boundary workshop, file cataloguing)
- domain.md generation (from discovered files and user decisions)
- registry.md update
- No file movement, no refactoring

**Estimated size**: ~200-300 lines (standalone, no v1 inheritance)

---

### plan-1b-v2-specify.md

**Standalone rewrite** of plan-1b-specify.

**Key changes from v1**: Adds mandatory `## Target Domains` section with new/existing domain classification and new domain sketches. Removes PlanPak references.

**Estimated size**: ~150-180 lines (v1 is 137 lines — similar size, different content)

---

### plan-2-v2-clarify.md

**Standalone rewrite** of plan-2-clarify.

**Key changes from v1**: Replaces PlanPak vs Legacy question with Domain Review question (confirm domain boundaries, check contracts, flag breaking changes). Removes File Management question.

**Estimated size**: ~120-150 lines (v1 clarify is compact — v2 swaps one question block)

---

### plan-3-v2-architect.md

**Standalone rewrite** of plan-3-architect. This is the **biggest v2 command** and also the biggest beneficiary of the lean redesign.

**Key changes from v1**:
- Domain detection replaces PlanPak detection
- 2 research subagents (down from 4), concise findings table
- Domain manifest replaces File Placement Manifest
- SRP phases per domain, domain setup tasks
- No testing philosophy section (reference spec)
- No example phases, no appendices
- No TAD/Footnote concepts
- Anchor conventions and graph traversal stay inline (simplified)

**Estimated size**: ~400-500 lines (v1 is 1446 lines)

---

### plan-5-v2-phase-tasks-and-brief.md

**Standalone rewrite** of plan-5-phase-tasks-and-brief.

**Key changes from v1**:
- 7-column task table with Domain column (down from 10)
- Prior-phase subagents produce 5 focused sections (down from 11 + synthesis)
- Simplified pre-implementation audit (domain-based, not plan-based)
- Context Brief replaces Alignment Brief (keep diagrams)
- Architecture Map kept
- Flight plan auto-generation kept
- Requirements flow optional (not default)
- No footnote stubs, evidence artifacts, ready check, commands-to-run

**Estimated size**: ~300-400 lines (v1 is 942 lines)

---

### plan-6-v2-implement-phase.md

**Standalone rewrite** of plan-6-implement-phase.

**Key changes from v1**: Domain placement rules replace PlanPak rules. Post-implementation domain.md updates required (History, Composition, Contracts, Dependencies). No PlanPak detection logic. No TAD workflow details.

**Estimated size**: ~250-350 lines (v1 size TBD — similar structure, different rules)

---

### plan-6a-v2-update-progress.md

**Standalone rewrite** of plan-6a-update-progress.

**Key changes from v1**: FlowSpace node IDs gain domain context. No TAD or Footnote concepts (per clarification). Domain.md update trigger when progress is recorded.

**Estimated size**: ~150-200 lines (smallest v2 — focused scope)

---

### plan-7-v2-code-review.md

**Standalone rewrite** of plan-7-code-review.

**Key changes from v1**: Domain Compliance Validator replaces PlanPak Compliance Validator. Anti-reinvention check via `/code-concept-search` against domain registry. Validates contract-only imports and dependency direction.

**Estimated size**: ~250-350 lines (v1 size TBD — similar structure, different validators)

---

## 5. The `extract-domain` Command — Full Design

This is the only **entirely new** command. Not a v2 of anything.

```markdown
# extract-domain

> Collaboratively identify and formalize an existing codebase concept
> as a named domain. No files are moved — this is about communication
> and traceability, not refactoring.

## Usage

/extract-domain <concept>              # Explore and extract
/extract-domain <concept> --domain <slug>  # Specify slug
/extract-domain --list                 # List existing domains

## Examples

/extract-domain "authentication"
/extract-domain "payment processing" --domain billing
/extract-domain --list
```

**Flow**:

```
Step 1: EXPLORE
  Launch research subagents to discover all code related to <concept>
  - Search for services, adapters, repos, controllers, models
  - Search for tests, config, middleware
  - Search docs/domains/ to check concept doesn't already exist
  - Use /code-concept-search for semantic discovery
  
  Output: File catalogue with roles

Step 2: PRESENT & WORKSHOP (interactive with user)
  Present discovered files in table:
  
  | # | File | Suspected Role | Include? |
  |---|------|---------------|----------|
  | 1 | src/services/auth-service.ts | Service | ✅ |
  | 2 | src/middleware/jwt.ts | Adapter | ? |
  | 3 | src/models/user.ts | Model (shared?) | ? |
  
  Ask user to confirm/adjust:
  - Which files belong to this domain?
  - Which are shared with other concepts?
  - What's the domain boundary (owns vs doesn't own)?
  - What are the public contracts others consume?

Step 3: DEFINE
  From user decisions, build:
  - Domain slug
  - Purpose (1-3 sentences)
  - Boundary (owns / doesn't own)
  - Contracts (public interfaces identified from code)
  - Composition (services, adapters, repos mapped from files)
  - Source Location (files WHERE THEY CURRENTLY LIVE)
  - Dependencies (other domains this one relates to)

Step 4: WRITE
  - Create docs/domains/<slug>/domain.md
  - Update docs/domains/registry.md
  - If docs/domains/ doesn't exist, create it with registry.md

Step 5: REPORT
  ✅ Domain extracted: <slug>
  - Files catalogued: N
  - Contracts identified: N
  - Location: docs/domains/<slug>/domain.md
  
  Note: No files were moved. Source Location in domain.md
  points to files in their current locations. A future plan
  can consolidate files into src/<slug>/ if desired.
```

---

## 6. Install/Sync Pipeline

### How v2-commands integrate with the existing sync

The `install/agents.sh` script and `scripts/sync-to-dist.sh` need to handle the new directory.

**Option A (Recommended)**: v2-commands are installed **alongside** v1 commands in the same target directories. Users invoke `/plan-3-v2-architect` or `/extract-domain` by name.

```
~/.claude/commands/
├── plan-3-architect.md          # v1 (existing)
├── plan-3-v2-architect.md       # v2 (new)
├── extract-domain.md            # new command
└── ...

~/.config/opencode/command/
├── plan-3-architect.md          # v1
├── plan-3-v2-architect.md       # v2
├── extract-domain.md            # new
└── ...
```

**Why**: Simple, no runtime detection needed, user explicitly chooses v1 or v2. Both available simultaneously.

**Sync changes**:
- `scripts/sync-to-dist.sh`: Add `agents/v2-commands/*.md → src/jk_tools/agents/v2-commands/`
- `install/agents.sh`: Add loop to copy v2-commands to same targets as commands

### Naming in target directories

V2 commands keep their v2 naming in all targets:

| Source | Target (Claude) | Target (OpenCode) | Target (Copilot) |
|--------|----------------|-------------------|-------------------|
| `agents/v2-commands/plan-3-v2-architect.md` | `~/.claude/commands/plan-3-v2-architect.md` | `~/.config/opencode/command/plan-3-v2-architect.md` | `plan-3-v2-architect.prompt.md` |
| `agents/v2-commands/extract-domain.md` | `~/.claude/commands/extract-domain.md` | `~/.config/opencode/command/extract-domain.md` | `extract-domain.prompt.md` |

---

## 7. V2 Adoption Path

### For users

```
# Project wants to use domain system:
1. Run /extract-domain for key concepts (brownfield)
   — OR — domains emerge naturally via /plan-1b-v2-specify (greenfield)

2. Use v2 commands instead of v1 for the plan flow:
   /plan-1b-v2-specify → /plan-2-v2-clarify → /plan-3-v2-architect
   → /plan-5-v2-phase-tasks-and-brief → /plan-6-v2-implement-phase
   → /plan-7-v2-code-review

3. Non-v2 commands work unchanged:
   /plan-0-constitution, /plan-1a-explore, /plan-2c-workshop,
   /plan-3a-adr, /plan-4-complete-the-plan, /plan-5b-flightplan,
   /plan-6b-worked-example, /plan-8-merge, /tad, etc.
```

### Mixing v1 and v2

It's safe to mix — v2 commands produce artifacts (spec, plan, tasks) that v1 commands can still read. The v2 sections (Target Domains, Domain column) are simply additional data that v1 commands ignore.

**However**: Using v1 plan-6 after v2 plan-5 means domain placement rules won't be enforced during implementation. The domain.md won't be updated. The value degrades but nothing breaks.

---

## 8. Future: V2 Becomes V1

When the domain system is proven and stable:

1. Merge v2 overrides back into the v1 commands
2. Remove PlanPak conditional blocks from merged commands
3. Delete `agents/v2-commands/` directory
4. `planpak.md` gets archived or removed
5. `extract-domain.md` moves to `agents/commands/`

This is a deliberate future decision, not something to plan for now.

---

## Quick Reference

```
v2-commands/ contents (8 files):
  extract-domain.md          # NEW — brownfield domain extraction
  plan-1b-v2-specify.md      # Adds Target Domains section
  plan-2-v2-clarify.md       # Domain Review replaces PlanPak question
  plan-3-v2-architect.md     # Domain-aware planning (biggest change)
  plan-5-v2-phase-tasks-and-brief.md  # Domain column, domain audit
  plan-6-v2-implement-phase.md        # Domain placement rules
  plan-6a-v2-update-progress.md       # Domain in footnotes
  plan-7-v2-code-review.md   # Domain compliance validator

Commands that DON'T need v2 (17):
  plan-0-constitution, plan-1a-explore, plan-2b-prep-issue,
  plan-2c-workshop, plan-3a-adr, plan-4-complete-the-plan,
  plan-5b-flightplan, plan-5c-requirements-flow,
  plan-6b-worked-example, plan-8-merge, planpak (superseded),
  code-concept-search, deepresearch, didyouknow,
  flowspace-research, tad, util-0-handover
```
