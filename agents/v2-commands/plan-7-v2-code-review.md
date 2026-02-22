---
description: Read-only per-phase code review with domain compliance validation. V2 standalone rewrite.
---

Please deep think / ultrathink as this is a complex task.

# plan-7-v2-code-review

Read-only code review that inspects diffs, verifies domain compliance, checks for concept reinvention, and produces structured findings. Does NOT modify code.

---

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>" (Full Mode) or omitted (Simple Mode)
# --plan "<abs path to plan.md>"

## Steps

1) Resolve paths:
   - PLAN, PLAN_DIR, SPEC from --plan
   - Full Mode: PHASE_DIR, tasks.md, execution.log.md
   - Simple Mode: read inline tasks from plan

2) Gather diffs:
   - Read execution.log.md for files changed
   - Use `git diff` to collect actual changes
   - If no git changes, read file list from task table Path(s) column

3) Launch review subagents in parallel:

### Subagent 1: Implementation Quality
"Review the code changes for this phase.

Read:
- All changed files (from diffs)
- Task table (expected changes)
- Acceptance criteria

Check:
- Do changes match what the tasks specified?
- Are there obvious bugs, logic errors, or security issues?
- Is error handling adequate?
- Are edge cases handled?
- Does the code follow existing patterns in the codebase?

Output: Findings as SEVERITY (HIGH/MEDIUM/LOW) | File | Issue | Suggestion
Only report issues that genuinely matter. No style nits."

### Subagent 2: Domain Compliance Validator
"Validate domain compliance for all changes in this phase.

Read:
- `docs/domains/registry.md` — all registered domains
- `docs/domains/<slug>/domain.md` — for each domain touched
- Plan's Domain Manifest — expected file→domain mapping
- All changed files

Check:
1. **File placement**: Every new file is under its declared domain's source tree
2. **Contract-only imports**: No imports from another domain's internal files
   (only contracts/ or public exports are allowed)
3. **Dependency direction**:
   - business → infrastructure: ✅
   - infrastructure → business: ❌ VIOLATION
   - business → business: only via contracts
4. **Domain.md currency**: domain.md § History updated for this plan,
   § Composition updated if new components added,
   § Contracts updated if public interface changed
5. **Registry currency**: docs/domains/registry.md reflects any new domains
6. **No orphan files**: Every changed file maps to a domain in the manifest

Output: Findings as SEVERITY | File | Rule Violated | Details | Fix"

### Subagent 3: Anti-Reinvention Check
"Check whether this phase introduced functionality that already exists in another domain.

Read:
- All NEW files created in this phase
- `docs/domains/*/domain.md` — contracts and composition for all domains

For each major new component (service, adapter, repository, handler):
1. Run `/code-concept-search "<component concept>"` against the codebase
2. Check domain contracts for overlapping capabilities
3. Flag if similar functionality exists in another domain

Output: Findings as SEVERITY | New Component | Existing Match | Domain | Recommendation
Only flag genuine duplication, not incidental similarity."

4) Collect and merge findings from all subagents.

5) Produce structured review:

```markdown
# Code Review: [Phase Title]

**Plan**: [path]
**Date**: [today]
**Reviewer**: Automated (plan-7-v2)

## Summary

[2-3 sentences: overall quality, domain compliance status, reinvention check results]

## Findings

### Critical (must fix)
| # | File | Issue | Recommendation |
|---|------|-------|---------------|

### High (should fix)
| # | File | Issue | Recommendation |
|---|------|-------|---------------|

### Medium (consider)
| # | File | Issue | Recommendation |
|---|------|-------|---------------|

## Domain Compliance

| Check | Status | Details |
|-------|--------|---------|
| File placement | ✅/❌ | [details] |
| Contract-only imports | ✅/❌ | [details] |
| Dependency direction | ✅/❌ | [details] |
| Domain.md updated | ✅/❌ | [details] |
| Registry current | ✅/❌ | [details] |
| No orphan files | ✅/❌ | [details] |

## Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| [component] | None found | — | ✅ Clean |
| [component] | [similar in domain X] | [domain] | ⚠️ Review |

## Verdict

**[PASS | PASS WITH NOTES | NEEDS FIXES]**

[If NEEDS FIXES: list the critical/high items that must be addressed]
```

6) Save review to PHASE_DIR (Full Mode) or PLAN_DIR (Simple Mode).

STOP: This is a read-only review. Do NOT modify any code.
```

Output: Structured review with domain compliance validation, anti-reinvention results, and verdict.
