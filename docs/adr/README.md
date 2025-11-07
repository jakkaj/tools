# ADR Index

This directory contains Architectural Decision Records (ADRs) that document important architectural decisions made for this project.

## ADR Status Definitions

- **Proposed**: Decision under consideration, not yet approved
- **Accepted**: Decision approved and should be followed
- **Rejected**: Decision considered but not adopted
- **Superseded**: Decision replaced by a newer ADR
- **Deprecated**: Decision no longer relevant but kept for historical record

## ADR Table

| ADR | Title | Date | Status | Supersedes | Superseded By |
|-----|-------|------|--------|------------|---------------|

## How to Create a New ADR

1. Run `/plan-3a-adr` command after creating a feature spec
2. The command will:
   - Automatically assign the next sequential number (0001, 0002, etc.)
   - Generate the ADR from spec and clarifications
   - Create proper cross-links to specs and plans
   - Update this index table

## ADR Format

Each ADR follows a strict format with:
- **Front matter**: YAML metadata with title, status, date, authors, tags
- **Sections**: Status, Context, Decision, Consequences (Positive/Negative), Alternatives, Implementation Notes, References
- **Coding scheme**: POS-001, NEG-001, ALT-001, IMP-001, REF-001 for machine parsing

## Cross-References

ADRs are cross-referenced in:
- Feature specs: `## ADRs` section lists related ADRs
- Implementation plans: ADR Ledger table tracks constraints
- Task dossiers: Notes column tags tasks with "Per ADR-NNNN"

## Maintenance

- ADR status changes are semi-automated (system suggests, user confirms)
- When superseding an ADR, both the old and new ADRs are updated
- This index is automatically maintained by the `/plan-3a-adr` command