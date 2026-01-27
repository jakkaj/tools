# Cross-Branch Plan Ordinal Counter Tool

**Mode**: Simple

## Summary

Create a CLI tool (`plan-ordinal`) that scans all git branches to find existing plan folders in `docs/plans/` and returns the next available ordinal number. This prevents ordinal collisions when multiple feature branches create plans concurrently, which the current filesystem-only approach cannot detect.

**WHAT**: A Python script that uses `git ls-tree` to enumerate `docs/plans/NNN-*` folders across all local and remote branches, finds the maximum ordinal, and outputs the next available number (e.g., "011").

**WHY**: Plan creation commands (`/plan-1a-explore`, `/plan-1b-specify`) currently count folders only on the current branch. When developers work on parallel feature branches and each creates a new plan, they get the same ordinal, causing merge conflicts. This tool eliminates that collision risk.

## Goals

- Provide accurate cross-branch ordinal counting via `git ls-tree` (no checkouts required)
- Output a simple 3-digit zero-padded ordinal (e.g., "011") for easy integration
- Follow existing tool conventions (`--help`, alias generation, exit codes)
- Work from any directory within the git repository
- Support both local and remote branch scanning
- Provide JSON output option for programmatic consumption
- Enable graceful fallback when tool is unavailable (plan commands should prompt user)

## Non-Goals

- Modifying existing plan folders or their structure
- Reserving or locking ordinals (accept low collision risk for concurrent tool invocations)
- Checking ordinal gaps or suggesting gap-filling (always use max+1)
- Validating plan folder contents (only checks folder naming pattern)
- Cross-repository plan coordination (single repo scope only)
- Automatic integration with plan commands (that's a separate change)

## Complexity

* **Score**: CS-2 (small)
* **Breakdown**: S=1, I=0, D=0, N=0, F=0, T=1
  - Surface Area (S=1): Single new script file + alias registration (2-3 files touched)
  - Integration (I=0): Internal only - uses git CLI which is always available
  - Data/State (D=0): No schema changes, no persistent state
  - Novelty (N=0): Well-specified requirements, clear algorithm from research
  - Non-Functional (F=0): Standard CLI tool, no performance/security concerns
  - Testing/Rollout (T=1): Needs integration tests across branch scenarios
* **Confidence**: 0.90
* **Assumptions**:
  - Git is always available in environments where this tool runs
  - `docs/plans/` follows the established `NNN-slug` naming convention
  - Remote branches are fetched (`git fetch` has been run)
* **Dependencies**: None beyond git CLI
* **Risks**:
  - Remote branches not fetched could miss ordinals (mitigated by documenting requirement)
  - Very large repos with many branches could be slow (mitigated by branch deduplication)
* **Phases**:
  1. Implement core script with `--help`, `--next`, `--current`, `--json` options
  2. Add to scripts/, run setup.sh for alias generation
  3. Test across branch scenarios

## Acceptance Criteria

1. **Basic ordinal retrieval**: Running `plan-ordinal` in a git repo with plans 001-010 on main branch outputs `011`
2. **Cross-branch detection**: If branch `feature/x` has plan 011 and main has 001-010, running `plan-ordinal` from main outputs `012`
3. **Remote branch inclusion**: Plans on `origin/feature-y` are detected even if not checked out locally
4. **Empty state handling**: Running in a repo with no `docs/plans/` outputs `001`
5. **Non-git error**: Running outside a git repository outputs error message and exits with code 1
6. **Help output**: `plan-ordinal --help` displays NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES sections
7. **JSON output**: `plan-ordinal --json` outputs `{"next": 11}` (integer, not string)
8. **Current ordinal**: `plan-ordinal --current` outputs highest existing ordinal (e.g., `010`)
9. **Alias registration**: After `./setup.sh`, the alias `jk-po` invokes the tool
10. **Directory independence**: Tool works correctly when run from any subdirectory of the repo

## Risks & Assumptions

### Risks
- **Unfetched remotes**: If `git fetch` hasn't been run, remote branch plans may be missed. Mitigation: Document this requirement; optionally add `--fetch` flag.
- **Concurrent invocation**: Two users running the tool simultaneously could both get the same "next" ordinal. Mitigation: Accept as low probability; plan creation will fail visibly on folder collision.
- **Large branch count**: Repos with hundreds of branches could experience slowness. Mitigation: Branch deduplication, consider `--local-only` flag for speed.

### Assumptions
- All plan folders follow the `NNN-slug` naming convention (3-digit prefix)
- Git CLI is available and functional
- Users have read access to all branches
- The `docs/plans/` path is consistent across branches

## Open Questions

*All critical questions resolved. The following were deferred to future iterations:*

1. ~~**Should the tool auto-fetch remotes?**~~ **DEFERRED**: v1 uses minimal flags; document `git fetch` as user prerequisite
2. ~~**Should there be a `--local-only` flag?**~~ **DEFERRED**: v1 scans all branches; add optimization if performance issues emerge

## Documentation Strategy

- **Location**: README.md only
- **Rationale**: Tool's `--help` provides detailed usage; README entry for discoverability
- **Content**: Brief entry in README's tool listing with purpose and example
- **Target Audience**: Developers using plan commands
- **Maintenance**: Update if flags change

## Testing Strategy

- **Approach**: Manual Only
- **Rationale**: Simple CLI tool with straightforward git operations; manual verification sufficient
- **Focus Areas**: Cross-branch ordinal detection, edge cases (no plans, non-git directory)
- **Excluded**: Automated test suite
- **Verification Steps**:
  1. Run in repo with existing plans → verify correct ordinal output
  2. Create test branch with additional plan → verify detection
  3. Run outside git repo → verify error handling
  4. Test `--help`, `--json`, `--current` flags

## ADR Seeds (Optional)

* **Decision Drivers**:
  - Must work without modifying working directory (no checkouts)
  - Must be fast enough for interactive use
  - Must follow existing tool conventions in this repo
* **Candidate Alternatives**:
  - A: Python script using `git ls-tree` (proposed)
  - B: Bash script using same git commands (simpler but less portable)
  - C: Central ordinal registry file checked into repo (more complex, different tradeoffs)
* **Stakeholders**: Developers using plan commands across feature branches

## Clarifications

### Session 2026-01-27

**Q1: Testing Strategy**
- Question: What testing approach best fits this feature's complexity and risk profile?
- Answer: D (Manual Only)
- Rationale: Simple CLI tool with straightforward git operations

**Q2: Documentation Strategy**
- Question: Where should this feature's documentation live?
- Answer: A (README.md only)
- Rationale: Tool's --help provides detail; README entry for discoverability

**Q3: Optional Flags Scope**
- Question: Should we implement optional network/performance flags in v1?
- Answer: A (Minimal - core flags only)
- Rationale: Keep v1 simple; document git fetch prerequisite; add flags if pain points emerge

---

*ℹ️ This specification incorporates findings from prior `/plan-1a-explore` research conducted in-conversation. Key insights: `git ls-tree` enables branch inspection without checkout; existing tools follow `--help` convention with `jk-` prefix aliases; Python preferred for subprocess handling.*
