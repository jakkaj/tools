---
mode: 'agent'
description: 'Generate an Architectural Decision Record (ADR) from the feature spec and clarifications; persist to docs/adr and cross-link into the plan.'

---

Please deep think / ultrathink as this is a complex task.

# plan-3a-adr (alias: architect-adr, /3a)

**Goal:** Generate a high-quality ADR from the spec (and optional plan), save it under `docs/adr/`, and wire cross-links so /3 and /5 can import constraints.

```md
User input:

$ARGUMENTS
# Expected flags:
# --spec  "<abs path to docs/plans/<ordinal>-<slug>/<slug>-spec.md>"     # REQUIRED
# --plan  "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"     # OPTIONAL (link if present)
# --title "Decision Title"                                               # OPTIONAL (derive if absent)
# --status "Proposed|Accepted|Rejected|Superseded|Deprecated"            # OPTIONAL (default "Proposed")
# --stakeholders "Name (Role); Name (Role); ..."                         # OPTIONAL (derive if absent)
# --replace NNNN                                                         # OPTIONAL (update existing ADR)
# --non-interactive                                                      # OPTIONAL (assume defaults)
# --supersedes NNNN                                                      # OPTIONAL (mark older ADR as superseded)
```

## 0) Inputs & Pre-flight

* **FEATURE_SPEC** = `--spec` (REQUIRED; abort if missing)
* **PLAN_PATH**    = `--plan` (OPTIONAL; used for backlinks)
* **TODAY**        = {{TODAY}}

**Pre-flight checks:**
1. Abort if `--spec` missing. Read spec (entire file).
2. If `--plan` exists, read for references only.
3. If doctrine files exist (`docs/project-rules/{constitution.md, rules.md, idioms.md, architecture.md}`), load for alignment cues.
4. Compute ADR dir = `docs/adr/` (mkdir -p if needed). Scan for `adr-*.md`.
5. **Idempotency check**:
   - Normalize `--title` or derived title → `[title-slug]`
   - If file matching `adr-????-[title-slug].md` exists:
     - If `--replace` not set: prompt (or with `--non-interactive`, create new with suffix `-2`)
     - If `--replace NNNN`: update that file in place (preserve history)

**Parallel Research Architecture**

Launch 4 specialized research subagents (single message with 4 Task tool calls):

**Subagent 1: Existing ADR Scanner**
"Find and analyze all existing ADRs in docs/adr/.

**Tasks**:
- List all ADR files in docs/adr/
- Extract titles, statuses, and supersedes/superseded_by fields
- Identify ADRs that reference similar subsystems or tags
- Check for potential duplicates by title similarity

**Output**: List of existing ADRs with metadata, potential conflicts/duplicates
"

**Subagent 2: Doctrine Mapper**
"Read and extract constraints from doctrine files.

**Tasks**:
- Read docs/project-rules/constitution.md if present
- Read docs/project-rules/{rules.md, idioms.md, architecture.md} if present
- Extract architectural principles that affect this decision
- Identify guardrails and constraints

**Output**: List of doctrine constraints relevant to the decision
"

**Subagent 3: Decision Extractor**
"Extract decision context from spec and clarifications.

**Tasks**:
- Read spec Summary, Goals, Risks & Assumptions, Clarifications
- Identify decision drivers (constraints/NFRs)
- Extract any architectural choices already made
- Find stakeholder references

**Output**: Context drivers, implicit decisions, stakeholder list
"

**Subagent 4: Alternative Analyzer**
"Generate and analyze alternative approaches.

**Tasks**:
- Based on constraints, generate 3-5 plausible alternatives
- For each alternative, identify pros/cons
- Determine rejection reasons for non-selected options
- Consider prior patterns in repo

**Output**: List of alternatives with descriptions and rejection rationale
"

**Wait for all 4 subagents to complete before proceeding.**

## 1) Context Extraction (deterministic)

From the parallel research synthesis:

* **Problem / Context drivers**: Combine findings from Decision Extractor
* **Decision candidates**: Merge Decision Extractor + Alternative Analyzer outputs
* **Alternatives**: Use Alternative Analyzer's 3-5 options (minimum 2 required)
* **Stakeholders**: From Decision Extractor or `--stakeholders` flag
* **Existing ADRs**: From ADR Scanner, check for conflicts/duplicates

**Duplicate Detection**:
- If ADR Scanner found similar titles (normalized match):
  - With `--non-interactive`: create new with `-2` suffix
  - Otherwise: prompt user with options:
    1. Create new ADR (different decision)
    2. Update existing ADR (same decision, new info)
    3. Abort and review existing ADR

If any of the ADR template's **required inputs** cannot be inferred:

* Ask **≤4** focused questions (short answer or multiple-choice) to complete:
  - **Decision Title** (if not provided)
  - **Context** (1-3 sentences)
  - **Chosen Decision** (1 paragraph, ≤10 lines)
  - **Alternatives** (names + 1-line summaries, minimum 2)
  - **Stakeholders** (names or roles)
* Persist answers back into the spec under `## Clarifications -> ### Session {{TODAY}}` (append; do not overwrite).

## 2) ADR Synthesis Rules (strict validation)

Generate content following this exact structure and coding scheme:

### Front Matter (ALL fields required)

```yaml
---
title: "ADR-NNNN: [Decision Title]"
status: "<status>"                 # default: Proposed
date: "{{TODAY}}"                  # YYYY-MM-DD format
authors: "[Stakeholder Names/Roles]"
tags: ["architecture", "decision", "[subsystem]", "[feature]"]
supersedes: ""                     # Fill if --supersedes NNNN provided
superseded_by: ""                  # Leave empty (filled when superseded)
---
```

### Sections and Codes (ALL required with validation)

* `# ADR-NNNN: [Decision Title]`

* `## Status`
  - MUST be one of: **Proposed | Accepted | Rejected | Superseded | Deprecated**

* `## Context`
  - Tight problem statement + constraints (no solutioning)
  - 3-10 sentences maximum

* `## Decision`
  - The chosen solution and rationale
  - MUST be ≤10 lines
  - Clear, actionable statement

* `## Consequences`

  **Positive** (MINIMUM 3 required)
  - `- **POS-001**: [Beneficial outcome]`
  - `- **POS-002**: [Performance/maintainability improvement]`
  - `- **POS-003**: [Alignment with principles]`

  **Negative** (MINIMUM 3 required)
  - `- **NEG-001**: [Trade-off or limitation]`
  - `- **NEG-002**: [Technical debt or complexity]`
  - `- **NEG-003**: [Risk or future challenge]`

* `## Alternatives Considered` (MINIMUM 2 required)

  ### [Alternative 1 Name]
  - `- **ALT-001**: **Description**: [Brief technical description]`
  - `- **ALT-002**: **Rejection Reason**: [Why not selected]`

  ### [Alternative 2 Name]
  - `- **ALT-003**: **Description**: [Brief technical description]`
  - `- **ALT-004**: **Rejection Reason**: [Why not selected]`

* `## Implementation Notes`
  - `- **IMP-001**: [Key implementation consideration]`
  - `- **IMP-002**: [Migration or rollout strategy]`
  - `- **IMP-003**: [Monitoring and success criteria]`

* `## References` (MUST include spec/plan links)
  - `- **REF-001**: [Spec](../../<ordinal>-<slug>/<slug>-spec.md)`
  - `- **REF-002**: [Plan](../../<ordinal>-<slug>/<slug>-plan.md)` (if --plan provided)
  - `- **REF-003**: [Related ADRs or external docs]`
  - `- **REF-004**: [Standards/frameworks referenced]`

### Validation Rules (abort with actionable error if violated)

1. **Code format**: All codes MUST be 3-4 letters + 3 digits (e.g., POS-001, ALT-002)
2. **Minimum counts**: ≥3 POS, ≥3 NEG, ≥2 Alternatives
3. **Front matter**: All fields present, even if empty
4. **Date format**: YYYY-MM-DD
5. **Status values**: Only allowed values listed above

## 3) Cross-Linking & Provenance

### Update ADR References
* In `## References`, include:
  - `[Spec](../../<ordinal>-<slug>/<slug>-spec.md)` (always)
  - `[Plan](../../<ordinal>-<slug>/<slug>-plan.md)` (if --plan provided)

### Update Spec with ADR Backlink
* Open spec file
* Look for `## ADRs` section (create after `## ADR Seeds` if missing)
* Append: `- ADR-NNNN: [Decision Title] ({{TODAY}}) – status: <status>`

### Update Plan with ADR Ledger (if plan exists)
* Open plan file
* Look for `## ADR Ledger` section (create after `## Technical Context` if missing)
* Add row to table:
  ```markdown
  | ADR | Title | Status | Date | Affects Phases |
  |-----|-------|--------|------|----------------|
  | NNNN | [Title] | <status> | {{TODAY}} | [Phase list or "TBD"] |
  ```

### Handle Superseding (if --supersedes NNNN)
* Open old ADR file (adr-NNNN-*.md)
* Update its front matter: `status: "Superseded"`, `superseded_by: "NNNN"`
* In new ADR, set front matter: `supersedes: "NNNN"`

## 4) Numbering & File Writing (atomic)

### Determine NNNN
```bash
# Find next number
EXISTING=$(ls docs/adr/adr-*.md 2>/dev/null | sed 's/.*adr-\([0-9]*\).*/\1/' | sort -n | tail -1)
NEXT=$(printf "%04d" $((${EXISTING:-0} + 1)))
```

### Slugification
```bash
# Normalize title to slug
SLUG=$(echo "${TITLE}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
```

### Atomic Write
1. Write to temp file: `docs/adr/.tmp-adr-NNNN-[slug].md`
2. Validate content (all sections present, codes valid)
3. Rename atomically: `mv docs/adr/.tmp-* docs/adr/adr-NNNN-[slug].md`

### Update Index
* Open/create `docs/adr/README.md`
* Add header if new:
  ```markdown
  # ADR Index

  | ADR | Title | Date | Status | Supersedes | Superseded By |
  |-----|-------|------|--------|------------|---------------|
  ```
* Append row:
  ```markdown
  | NNNN | [Decision Title] | {{TODAY}} | <status> | <supersedes or "-"> | <superseded_by or "-"> |
  ```

## 5) Success Output

```
✅ ADR created
File: docs/adr/adr-NNNN-[title-slug].md
Status: <status>
Backlinks: Spec linked=Y, Plan linked=<Y/N>
Cross-references updated:
  - Spec: Added to ## ADRs section
  - Plan: Added to ADR Ledger (if applicable)
  - Index: Updated docs/adr/README.md

ADR Ledger:
| ADR  | Title               | Status    | Date       | Affects    |
|------|---------------------|-----------|------------|------------|
| NNNN | [Decision Title]    | <status>  | {{TODAY}}  | [Phases]   |

Next steps:
- Option A: proceed to /plan-3-architect (plan uses this ADR)
- Option B: rerun /plan-3a-adr for additional decisions
- Option C: review ADR at docs/adr/adr-NNNN-[title-slug].md
```

## 6) Validation Checklist (must all pass)

- [ ] Spec present and fully parsed
- [ ] Context/Decision/Alternatives/Stakeholders resolved
- [ ] POS codes: exactly 3-4 letters + 3 digits, minimum 3 entries
- [ ] NEG codes: exactly 3-4 letters + 3 digits, minimum 3 entries
- [ ] ALT codes: minimum 2 alternatives with descriptions and rejection reasons
- [ ] IMP codes: minimum 3 implementation notes
- [ ] REF codes: includes spec link, plan link if applicable
- [ ] Front matter complete with all fields (even if empty)
- [ ] Date format: YYYY-MM-DD
- [ ] File path: `docs/adr/adr-NNNN-[title-slug].md`
- [ ] Spec updated with ADR backlink
- [ ] Plan updated with ADR ledger entry (if plan exists)
- [ ] Index updated in docs/adr/README.md
- [ ] Atomic write completed successfully

## 7) Error Handling

If validation fails, provide actionable error:
```
❌ ADR creation failed

Validation errors:
- Missing minimum POS codes (found 2, need 3)
- Invalid code format in NEG-01 (should be NEG-001)
- Missing rejection reason for Alternative 2

Fix these issues and retry with --replace NNNN flag
```

## 8) Style & Determinism

* Mirror heading, spacing, and code formatting exactly as above
* Slug and numbering stable across re-runs (idempotent if inputs unchanged)
* Keep ADRs technology-agnostic unless constraints force specificity
* Use consistent voice (active, present tense for decisions)
* Maintain strict validation to ensure machine parseability