---
description: Generate an Architectural Decision Record (ADR) from the feature spec and clarifications; persist to docs/adr and cross-link into the plan. Domain-aware v2.
---

Please deep think / ultrathink as this is a complex task.

# plan-3a-v2-adr

Generate a high-quality, **domain-aware ADR** from the spec (and optional plan), save it under `docs/adr/`, and wire cross-links so /plan-3-v2-architect and /plan-5-v2 can import constraints. Includes domain impact analysis, domain map integration, and domain.md backlinks.

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

### Domain Context Loading

Before research, load domain system context:

- **Read `## Target Domains` from spec** → list of existing and NEW domains relevant to this decision
- If `docs/domains/registry.md` exists → read all registered domains
- If `docs/domains/domain-map.md` exists → read the domain architecture diagram to understand current topology, contract relationships, and dependency flows
- For each existing domain in spec's target list → read `docs/domains/<slug>/domain.md`
  * Note: contracts (public interfaces), composition (internal structure), dependencies, boundary (owns/excludes)
- For each NEW domain in spec → note the sketch (Purpose, Boundary Owns/Excludes)
- If no domain system exists → note "No domain registry found — domain impact will be inferred from spec and codebase"

This context feeds into Subagent 5 (Domain Impact Analyzer) and informs the ADR's `## Domain Impact` section.

## 0a) Parallel Research Architecture

Launch **5** specialized research subagents (single message with 5 Task tool calls):

**Subagent 1: Existing ADR Scanner**
"Find and analyze all existing ADRs in docs/adr/.

**Tasks**:
- List all ADR files in docs/adr/
- Extract titles, statuses, and supersedes/superseded_by fields
- Identify ADRs that reference similar subsystems or tags
- Check for potential duplicates by title similarity
- Check for ADRs that reference the same domains

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
- Read spec's `## Target Domains` section for domain context

**Output**: Context drivers, implicit decisions, stakeholder list, affected domains
"

**Subagent 4: Alternative Analyzer**
"Generate and analyze alternative approaches.

**Tasks**:
- Based on constraints, generate 3-5 plausible alternatives
- For each alternative, identify pros/cons
- Determine rejection reasons for non-selected options
- Consider prior patterns in repo
- For each alternative, assess domain impact: does it change domain boundaries, contracts, or dependency direction?

**Output**: List of alternatives with descriptions, rejection rationale, and domain impact notes
"

**Subagent 5: Domain Impact Analyzer**
"Analyze how this architectural decision affects domain boundaries, contracts, and the domain map.

**Read**:
- `docs/domains/registry.md` (if exists)
- `docs/domains/domain-map.md` (if exists)
- `docs/domains/<slug>/domain.md` for each relevant domain
- Spec's `## Target Domains` section
- Plan's `## Domain Manifest` and `## Target Domains` (if plan provided)

**Tasks**:
1. **Identify affected domains**: Which domains does this decision touch?
2. **Contract impact**: Does the decision create, modify, or remove domain contracts?
   - New contracts introduced
   - Existing contracts changed (breaking vs non-breaking)
   - Contracts deprecated or removed
3. **Boundary impact**: Does the decision change what a domain owns or excludes?
   - Capabilities moving into or out of a domain
   - New domain creation triggered by this decision
   - Domain merges or splits implied
4. **Dependency impact**: Does the decision change the domain map topology?
   - New edges (domain dependencies)
   - Changed dependency direction
   - Risk of introducing circular business-domain dependencies
5. **Composition impact**: Does the decision add/remove/change internal domain components?
   - New services, adapters, repositories
   - Changed roles of existing components
6. **Domain map changes required**: What updates to domain-map.md does this decision imply?

**Output** (structured):
```json
{
  \"affected_domains\": [{\"slug\": \"...\", \"relationship\": \"modify|create|consume|deprecate\", \"summary\": \"...\"}],
  \"contract_changes\": [{\"domain\": \"...\", \"contract\": \"...\", \"change\": \"new|modified|breaking|removed\", \"detail\": \"...\"}],
  \"boundary_changes\": [{\"domain\": \"...\", \"change\": \"...\"}],
  \"dependency_changes\": [{\"from\": \"...\", \"to\": \"...\", \"change\": \"new|removed|reversed\", \"risk\": \"...\"}],
  \"map_updates_needed\": true/false,
  \"map_update_detail\": \"...\",
  \"risks\": [\"...\"]
}
```

If no domain system exists: infer likely domain impact from spec's Target Domains and codebase structure, and note recommendations for domain formalization.
"

**Wait for all 5 subagents to complete before proceeding.**

## 1) Context Extraction (deterministic)

From the parallel research synthesis:

* **Problem / Context drivers**: Combine findings from Decision Extractor
* **Decision candidates**: Merge Decision Extractor + Alternative Analyzer outputs
* **Alternatives**: Use Alternative Analyzer's 3-5 options (minimum 2 required)
* **Stakeholders**: From Decision Extractor or `--stakeholders` flag
* **Existing ADRs**: From ADR Scanner, check for conflicts/duplicates
* **Domain Impact**: From Domain Impact Analyzer — affected domains, contract changes, topology changes

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
domains: ["[slug]", "[slug]"]      # domains affected by this decision
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
  - Include domain context: which domains are in play, what contracts exist today

* `## Decision`
  - The chosen solution and rationale
  - MUST be ≤10 lines
  - Clear, actionable statement

* `## Domain Impact`

  **MANDATORY section.** Captures how the decision affects domain boundaries, contracts, and topology.

  ### Affected Domains

  | Domain | Relationship | Impact Summary |
  |--------|-------------|----------------|
  | [slug] | modify/create/consume/deprecate | [one-line impact] |

  ### Contract Changes

  | Domain | Contract | Change | Detail |
  |--------|----------|--------|--------|
  | [slug] | [contract name] | new/modified/breaking/removed | [what changes] |

  If no contract changes: "No contract changes — decision is internal to existing domain boundaries."

  ### Topology Changes

  [If the decision changes the domain map:]
  - New dependencies: [from] → [to] via [contract]
  - Removed dependencies: [description]
  - Risk assessment: [circular dep risk, fan-in concerns, etc.]

  [If no topology changes: "No topology changes — existing domain map edges are unaffected."]

  ### Domain Map Update Required

  **Yes/No**. If yes, briefly describe what changes: new nodes, new edges, updated labels, updated health summary.

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
  - `- **ALT-003**: **Domain Impact**: [How this alternative would have affected domains differently]`

  ### [Alternative 2 Name]
  - `- **ALT-004**: **Description**: [Brief technical description]`
  - `- **ALT-005**: **Rejection Reason**: [Why not selected]`
  - `- **ALT-006**: **Domain Impact**: [How this alternative would have affected domains differently]`

* `## Implementation Notes`
  - `- **IMP-001**: [Key implementation consideration]`
  - `- **IMP-002**: [Migration or rollout strategy]`
  - `- **IMP-003**: [Monitoring and success criteria]`
  - `- **IMP-004**: [Domain artifacts to update — domain.md, registry.md, domain-map.md as applicable]`

* `## References` (MUST include spec/plan/domain links)
  - `- **REF-001**: [Spec](../../<ordinal>-<slug>/<slug>-spec.md)`
  - `- **REF-002**: [Plan](../../<ordinal>-<slug>/<slug>-plan.md)` (if --plan provided)
  - `- **REF-003**: [Related ADRs or external docs]`
  - `- **REF-004**: [Standards/frameworks referenced]`
  - `- **REF-005**: [Domain docs](../../domains/<slug>/domain.md)` (for each affected domain)

### Validation Rules (abort with actionable error if violated)

1. **Code format**: All codes MUST be 3-4 letters + 3 digits (e.g., POS-001, ALT-002)
2. **Minimum counts**: ≥3 POS, ≥3 NEG, ≥2 Alternatives
3. **Front matter**: All fields present, even if empty
4. **Date format**: YYYY-MM-DD
5. **Status values**: Only allowed values listed above
6. **Domain Impact section**: MUST be present with Affected Domains table
7. **Domains frontmatter**: MUST list at least one domain slug (or `["none"]` if truly domain-agnostic)

## 3) Cross-Linking & Provenance

### Update ADR References
* In `## References`, include:
  - `[Spec](../../<ordinal>-<slug>/<slug>-spec.md)` (always)
  - `[Plan](../../<ordinal>-<slug>/<slug>-plan.md)` (if --plan provided)
  - `[Domain: <slug>](../../domains/<slug>/domain.md)` (for each affected domain)

### Update Spec with ADR Backlink
* Open spec file
* Look for `## ADRs` section (create after `## ADR Seeds` if missing)
* Append: `- ADR-NNNN: [Decision Title] ({{TODAY}}) – status: <status> – domains: [slug, slug]`

### Update Plan with ADR Ledger (if plan exists)
* Open plan file
* Look for `## ADR Ledger` section (create after `## Technical Context` if missing)
* Add row to table:
  ```markdown
  | ADR | Title | Status | Date | Affected Domains | Affects Phases |
  |-----|-------|--------|------|------------------|----------------|
  | NNNN | [Title] | <status> | {{TODAY}} | [domain slugs] | [Phase list or "TBD"] |
  ```

### Update Domain Files (for each affected domain)

For each domain listed in `## Domain Impact → Affected Domains`:

a) **If `docs/domains/<slug>/domain.md` exists**:
   - Look for `## ADRs` section (create at bottom before `## History` if missing)
   - Append: `- [ADR-NNNN: Decision Title](../../adr/adr-NNNN-[title-slug].md) — <status> — [impact summary]`

b) **Update domain.md § History**:
   ```markdown
   | ADR-NNNN | [Decision Title] — [one-line impact] | {{TODAY}} |
   ```

c) **If contract changes identified**: Note in domain.md § Contracts that a pending ADR affects this contract (append comment or note — do NOT modify actual contract definitions until implementation)

### Update Domain Map (if domain map update required)

If Domain Impact Analyzer flagged `map_updates_needed: true`:

- Read `docs/domains/domain-map.md`
- Add/modify domain nodes, edges, or labels as specified
- Update Health Summary table
- Add a comment in the Mermaid diagram noting the ADR:
  ```
  %% ADR-NNNN: [brief note about what changed]
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

  | ADR | Title | Date | Status | Domains | Supersedes | Superseded By |
  |-----|-------|------|--------|---------|------------|---------------|
  ```
* Append row:
  ```markdown
  | NNNN | [Decision Title] | {{TODAY}} | <status> | [domain slugs] | <supersedes or "-"> | <superseded_by or "-"> |
  ```

## 5) Success Output

```
✅ ADR created
File: docs/adr/adr-NNNN-[title-slug].md
Status: <status>
Domains: [affected domain slugs]
Backlinks: Spec linked=Y, Plan linked=<Y/N>
Cross-references updated:
  - Spec: Added to ## ADRs section
  - Plan: Added to ADR Ledger (if applicable)
  - Index: Updated docs/adr/README.md
  - Domain docs: [N] domain.md files updated with ADR backlink
  - Domain map: [Updated/No changes needed]

ADR Ledger:
| ADR  | Title               | Status    | Date       | Domains    | Affects    |
|------|---------------------|-----------|------------|------------|------------|
| NNNN | [Decision Title]    | <status>  | {{TODAY}}  | [slugs]    | [Phases]   |

Domain Impact Summary:
| Domain | Relationship | Contract Changes | Map Update |
|--------|-------------|-----------------|------------|
| [slug] | [modify]    | [summary]       | [yes/no]   |

Next steps:
- Option A: proceed to /plan-3-v2-architect (plan uses this ADR)
- Option B: rerun /plan-3a-v2-adr for additional decisions
- Option C: review ADR at docs/adr/adr-NNNN-[title-slug].md
```

## 6) Validation Checklist (must all pass)

- [ ] Spec present and fully parsed
- [ ] Context/Decision/Alternatives/Stakeholders resolved
- [ ] POS codes: exactly 3-4 letters + 3 digits, minimum 3 entries
- [ ] NEG codes: exactly 3-4 letters + 3 digits, minimum 3 entries
- [ ] ALT codes: minimum 2 alternatives with descriptions and rejection reasons
- [ ] IMP codes: minimum 3 implementation notes
- [ ] REF codes: includes spec link, plan link if applicable, domain doc links
- [ ] Front matter complete with all fields (even if empty)
- [ ] Front matter `domains` field lists affected domain slugs
- [ ] Date format: YYYY-MM-DD
- [ ] File path: `docs/adr/adr-NNNN-[title-slug].md`
- [ ] `## Domain Impact` section present with Affected Domains table
- [ ] Spec updated with ADR backlink
- [ ] Plan updated with ADR ledger entry (if plan exists)
- [ ] Index updated in docs/adr/README.md
- [ ] Domain.md files updated with ADR backlink (for each affected domain)
- [ ] Domain map updated (if changes required)
- [ ] Atomic write completed successfully

## 7) Error Handling

If validation fails, provide actionable error:
```
❌ ADR creation failed

Validation errors:
- Missing minimum POS codes (found 2, need 3)
- Invalid code format in NEG-01 (should be NEG-001)
- Missing rejection reason for Alternative 2
- Missing ## Domain Impact section
- Front matter 'domains' field empty

Fix these issues and retry with --replace NNNN flag
```

## 8) Style & Determinism

* Mirror heading, spacing, and code formatting exactly as above
* Slug and numbering stable across re-runs (idempotent if inputs unchanged)
* Keep ADRs technology-agnostic unless constraints force specificity
* Use consistent voice (active, present tense for decisions)
* Maintain strict validation to ensure machine parseability
* Domain Impact section uses the same vocabulary as the domain system: contracts, composition, boundary, dependency direction
* Dependency rules apply: business → infrastructure ✅, infrastructure → business ❌, business → business via contracts only ⚠️

Next steps:
- Proceed to **/plan-3-v2-architect** (plan uses this ADR)
- Or rerun **/plan-3a-v2-adr** for additional decisions
