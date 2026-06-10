# Flight plan — eng-harness-switchover

> Generated from [`the-flow.json`](./the-flow.json) — never hand-edit this file.
> **Now**: Build done — T001–T014 complete, 12/12 ACs verified; one commit staged for the user · **Next**: Review (`/plan-7`), then user commits + merge (`/plan-8`, typed `PROCEED`)

```mermaid
flowchart TD
    classDef done fill:#C8E6C9,stroke:#2E7D32,color:#000
    classDef wip fill:#FFE0B2,stroke:#EF6C00,color:#000
    classDef blocked fill:#FFCDD2,stroke:#C62828,color:#000
    classDef known fill:#CFD8DC,stroke:#455A64,color:#000
    classDef assumed fill:#FAFAFA,stroke:#9E9E9E,stroke-dasharray:5 5,color:#666
    classDef said fill:#FFF9C4,stroke:#F9A825,color:#000

    SAID1>"🗣 lets plan this updat eproperly as the flow is very imporatnt"]:::said
    SAID2>"🗣 when dne that move in to spec pleae"]:::said
    SAID3>"🗣 observe is a engineering harness concept, not SDD … all at once. once commit … lets be selective on what should not be removed"]:::said
    SAID4>"🗣 uep run it"]:::said
    SAID5>"🗣 we dont use companion mode in this repo just normal mode /6 please."]:::said

    research["Research<br/>/plan-1a · ✅ research-dossier.md"]:::done
    spec["Spec<br/>/plan-1b · ✅ spec + fltplan · Simple"]:::done
    plan["Plan<br/>/plan-3 · ✅ READY · 14 tasks · validated w/ fixes"]:::done
    px["Phase 1: Switchover cascade · one commit<br/>/plan-6 · ✅ T001–T014 · 12/12 ACs · 32→28 skills"]:::done
    review["Review<br/>/plan-7"]:::known
    merge["Merge<br/>/plan-8 · typed PROCEED only"]:::assumed

    SAID1 -.- research
    SAID2 -.- spec
    SAID3 -.- spec
    SAID4 -.- plan
    SAID5 -.- px
    research --> spec --> plan --> px --> review --> merge
```

**Legend**: 🟩 done · 🟧 in progress · 🟥 blocked · 🟦 known (designed future) · ⬜ dashed = assumed (speculative) · 🗣 verbatim user input

*(No harness nodes for this flow: the eng-harness router was absent at flow start — the live no-router fixture whose probe miss became AC7 evidence. The router was installed mid-build at T001, machine-level. Fitting: this plan's subject IS graceful no-harness degradation.)*
