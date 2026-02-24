# V2 Commands — Domain-Aware Plan Workflow

These commands are **standalone rewrites** of select v1 commands from `agents/commands/`, incorporating:

- **Domain system**: First-class business domain boundaries that own code, contracts, and composition
- **Leaner output**: Slimmer plan and task artifacts that provide guardrails without removing implementor agency
- **Domain-based organization**: File placement follows business domains, not plan chronology

## When to Use V2 vs V1

| Use V2 when... | Use V1 when... |
|----------------|----------------|
| Project uses or wants domain-based organization | Project doesn't use domains |
| You want leaner plan/task output | You want the full-detail v1 output |
| You're working on a brownfield codebase and want to formalize concepts | Quick fixes that don't need domain tracking |

## Commands

| Command | Replaces | What's Different |
|---------|----------|-----------------|
| `plan-v2-extract-domain` | *(new)* | Collaboratively identify and formalize existing code as a named domain |
| `plan-1b-v2-specify` | `plan-1b-specify` | Adds `## Target Domains` section to spec |
| `plan-2-v2-clarify` | `plan-2-clarify` | Domain Review question for boundary validation |
| `plan-3-v2-architect` | `plan-3-architect` | Lean output (≤500 lines), 2 research subagents, domain manifest |
| `plan-4-v2-complete-the-plan` | `plan-4-complete-the-plan` | Domain completeness validation, no false positives on lean plan format |
| `plan-5-v2-phase-tasks-and-brief` | `plan-5-phase-tasks-and-brief` | 7-column task table with Domain column, simplified prior-phase review |
| `plan-6-v2-implement-phase` | `plan-6-implement-phase` | Domain placement rules, post-implementation domain.md updates |
| `plan-6a-v2-update-progress` | `plan-6a-update-progress` | Domain context in progress tracking |
| `plan-7-v2-code-review` | `plan-7-code-review` | Domain Compliance Validator, anti-reinvention checks |
| `plan-2c-v2-workshop` | `plan-2c-workshop` | Domain context in workshop design documents |
| `didyouknow-v2` | `didyouknow` | Domain boundary/contract insights when relevant |

## Commands That Don't Need V2

These work unchanged with domain-aware projects:

`plan-0-constitution`, `plan-1a-explore`, `plan-2b-prep-issue`, `plan-3a-adr`, `plan-5b-flightplan`, `plan-5c-requirements-flow`, `plan-6b-worked-example`, `plan-8-merge`, `code-concept-search`, `deepresearch`, `flowspace-research`, `tad`, `util-0-handover`

## Domain System Overview

Domains are persistent, named business concept boundaries. Every source file belongs to a domain. Plans deliver into domains.

```
docs/domains/
├── registry.md              # Master index of all domains
├── domain-map.md            # Mermaid architecture diagram — domains as components with contract edges
├── auth/
│   ├── domain.md            # Locked-down definition (required sections)
│   └── *.md                 # Freeform notes, sketches, research
└── _platform/               # Infrastructure parent domain
    └── data-access/
        └── domain.md

src/
├── auth/                    # Mirrors docs/domains/auth/
├── billing/                 # Mirrors docs/domains/billing/
└── _platform/               # Mirrors docs/domains/_platform/
```

The **domain map** (`domain-map.md`) shows all domains as components with labeled contract edges between them. It validates that domains are truly first-class — if a domain can't be placed on the map with clear contracts in/out, it needs better definition.

See `plan-v2-extract-domain.md` for the full domain.md template, registry format, and domain map format.
