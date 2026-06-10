# Skills Pipeline — Domain-Aware Plan Workflow

These skills (installed via `npx skills add jakkaj/tools -a <cli>` from `/skills/SDD/`) are the active spec-driven-development pipeline, incorporating:

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
| `the-flow` | *(new)* | **Guided co-pilot front-door** that *drives/narrates* the whole `plan-*` pipeline conversationally — asks what you want to build, routes to `/plan-1a`/`/plan-1b`, narrates each seam with one artifact insight, surfaces the optional branches (`/plan-2c`), `/compact` seams, and the harness seams (routed via `/eng-harness-flow`), and tells you the exact next command. Re-entrant via on-disk state (survives `/compact`); can **adopt** an in-flight plan. Coaches only — never runs `/plan-*`/code/merge itself, never gates. Drives real `plan-*` work (not an RPIV/`task-*` teaching loop); bundles the visual pipeline guide at `references/getting-started.md`. |
| `plan-v2-extract-domain` | *(new)* | Collaboratively identify and formalize existing code as a named domain |
| `plan-1a-v2-explore` | `plan-1a-explore` | Domain & Boundary Scout subagent, domain context in research output |
| `plan-1b-v3-specify-and-clarify` | `plan-1b-specify` + `plan-2-clarify` | Merged: front-loaded batched questions before spec sketch + conditional post-sketch round. Replaces both v2 skills. |
| `plan-2-v2-clarify` | `plan-2-clarify` | Soft-deprecated mid-plan re-entry point (≤4 questions). For new specs use `plan-1b-v3-specify-and-clarify`. |
| `plan-3-v3-architect` | `plan-3-architect` + `plan-4-complete-the-plan` | Merged: lean output (≤500 lines), 2 research subagents, domain manifest, AND seven inline fail-fast gates (Clarify / Constitution / Architecture / ADR / Structure / Testing Alignment / Domain Completeness). Emits with `Status: READY` or `Status: DRAFT — UNRESOLVED GAPS` + inline `⚠️ GAP:` markers. Replaces both v2 skills. |
| `plan-3a-v2-adr` | `plan-3a-adr` | Domain impact analysis, domain map integration, domain.md backlinks |
| `plan-5-v2-phase-tasks-and-brief` | `plan-5-phase-tasks-and-brief` | 7-column task table with Domain column, simplified prior-phase review |
| `plan-6-v2-implement-phase` | `plan-6-implement-phase` | Domain placement rules, post-implementation domain.md updates |
| `plan-6-v2-implement-phase-companion` | *(new — sibling of plan-6-v2)* | Same as plan-6-v2 + parallel `code-review-companion` (Power-On-Mode via `minih`). Companion reviews each commit live; **supersedes `/plan-7-v2-code-review`** for projects with a companion agent. |
| `plan-6a-v2-update-progress` | `plan-6a-update-progress` | Domain context in progress tracking |
| `plan-7-v2-code-review` | `plan-7-code-review` | Domain Compliance Validator, anti-reinvention checks |
| `plan-2c-v2-workshop` | `plan-2c-workshop` | Domain context in workshop design documents |
| `/eng-harness-flow --event post-spec` (alias `/plan-2d`) | *(external — the post-spec harness seam)* | The recommended step after the spec, before `plan-3`. The external eng-harness router (`AI-Substrate/harness-engineering`) surveys deterministic-backpressure coverage of the planned work and writes `backpressure-coverage.md`, consumed by `plan-3-v3-architect`. Advisory only — never blocks, no thresholds. Computational counterpart to `plan-7-v2-code-review`. Router not installed → one calm warning, then standard testing (plan-029 switchover). |
| `didyouknow-v2` | `didyouknow` | Domain boundary/contract insights when relevant |
| `plan-2b-v2-prep-issue` | `plan-2b-prep-issue` | Domain metadata, labels, cross-domain dependency warnings in issues |

## Commands That Don't Need V2

These work unchanged with domain-aware projects:

`plan-0-constitution`, `plan-5c-requirements-flow`, `plan-6b-worked-example`, `plan-8-merge`, `code-concept-search`, `deepresearch`, `flowspace-research`, `util-0-handover`

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
