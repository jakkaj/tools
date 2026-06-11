# Skills Pipeline — Domain-Aware Plan Workflow

The active spec-driven-development pipeline ships as **one skill — `the-flow`** (installed via `npx skills add jakkaj/tools -a <cli>` from `/skills/SDD/the-flow/`): a dispatch `SKILL.md` plus lazily-loaded stage modules under `references/stages/`. Invoke it as `/the-flow <id|name> [flags]` — numbers and names are equivalent (`/the-flow 6 …` ≡ `/the-flow implement …`); with no stage argument it acts as a guided coach. A handful of standalone utility skills (constitution, prep-issue, handover, validate, …) accompany it. The pipeline incorporates:

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

The main flow is one skill: `the-flow` dispatches on `<id|name>` and lazily loads the matching stage module from `references/stages/`. Each row below maps a stage (or utility) to the legacy v1 command it replaces.

| Command | Replaces | What's Different |
|---------|----------|-----------------|
| `/the-flow` (dispatch `SKILL.md`) | *(consolidates the former 12 per-stage skills)* | **The whole pipeline in one skill.** With no stage argument it is a guided coach — asks what you want to build, narrates each seam with one artifact insight, surfaces the optional branches (workshop), `/compact` seams, and the harness seams (routed via `/eng-harness-flow`), and tells you the exact next command. With `<id\|name>` it jumps straight to a stage module. Re-entrant via on-disk state (survives `/compact`); can **adopt** an in-flight plan. Never gates; bundles the visual pipeline guide at `references/getting-started.md`. |
| `plan-v2-extract-domain` | *(new)* | Collaboratively identify and formalize existing code as a named domain |
| `/the-flow 1a` (`references/stages/10-explore.md`) | `plan-1a-explore` | Domain & Boundary Scout subagent, domain context in research output |
| `/the-flow 1b` (`references/stages/20-specify.md`) | `plan-1b-specify` + `plan-2-clarify` | Merged: front-loaded batched questions before spec sketch + conditional post-sketch round. Replaces both v2 skills. |
| `/the-flow 1b` § Re-entry | `plan-2-clarify` | Soft-deprecated mid-plan re-entry point (≤4 questions). For new specs use `/the-flow 1b`. |
| `/the-flow 3` (`references/stages/30-architect.md`) | `plan-3-architect` + `plan-4-complete-the-plan` | Merged: lean output (≤500 lines), 2 research subagents, domain manifest, AND seven inline fail-fast gates (Clarify / Constitution / Architecture / ADR / Structure / Testing Alignment / Domain Completeness). Emits with `Status: READY` or `Status: DRAFT — UNRESOLVED GAPS` + inline `⚠️ GAP:` markers. Replaces both v2 skills. |
| `/the-flow 3a` (`references/stages/35-adr.md`) | `plan-3a-adr` | Domain impact analysis, domain map integration, domain.md backlinks |
| `/the-flow 5` (`references/stages/50-phase-tasks.md`) | `plan-5-phase-tasks-and-brief` | 7-column task table with Domain column, simplified prior-phase review |
| `/the-flow 6` (`references/stages/60-implement.md`) | `plan-6-implement-phase` | Domain placement rules, post-implementation domain.md updates |
| `/the-flow 6c` (`references/stages/61-implement-companion.md`) | *(new — sibling of the implement stage)* | Same as `/the-flow 6` + parallel `code-review-companion` (Power-On-Mode via `minih`). Companion reviews each commit live; **supersedes `/the-flow 7`** for projects with a companion agent. |
| `/the-flow 6a` (`references/stages/62-progress.md`) | `plan-6a-update-progress` | Domain context in progress tracking |
| `/the-flow 7` (`references/stages/70-review.md`) | `plan-7-code-review` | Domain Compliance Validator, anti-reinvention checks |
| `/the-flow 8` (`references/stages/80-merge.md`) | `plan-8-merge` | Analyze upstream changes from `main` and generate a merge plan, domain-aware |
| `/the-flow 2c` (`references/stages/25-workshop.md`) | `plan-2c-workshop` | Domain context in workshop design documents |
| `/eng-harness-flow --event post-spec` | *(external — the post-spec harness seam)* | The recommended step after the spec, before the architect stage. The external eng-harness router (`AI-Substrate/harness-engineering`) surveys deterministic-backpressure coverage of the planned work and writes `backpressure-coverage.md`, consumed by the architect stage (`/the-flow 3`). Advisory only — never blocks, no thresholds. Computational counterpart to the review stage (`/the-flow 7`). Router not installed → one calm warning, then standard testing (plan-029 switchover). |
| `didyouknow-v2` | `didyouknow` | Domain boundary/contract insights when relevant |
| `plan-2b-v2-prep-issue` | `plan-2b-prep-issue` | Domain metadata, labels, cross-domain dependency warnings in issues |

## Commands That Don't Need V2

These work unchanged with domain-aware projects:

`plan-0-constitution`, `plan-5c-requirements-flow`, `plan-6b-worked-example`, `code-concept-search`, `deepresearch`, `flowspace-research`, `util-0-handover`

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
