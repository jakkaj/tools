# PlanPak: Plan-Based Feature File Organization

**Mode**: Simple
**File Management**: PlanPak

> This specification incorporates findings from `research-dossier.md`

---

## Research Context

- **Components affected**: 7 agent command files (`plan-2-clarify`, `plan-3-architect`, `plan-5-phase-tasks-and-brief`, `plan-6-implement-phase`, `plan-6a-update-progress`, `plan-7-code-review`) + 1 new standalone command (`planpak.md`) + `README.md`
- **Critical dependencies**: Existing Simple/Full mode branching pattern in every command; task table format with `Absolute Path(s)` column; plan-7 subagent validation architecture
- **Modification risks**: Large files (plan-3 ~1400 lines, plan-7 ~1500 lines) require careful section insertion without disrupting existing flow
- **Prior learnings**: PlanPak v1 was rolled back — symlinks don't work (compilers resolve from real path), but the conditional branching pattern and dual detection logic were proven sound
- Link: See `research-dossier.md` for full analysis

---

## Summary

PlanPak is an opt-in file organization strategy for the plan workflow. When enabled, source code files are grouped by the plan that introduced them — each plan gets a flat feature folder containing its models, services, adapters, handlers, and tests. The project's existing architectural patterns (DI, adapter injection, service abstractions) are fully preserved; only the *storage location* changes from layer-based (all controllers together, all services together) to plan-based (all files for one feature together). Cross-cutting infrastructure, shared libraries, and deployment-target splits (web, cli, shared) remain in their traditional locations. The concept flows through the entire plan lifecycle: opt-in at clarify (/2), structure at architect (/3), task paths at dossier (/5), file placement at implement (/6), and compliance validation at review (/7). A standalone `planpak.md` command provides the full reference for use outside the plan workflow.

---

## Goals

1. **Feature-grouped source code**: All files a plan introduces live together in one flat folder, not scattered across layer directories
2. **Preserved architectural patterns**: DI containers, adapter-to-service injection, interface-driven design, and existing project idioms continue unchanged — only the file location changes
3. **Library split compatibility**: Top-level deployment/package splits (web, cli, shared, core) are preserved; feature folders nest within each
4. **Opt-in with zero disruption**: Legacy mode (current behavior) remains the default; PlanPak activates only when explicitly chosen during clarification
5. **Test organization defers to project conventions**: PlanPak does not prescribe test location — test placement follows the project's existing rules, idioms, ADRs, and constitution (e.g., `tests/`, colocated, `tests/feat-<slug>/`, etc.)
6. **Full workflow integration**: Every plan command from /2 through /7 knows about PlanPak and acts accordingly when active
7. **Standalone usability**: The `planpak.md` command works independently — drop it into any project to activate PlanPak without the full plan workflow
8. **Cross-plan editing**: Later plans can modify files from earlier plans in-place without moving them; file ownership is birth-based

---

## Non-Goals

1. **Symlinks or manifests**: No symlink-based file management (proven incompatible with compilers in v1)
2. **Automatic migration of existing code**: PlanPak applies to new plans only; existing codebases are not reorganized
3. **Nested feature subfolders**: Feature folders are flat (no `features/001-auth/models/`, `features/001-auth/services/` hierarchy) — files sit directly in the feature folder with descriptive names
4. **Framework-specific routing adapters**: PlanPak does not generate framework shims (Next.js route files, Django url configs); those remain the developer's responsibility
5. **Enforcing PlanPak on all projects**: This is purely opt-in; many projects are better served by legacy organization
6. **Prescribing test location**: PlanPak defers test organization entirely to the project's existing conventions (rules.md, idioms.md, ADRs, constitution) — it does not mandate where tests live

---

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2, I=0, D=0, N=1, F=0, T=1
  - Surface Area (S=2): 7 files modified + 1 new file + README — cross-cutting across the command system
  - Integration (I=0): No external dependencies; all changes are within the tools repository
  - Data/State (D=0): No database, no migrations, no schema changes
  - Novelty (N=1): Concept is well-understood (Screaming Architecture / VSA) but applying it to agent commands is new territory; v1 provided learnings
  - Non-Functional (F=0): Standard documentation/prompt engineering; no perf/security concerns
  - Testing/Rollout (T=1): Must verify via `./setup.sh` deployment; spot-check that commands deploy correctly to all CLI tool directories
- **Confidence**: 0.85 (high confidence due to v1 learnings and detailed research)
- **Assumptions**:
  - The existing Simple/Full mode branching pattern extends cleanly to PlanPak
  - Conditional sections ("if PlanPak active") keep command files maintainable
  - Flat feature folders work across languages (no deep subdirectory structure needed)
- **Dependencies**: None external
- **Risks**: Command file bloat if PlanPak sections are too verbose (mitigate: keep additions concise)
- **Phases**: Suggest 2-3 phases: (1) standalone planpak.md + plan-2 + plan-3, (2) plan-5 + plan-6 + plan-6a, (3) plan-7 + README

---

## Acceptance Criteria

1. **Opt-in question**: Running `/plan-2-clarify` presents a File Management question (PlanPak vs Legacy); the answer is recorded in the spec header as `**File Management**: PlanPak` or `**File Management**: Legacy`
2. **Architect awareness**: When PlanPak is active, `/plan-3-architect` produces a plan with:
   - A File Placement Manifest section classifying every planned file
   - A T000 setup task that creates the feature folder structure
   - Directory tree showing `features/<ordinal>-<slug>/` for plan-scoped files
3. **Task paths enforced**: `/plan-5-phase-tasks-and-brief` generates tasks where plan-scoped files have `Absolute Path(s)` pointing to `features/<ordinal>-<slug>/` and classification tags in Notes
4. **Implementation rules**: `/plan-6-implement-phase` follows PlanPak placement rules — new files in feature folder, cross-plan edits in-place, cross-cutting in shared locations
5. **Review validation**: `/plan-7-code-review` includes a PlanPak Compliance Validator subagent that checks file placement, dependency direction, and cross-cutting registration
6. **Standalone command**: `planpak.md` exists as a self-contained command explaining the full PlanPak concept, usable without the plan workflow
7. **Legacy unaffected**: When `File Management: Legacy` or no file management field exists, all commands behave exactly as they do today — zero behavioral change
8. **Test organization deferred**: PlanPak does not prescribe test location; test placement follows the project's existing conventions (rules.md, idioms.md, ADRs, constitution)
9. **DI/adapter patterns preserved**: PlanPak instructions explicitly state that architectural patterns (dependency injection, adapter interfaces, service abstractions) are unchanged — only file location changes
10. **Library splits preserved**: Feature folders nest within deployment-target or package splits (web/, cli/, shared/); PlanPak does not collapse these
11. **Setup deploys**: Running `./setup.sh` successfully syncs all modified commands (10/10 install success)
12. **Flat feature folders**: Feature folders contain files directly (e.g., `features/003-auth/user-service.ts`, `features/003-auth/auth-adapter.ts`) — no mandatory internal subdirectory structure

---

## Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Command files become too long with PlanPak sections | Medium | Medium | Keep all PlanPak additions behind conditional guards ("If PlanPak active:"); use concise bullet format not prose |
| Flat feature folders get cluttered for large plans | Low | Low | Plans are SRP-scoped; a single plan shouldn't produce dozens of files. If it does, the plan scope is too broad. |
| Project has no test convention documented | Low | Medium | PlanPak prompts the architect to check project rules; defaults to whatever the project already does |
| Agents ignore PlanPak rules in practice | Medium | High | plan-7 validator catches violations; the T000 task creates the folder structure upfront |
| Cross-plan file edits lose provenance | Low | Low | Git blame provides full history; plan task logs document cross-plan modifications |

**Assumptions**:
- Projects using PlanPak will have a `features/` (or equivalent) directory at the appropriate level in their source tree
- Plans are SRP-scoped enough that flat folders don't become unwieldy
- Existing project idioms (DI, adapters, interfaces) are documented in `docs/project-rules/` and respected by PlanPak

---

## Open Questions

1. ~~[RESOLVED] Test directory naming — deferred to project conventions~~
2. ~~[RESOLVED] Flat vs structured — flat only, all files directly in feature folder~~
3. ~~[RESOLVED] Feature folder naming — ordinal prefix: `features/<ordinal>-<slug>/`~~

---

## ADR Seeds (Optional)

- **Decision Drivers**: Need for feature traceability; desire to preserve existing DI/adapter patterns; framework compatibility across TypeScript, C#, Python, Go, Rust
- **Candidate Alternatives**:
  - A: Flat feature folders with ordinal prefix (`features/003-auth/`)
  - B: Flat feature folders without ordinal (`features/auth/`) with manifest for ordering
  - C: Structured feature folders with internal subdirectories (`features/003-auth/services/`, `features/003-auth/models/`)
- **Stakeholders**: Agent command authors, downstream plan users

---

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Feature folder internal structure | Storage Design | Flat (all files in one folder) vs structured (subdirectories per concern) affects discoverability and tooling | 1. Does flat scale to 10+ files per plan? 2. Do IDEs handle flat feature folders well? 3. Should structure be language-dependent? 4. How do barrel exports/`__init__.py` work with flat? |

---

## Testing Strategy

- **Approach**: Manual
- **Rationale**: This feature modifies markdown prompt files, not application code. Verification is running `./setup.sh` and confirming deployment.
- **Focus Areas**: `./setup.sh` deploys all modified commands successfully (10/10)
- **Excluded**: No unit tests, no TDD, no TAD — prompt engineering changes verified by deployment and manual review
- **Mock Usage**: N/A

## Documentation Strategy

- **Location**: No new documentation (README.md update is part of the feature itself, not separate documentation)
- **Rationale**: PlanPak is self-documenting via the standalone `planpak.md` command and the sections added to each workflow command
- **Target Audience**: Agent command users (LLM agents and developers using the plan workflow)

## Clarifications

### Session 2026-01-29

**Q1: Workflow Mode** → **Simple** (user specified "simple")
- Rationale: CS-3 but each change is a bounded section addition to existing files; single-phase plan appropriate

**Q2: Testing Strategy** → **Manual** (user specified "no TDD etc")
- Rationale: Changes are markdown prompt files; verification is `./setup.sh` deployment success

**Q3: Documentation Strategy** → **No new documentation**
- Rationale: The planpak.md standalone command IS the documentation; README update is a deliverable not separate docs

**Q4: Feature folder structure** → **Flat only**
- All files directly in `features/003-auth/` with descriptive names (e.g., `auth-service.ts`, `user-model.ts`). No internal subdirectories.

**Q5: Feature folder naming** → **Ordinal prefix**
- Format: `features/<ordinal>-<slug>/` (e.g., `features/003-auth/`). Matches `docs/plans/` naming. Provides chronological ordering and trivial plan-to-folder mapping.

---

**Spec Location**: `docs/plans/012-planpak/planpak-spec.md`
**Plan Folder**: `docs/plans/012-planpak/`
**Branch**: main
