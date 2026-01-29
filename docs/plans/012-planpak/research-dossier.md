# Research Dossier: PlanPak — Plan-Based File Organization

**Generated**: 2026-01-29
**Research Query**: "Screaming architecture approach branded as PlanPak, integrated across plan workflow commands /2 through /7, plus standalone command"
**Mode**: Pre-Plan
**Location**: `docs/plans/012-planpak/research-dossier.md`
**Findings**: 72 across 5 research threads + codebase exploration

---

## Executive Summary

### What It Does

PlanPak organizes project source code by the **plan that introduced it** rather than by architectural layer. Each plan gets a `features/<ordinal>-<slug>/` folder containing all files that plan created — models, services, handlers, tests. Cross-cutting code (DI, middleware, config) and shared libraries remain in traditional locations. The concept is opt-in via `/2-clarify` and flows through the entire plan lifecycle.

### Business Purpose

Provides full traceability from plan → code → tests. Makes the codebase a living archaeological record of how the system was built, feature by feature. Enables clean feature deletion (remove one folder), clear team ownership, and natural microservice extraction boundaries.

### Key Insights

1. The approach is well-established under names like Vertical Slice Architecture (Bogard), Screaming Architecture (Uncle Bob), and Feature-Sliced Design — PlanPak adds a temporal/provenance dimension
2. Nearly all modern frameworks support non-default file locations with minimal configuration; Go is the exception (no numeric prefixes in package names)
3. The existing plan workflow already has Simple/Full mode branching in every command — PlanPak follows the same pattern as a third mode flag

### Quick Stats

- **Files to create**: 1 (`agents/commands/planpak.md`)
- **Files to modify**: 6 (`plan-2-clarify.md`, `plan-3-architect.md`, `plan-5-phase-tasks-and-brief.md`, `plan-6-implement-phase.md`, `plan-6a-update-progress.md`, `plan-7-code-review.md`) + `README.md`
- **Existing mode pattern**: Simple/Full branching already exists in plan-3 (line 44), plan-6 (line 150), plan-6a (line 75), plan-7 (line 28)
- **Complexity**: CS-3 (medium) — many files but each change is a bounded section addition

---

## How the Current System Works

### Workflow Mode Detection Pattern

Every command that varies by mode follows the same pattern:

**plan-2-clarify** (line 20): Q1 asks Simple vs Full, writes `**Mode**: Simple` or `**Mode**: Full` to spec header.

**plan-3-architect** (line 44-56): `PHASE 0: Detect Workflow Mode` — reads spec for `**Mode**: Simple` or `**Mode**: Full`, selects output format accordingly.

**plan-5-phase-tasks-and-brief**: No explicit mode detection — it only runs in Full Mode (Simple Mode skips it).

**plan-6-implement-phase** (line 150-177): `Detect Workflow Mode` — Simple vs Full affects path resolution, task loading, and output format.

**plan-6a-update-progress** (line 75-116): `Step A1: Determine Paths` — `INLINE_MODE = true` for Simple, affects all 4 phases of the update cycle.

**plan-7-code-review** (line 28-60): `Detect Workflow Mode` — Simple reduces subagents from 5→3 in Step 3a, skips Step 3b entirely.

### Task Table Formats

**Full Mode** (plan-3 § 8):
```
| # | Status | Task | CS | Success Criteria | Log | Notes |
```
Tasks use phase-relative IDs like `2.3` (phase 2, task 3).

**Simple Mode** (plan-3 inline, plan-5 canonical):
```
| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Subtasks | Notes |
```
Tasks use `T001, T002, T003...` IDs. The `Absolute Path(s)` column is mandatory.

### Existing Question Flow (plan-2-clarify)

Current question priority:
1. **Q1**: Workflow Mode (Simple/Full) — MANDATORY first
2. **Q2**: Testing Strategy (Full TDD/TAD/Lightweight/Manual/Hybrid)
3. **Q3**: Mock Usage (Avoid/Targeted/Liberal)
4. **Q4**: Documentation Strategy (README/docs/how/Hybrid/None)
5. Q5-Q8: Domain-specific ambiguities from spec scan

Cap: ≤8 total questions.

### File Organization (Current)

Currently, the plan workflow places all plan artifacts in `docs/plans/<ordinal>-<slug>/` but makes **no prescriptions** about where source code goes in the project tree. Source code goes wherever the developer or architect decides — typically following framework conventions (controllers/, services/, etc.) or existing project patterns. There is no `features/` directory concept.

---

## PlanPak Design

### Core Concept

Each plan creates source files inside a dedicated folder:
```
features/<ordinal>-<slug>/
```

The ordinal and slug mirror the plan's identity from `docs/plans/<ordinal>-<slug>/`. Example: plan `docs/plans/003-notifications/` produces source folder `features/003-notifications/`.

### Folder Structure

```
<project-root>/
├── features/                        # Plan-organized source code
│   ├── 001-user-auth/
│   │   ├── models/
│   │   ├── services/
│   │   ├── handlers/
│   │   └── tests/
│   ├── 002-payments/
│   │   ├── models/
│   │   ├── services/
│   │   └── tests/
│   └── 003-notifications/
│       └── ...
├── shared/                          # Cross-cutting code (never plan-specific)
│   ├── contracts/                   # Interfaces/types graduated from plans
│   ├── primitives/                  # Value objects, enums, constants
│   ├── middleware/                  # Auth, logging, error handling
│   ├── config/                     # DI, routing, app config
│   └── utils/                      # Pure utility functions
├── core/                            # Architectural abstractions (depends on nothing)
│   ├── interfaces/
│   └── types/
├── infrastructure/                  # External integrations
│   ├── database/
│   ├── messaging/
│   └── logging/
└── database/
    └── migrations/                  # Always sequential, never in plan folders
```

### Library Splits Preserved

Top-level deployment/library splits remain. Plan folders nest **within** each:

```
packages/
├── web/
│   └── features/
│       ├── 001-user-auth/
│       └── 002-payments/
├── api/
│   └── features/
│       └── 001-user-auth/
├── cli/
│   └── features/
│       └── 001-dashboard/
└── shared/                          # Cross-package shared code
```

A single plan may appear in multiple packages (same ordinal, same slug).

### Rules

| Rule | Description |
|------|-------------|
| **File ownership is birth-based** | A file lives in the plan that created it, permanently |
| **Modifications stay in place** | Later plans edit earlier plan files in-place, never move them |
| **Cross-cutting stays shared** | DI, middleware, config, logging never belong to a plan folder |
| **Dependency direction** | Plans → shared/core (allowed); shared → plans (never) |
| **Graduation via Rule of Three** | When 3+ plans import from another plan, graduate the type to shared/contracts/ |
| **Tests colocate** | Unit tests in `features/<ordinal>-<slug>/tests/`; integration tests in `tests/integration/` |
| **Migrations stay separate** | Database migrations in `database/migrations/` with plan number in filename |
| **Plan numbering is immutable** | Numbers are identifiers, not a contiguous sequence; gaps are fine |

### File Classification Tags

Every file in PlanPak gets one of four classifications:

| Tag | Meaning | Example |
|-----|---------|---------|
| `plan-scoped` | New file in current plan's feature folder | `features/003-notifications/services/notifier.py` |
| `cross-cutting` | Infrastructure file in shared/traditional location | `shared/config/di_container.py` |
| `cross-plan-edit` | File owned by earlier plan, edited in-place | `features/001-user-auth/services/auth_service.py` |
| `shared-new` | New genuinely reusable code going to shared/core | `shared/contracts/user.ts` |

### File Placement Decision Tree

```
Is this file new?
  YES → Does it serve only this plan's feature?
    YES → features/<ordinal>-<slug>/  (plan-scoped)
    NO  → Is it a registration/wiring file?
      YES → shared/config/ or traditional location (cross-cutting)
      NO  → Will 3+ plans use it immediately (not speculatively)?
        YES → shared/core/ or shared/contracts/ (shared-new)
        NO  → features/<ordinal>-<slug>/ (plan-scoped, graduate later if needed)
  NO → Edit in place at its current absolute path (cross-plan-edit)
```

### Cross-Plan Dependencies

| Scenario | Approach |
|----------|----------|
| Plan B uses Plan A's type | Import from Plan A's public API; graduate to shared on 3rd consumer |
| Plan B modifies Plan A's file | Edit in-place; document in plan's task log |
| Circular dependency | Domain events via mediator, or dependency-inverted interfaces in shared |
| Shared creep | Contracts only in shared; periodic repatriation; split bounded contexts |

### Framework Compatibility

| Framework | Works? | Adaptation |
|-----------|--------|------------|
| ASP.NET | Yes | Controller discovery is type-based; Minimal APIs work natively |
| Django | Yes | Each plan = Django app; use `AppConfig.label` for clean DB table names |
| Next.js | Hybrid | `app/` stays as thin routing layer; imports from plan folders |
| Go | Needs naming | Drop numeric prefixes (invalid Go identifiers); use manifest for plan→package mapping |
| Angular | Yes | Plan folders become lazy-loaded feature modules |
| Spring Boot | Minor config | Add `@ComponentScan(basePackages = {"features"})` |
| TypeScript | Yes | Path aliases (`@features/001-user-auth`) + barrel exports |
| Python | Yes | Use `p001_user_auth` (underscores); `__init__.py` exports |
| Rust | Yes | Cargo workspace members; plan folders as crate names (no numeric prefix) |

---

## Integration Points Per Command

### 1. plan-2-clarify.md — Add File Management Question

**Location**: After Q1 (Workflow Mode), as Q2 or early in sequence
**What changes**: Add a new question template

```
Q: How should feature files be organized?

| Option | Strategy | Best For | What Changes |
|--------|----------|----------|--------------|
| A | PlanPak (Recommended) | Full traceability, plan = self-contained feature folder | Code in features/<plan>/, cross-cutting in shared/ |
| B | Legacy | Quick edits, simple changes, no structural overhead | Code written directly to project paths as normal |

Answer: [A/B]
```

**Spec header update**:
- PlanPak selected: `**File Management**: PlanPak`
- Legacy selected: `**File Management**: Legacy`

**Downstream effect**: All subsequent commands check this field.

### 2. plan-3-architect.md — File Placement Manifest

**Location**: PHASE 0 (line 44) — extend mode detection; PHASE 3 — add manifest to directory structure; PHASE 4 — add manifest section to plan document

**What changes**:

1. **PHASE 0**: Check spec for `**File Management**: PlanPak` in addition to Mode detection
2. **PHASE 3**: When PlanPak active, include `features/<ordinal>-<slug>/` in directory structure template
3. **PHASE 4**: Add new required section "File Placement Manifest" to plan document:

```markdown
## File Placement Manifest

| File | Location | Classification | Rationale |
|------|----------|----------------|-----------|
| features/003-notifications/services/notifier.py | Plan folder | plan-scoped | New service for this feature |
| shared/config/di_container.py | Shared | cross-cutting | DI registration |
| features/001-user-auth/services/auth_service.py | Earlier plan | cross-plan-edit | Adding notification hook |
```

4. **T000 Setup Task**: When PlanPak active, plan-3 includes a T000 task that creates the `features/<ordinal>-<slug>/` directory structure. This is the "pack setup" task.

### 3. plan-5-phase-tasks-and-brief.md — PlanPak-Aware Task Generation

**Location**: Step 5 (Transform and expand tasks), Step 6 (Write dossier)

**What changes**:

1. **Step 5**: When PlanPak active, enforce `Absolute Path(s)` uses `features/<ordinal>-<slug>/` prefix for plan-scoped files. Add classification tag to `Notes` column.
2. **Step 6 (Alignment Brief)**: Add "File Placement Rules" subsection:
   ```markdown
   ### File Placement Rules (from plan § File Placement Manifest)
   - **New feature files** → `features/003-notifications/`
   - **Cross-cutting edits** → Edit in-place at shared locations
   - **Earlier plan files** → Edit in-place, do NOT move
   - **Tests** → Colocate in `features/003-notifications/tests/`
   ```

### 4. plan-6-implement-phase.md — PlanPak File Creation Rules

**Location**: Step 1 (Path Resolution), Step 2 (Contract), Step 3 (Execution)

**What changes**:

Add **5 PlanPak implementation rules** (conditional on `File Management: PlanPak`):

1. **New files always go in the current plan folder**: Path MUST start with `features/<ordinal>-<slug>/`. Exception: cross-cutting registration files.
2. **Modifying earlier plan files: edit in-place, never move**: The originating plan retains ownership.
3. **Cross-cutting registration edits go to central files**: Import from plan folder; register in central config.
4. **Test colocation**: Unit tests in `features/<ordinal>-<slug>/tests/`. Integration tests in `tests/integration/`.
5. **Directory creation**: `mkdir -p features/<ordinal>-<slug>/models/` etc. as needed before file creation.

### 5. plan-6a-update-progress.md — PlanPak Progress Tracking

**Location**: Step A1 (Determine Paths), Step C1 (Dossier Updater)

**What changes**:

1. **Step A1**: When PlanPak active, note the plan's feature folder for validation
2. **Step C1**: Classification tag (`plan-scoped`, `cross-cutting`, `cross-plan-edit`) can be included in Notes alongside footnote references
3. **No major structural changes** — plan-6a's 3-location update pattern works unchanged since it operates on plan artifacts (docs/plans/), not source code locations

### 6. plan-7-code-review.md — PlanPak Validation

**Location**: Step 4 (Rules & doctrine gates) — add new subagent

**What changes**:

Add **Subagent: PlanPak Compliance Validator** (runs when `File Management: PlanPak`):

```
Validation Checks:
1. New plan-scoped files under features/<ordinal>-<slug>/     (HIGH if violated)
2. No feature-specific logic leaked into shared/core          (HIGH if found)
3. Dependency direction: plan → shared (never shared → plan)  (CRITICAL if violated)
4. Cross-cutting registrations present for new services       (HIGH if missing)
5. No files moved between plan folders                        (CRITICAL if found)
6. Tests colocated in plan folder (unit) or tests/integration (LOW advisory)
```

Report format matches existing subagent JSON structure.

### 7. planpak.md (NEW) — Standalone Command

**Purpose**: Self-contained reference document that explains PlanPak completely. Can be dropped into any project's `.claude/commands/` to activate PlanPak even without the full plan workflow.

**Contents**:
- Full concept explanation
- Folder structure reference
- File classification system
- Placement decision tree
- Cross-plan rules
- Framework compatibility notes
- T000 setup task template
- Detection logic (`**File Management**: PlanPak` in spec OR T000 in task table)
- Quick reference card

### 8. README.md — Documentation Update

**Location**: Command Flow Diagram, Core Workflow Commands, Directory Structure

**What changes**:
- Add PlanPak to command list with description
- Note PlanPak as optional file management strategy
- Show `features/` directory in structure example

---

## Detection Logic

PlanPak is active when **any** of these are true:
1. Spec header contains `**File Management**: PlanPak`
2. Task table contains a T000 with PlanPak setup description
3. The `planpak.md` command was explicitly invoked in the conversation

This allows PlanPak to work:
- Through the full plan workflow (spec → architect → implement → review)
- Ad-hoc when someone drops the standalone command into a conversation

---

## Cross-Cutting Concerns (What Stays Outside Plan Folders)

| Category | Location | Examples |
|----------|----------|---------|
| DI/IoC registration | `shared/config/` or composition root | Container setup, service registration |
| Middleware pipeline | `shared/middleware/` or app startup | Auth, logging, error handling, CORS |
| Database migrations | `database/migrations/` | Schema changes (include plan number in filename) |
| App configuration | `shared/config/` | Environment variables, app settings |
| Shared interfaces | `shared/contracts/` or `core/interfaces/` | Graduated types, cross-plan contracts |
| Value objects | `shared/primitives/` or `core/types/` | Money, Email, Result<T> |
| Build/CI configuration | Project root | Dockerfile, CI pipelines, linter config |

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Import paths become verbose | High | Low | Path aliases + barrel exports per plan folder |
| Shared folder becomes dumping ground | Medium | High | Rule of Three + contracts-only policy + periodic repatriation |
| Framework routing conventions conflict | Medium | Medium | Thin adapter files in framework-conventional locations |
| Go package naming incompatibility | High (for Go) | Medium | Drop numeric prefixes; use manifest for ordering |
| Cross-plan dependencies tangle | Low | High | Public API per plan + declared dependencies + domain events for cycles |
| Agent commands become too long | Medium | Medium | Keep PlanPak sections conditional ("if PlanPak active") and concise |

---

## Prior Learnings

### From PlanPak v1 (rolled back from commits 5749ba0, 50dd1f2)

1. **Symlinks don't work**: Nearly all compilers (TypeScript, Go, Rust, Dart, C#) resolve imports from the **real file location**, not the symlink location. Go, TypeScript (with rootDir), Rust, and Dart can outright reject files whose real path is outside the project boundary. **Decision: No symlinks. Real files only.**

2. **All 5 command files already had conditional PlanPak language**: The v1 implementation proved that the existing Simple/Full mode branching pattern extends cleanly to PlanPak as a third option.

3. **Detection logic works with dual signals**: Checking both spec header (`File Management: PlanPak`) and task table (T000 presence) provides robustness — either signal activates PlanPak behavior.

4. **Cross-plan file handling simplified without symlinks**: When real files stay at their creation location, cross-plan editing is just "edit the file where it is." No copy-and-relink, no manifest updates, no symlink management.

---

## Modification Considerations

### Safe to Modify
- `plan-2-clarify.md` — Adding a question follows the exact pattern of existing Q1-Q4
- `planpak.md` — New file, no conflicts
- `README.md` — Documentation addition only

### Modify with Caution
- `plan-3-architect.md` — Large file (~1400 lines); PlanPak section must integrate cleanly into PHASE 0, PHASE 3, and PHASE 4 without disrupting existing flow
- `plan-5-phase-tasks-and-brief.md` — Task table format is critical; PlanPak additions must be backward-compatible
- `plan-6-implement-phase.md` — Implementation rules are central; PlanPak rules must be clearly conditional

### Low Risk
- `plan-6a-update-progress.md` — Minimal changes; PlanPak doesn't fundamentally alter the 3-location update pattern
- `plan-7-code-review.md` — Adding a subagent follows the established parallel validation pattern

---

## Next Steps

- **Research complete.** Run `/plan-1b-specify` to create the PlanPak specification.
- No external research needed — the Perplexity research from earlier in this conversation covers the theoretical foundations thoroughly.

---

**Research Complete**: 2026-01-29
**Report Location**: `docs/plans/012-planpak/research-dossier.md`
