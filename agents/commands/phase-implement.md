---
description: Executes an approved single-phase implementation brief using strict TDD; logs each test-driven cycle with diffs, commands, evidence, and acceptance mapping.
---

# Execute the Agreed Plan (Single Phase)

We have an approved brief for ONE phase. Execute EXACTLY that brief with strict TDD.

INPUTS
- Approved brief (paste below or reference file): {{BRIEF_REF}}
- Repo root: {{REPO_ROOT}}
- Branch: {{BRANCH}}
- Mode: {{DRY_RUN|apply}}   # if tooling supports apply/dry-run, default dry-run = true
- Constraints: {{CONSTRAINTS}}

EXECUTION CONTRACT
- TDD loop per test case: write/adjust test (red) → implement minimal code (green) → refactor (clean) → commit.
- Tests-as-documentation: assertions must demonstrate behavior, not just "true". :contentReference[oaicite:11]{index=11}
- No mocks; use real repo data/fixtures as specified in the brief (or repository-native equivalents). :contentReference[oaicite:12]{index=12}
- Follow stack-congruent runners and patterns (e.g., extension-host tests via Mocha; Python tests via pytest; use module-based debug configs where applicable; bounded searches, remote-safe paths, request-scoped context). :contentReference[oaicite:13]{index=13}
- Do not exceed the scope of {{PHASE_NAME}}. If you hit ambiguity, STOP and ask a single focused question.

OUTPUT FORMAT
1) Execution Log (concise)
   - For each TDD cycle: Test Added/Updated → Expected Failure (snippet) → Code Change Summary → Tests Passing (snippet) → Refactor note.

2) Changes (patches)
   - Provide unified diffs per file (minimal, self-contained).
   - Note any new files, config updates, or scripts.

3) Commands & Evidence
   - Exact commands run (copy/paste).
   - Key test runner output excerpts proving acceptance criteria.
   - Any debug/session evidence promised in the brief.

4) Risk/Impact & Rollback
   - Confirm no invariant was broken.
   - If any deviation from the brief was strictly necessary, explain, and gate on my approval.

5) Final Status
   - Checklist mapped to acceptance criteria with pass/fail.
   - Proposed commit message(s) and PR title with scope tags.

Begin now. If the brief is missing, STOP and ask me to provide it.
