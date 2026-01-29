---
description: Plan Pack paradigm — the pack is a manifest of symlinks claiming project files. Drop this into any conversation to activate plan-pack mode.
---

# PlanPak: Plan-Based Feature File Organization

Activate **PlanPak** file organization for this project. When PlanPak is active, new source files introduced by a plan live in flat `features/<ordinal>-<slug>/` folders grouped by the plan that created them. Cross-cutting code, shared libraries, and deployment-target splits remain in their traditional locations.

```md
User input:

$ARGUMENTS

## What Is PlanPak?

PlanPak is an opt-in file organization strategy inspired by Screaming Architecture. Instead of grouping files by architectural layer (all controllers together, all services together), PlanPak groups files by the **plan that introduced them** — so the folder structure communicates *which feature this code belongs to*.

**Key principle**: Only the *storage location* changes. Your project's existing patterns (DI, adapters, interfaces, service abstractions) are fully preserved.

## Detection Logic

PlanPak is active when **either** signal is present:

1. **Spec header**: `**File Management**: PlanPak` in the feature spec
2. **T000 task**: A `T000` task exists in the plan's task table creating the feature folder structure

If neither signal is found, all commands fall back to **Legacy** behavior (files placed in traditional layer-based locations).

## Feature Folder Structure

```
features/
├── 001-user-auth/           # Plan 001 files
│   ├── auth-service.ts
│   ├── auth-adapter.ts
│   ├── user-model.ts
│   └── login-handler.ts
├── 002-billing/             # Plan 002 files
│   ├── invoice-service.ts
│   ├── payment-adapter.ts
│   └── billing-model.ts
└── 003-notifications/       # Plan 003 files
    ├── notification-service.ts
    └── email-adapter.ts
```

### Naming Convention

`features/<ordinal>-<slug>/`

- **Ordinal**: Matches the plan's ordinal from `docs/plans/<ordinal>-<slug>/`
- **Slug**: Matches the plan's slug
- **Flat**: All files directly in the folder — no internal subdirectories (`models/`, `services/`, etc.)
- **Descriptive filenames**: Use `auth-service.ts`, `user-model.ts` (not `service.ts`, `model.ts`)

### Library Splits

If the project has deployment-target or package splits, feature folders nest within each:

```
src/
├── web/
│   └── features/
│       └── 001-user-auth/
├── cli/
│   └── features/
│       └── 001-user-auth/
└── shared/
    └── features/
        └── 001-user-auth/
```

## File Classification Tags

Every file in a PlanPak plan gets classified:

| Tag | Meaning | Where It Lives |
|-----|---------|---------------|
| `plan-scoped` | Serves only this plan's feature | `features/<ordinal>-<slug>/` |
| `cross-cutting` | Registration, wiring, DI config, shared infrastructure | Traditional shared location |
| `cross-plan-edit` | Editing a file owned by an earlier plan | Stays in the original plan's folder |
| `shared-new` | New file needed by 3+ plans from the start | `shared/`, `core/`, or project convention |

## File Placement Decision Tree

For each new file the plan introduces:

```
Is this file serving ONLY this plan's feature?
├── YES → Is it a registration/wiring/DI file?
│   ├── YES → cross-cutting (shared location)
│   └── NO → plan-scoped (features/<ordinal>-<slug>/)
└── NO → Will 3+ plans need it from the start?
    ├── YES → shared-new (shared/, core/, or convention)
    └── NO → plan-scoped (features/<ordinal>-<slug>/, graduate later)
```

## Cross-Plan Editing

When Plan B needs to modify a file that Plan A created:

1. **The file stays in Plan A's folder** — file ownership is birth-based
2. Plan B edits the file **in place** (no moving, no copying)
3. The task table marks the file as `cross-plan-edit` in Notes
4. Git blame provides the full modification history

**Rule**: Never move a file from one plan's folder to another. If you need the file, edit it where it lives.

## Handling Files From Earlier Packs

When a plan needs to edit a file that lives in an earlier plan's pack:

1. **Detect**: The target project path points to a file in another plan's `features/` folder
2. **Edit in place**: Modify the file directly in the earlier plan's folder
3. **Tag**: Mark as `cross-plan-edit` in the task table Notes column
4. **Log**: Document the cross-plan modification in the execution log

The earlier plan's folder retains the file — this is intentional. File provenance follows the plan that *created* the file, not the plan that last modified it.

## Dependency Direction

```
features/003-notifications/ ──→ shared/core/ ✅ (allowed)
shared/core/ ──→ features/003-notifications/ ❌ (never)
features/002-billing/ ──→ features/001-auth/ ⚠️ (cross-plan-edit only)
```

- **Plans → shared/core**: Always allowed
- **Shared → plans**: Never allowed (shared must not depend on plan-scoped code)
- **Plan → Plan**: Only for cross-plan edits (editing files, not importing modules)

## Rule of Three Graduation

When 3+ plans import from another plan's folder, graduate the shared code:

1. Move the file to `shared/`, `core/`, or `contracts/` (project convention)
2. Update all imports
3. Reclassify as `cross-cutting` in the plan's manifest
4. Document the graduation in the execution log

## Test Organization

PlanPak **does not prescribe** where tests live. Test placement follows the project's existing conventions:

- Check `docs/project-rules/rules.md`, `idioms.md`, ADRs, and constitution
- Common patterns: `tests/`, colocated `__tests__/`, `tests/feat-<slug>/`
- Whatever the project already does — PlanPak defers entirely

## Backward Compatibility

PlanPak detection uses dual signals:

1. `**File Management**: PlanPak` in spec header (primary — set by `/plan-2-clarify`)
2. `T000` task in plan task table (secondary — set by `/plan-3-architect`)

When **neither** is present, all commands behave exactly as they do today. Zero behavioral change for legacy projects.

## Quick Reference Card

| Question | Answer |
|----------|--------|
| Where do plan-scoped files go? | `features/<ordinal>-<slug>/` |
| Are feature folders flat or nested? | Flat — all files directly in the folder |
| What about cross-cutting code? | Traditional shared locations (unchanged) |
| Can Plan B edit Plan A's files? | Yes, in place — never move them |
| Where do tests go? | Follow project conventions (PlanPak doesn't prescribe) |
| How are library splits handled? | Feature folders nest within each split (`web/features/`, `cli/features/`) |
| When does code graduate to shared? | When 3+ plans import from one plan's folder |
| How is PlanPak detected? | Spec header `File Management: PlanPak` OR T000 task |
| Does PlanPak change DI/adapters? | No — only file location changes, not architecture |
| What naming convention? | `features/<ordinal>-<slug>/` matching `docs/plans/<ordinal>-<slug>/` |

## Integration With Plan Workflow

| Command | What PlanPak Changes |
|---------|---------------------|
| `/plan-2-clarify` | Asks File Management question (PlanPak vs Legacy) |
| `/plan-3-architect` | Detects PlanPak, adds File Placement Manifest, generates T000 |
| `/plan-5-phase-tasks-and-brief` | Enforces `features/` paths for plan-scoped files |
| `/plan-6-implement-phase` | Follows 5 PlanPak placement rules |
| `/plan-6a-update-progress` | Includes classification tag in Notes |
| `/plan-7-code-review` | Validates PlanPak compliance with dedicated subagent |

## Standalone Usage

You can drop PlanPak into any project without the full plan workflow:

1. Create `features/` directory at the appropriate level in your source tree
2. Organize new feature code into `features/<ordinal>-<slug>/` folders
3. Keep cross-cutting code in traditional locations
4. Follow the decision tree for each new file
5. Use descriptive filenames (not generic `service.ts`)

No symlinks, no manifests, no special tooling required — just file placement.
```
