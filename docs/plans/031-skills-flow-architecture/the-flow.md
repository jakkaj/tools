<!-- 🔄 GENERATED from the-flow.json — never hand-edit this file as the primary. -->
# the-flow · skills-flow-architecture — flight plan

```mermaid
flowchart TD
    classDef done fill:#E8F5E9,stroke:#2E7D32,color:#1B5E20
    classDef wip fill:#FFF3E0,stroke:#EF6C00,color:#E65100
    classDef blocked fill:#FFEBEE,stroke:#C62828,color:#B71C1C
    classDef known fill:#E3F2FD,stroke:#1565C0,color:#0D47A1
    classDef assumed fill:#FAFAFA,stroke:#9E9E9E,color:#616161,stroke-dasharray: 5 5
    classDef said fill:#F3E5F5,stroke:#7B1FA2,color:#4A148C
    classDef harness fill:#EDE7F6,stroke:#673AB7,color:#311B92

    research["Research<br/>/the-flow 1a explore<br/>✅ dossier: leak=147 verified"]:::done
    ws1["Workshop 1 · composable skill flows<br/>✅ D1–D7 · R1–R8 · L1–L6 (authoritative)"]:::done
    spec["Spec<br/>/the-flow 1b specify<br/>✅ Simple · CS-3 · 14 ACs · sub-skill named · validated"]:::done
    plan["Plan<br/>/the-flow 3 architect<br/>✅ READY v1.1.0 · 16 tasks · D-A..D-F · validated"]:::done
    build["Build · Phase 1 (A→B→C→D, 16 tasks)<br/>/the-flow 6 implement --plan …"]:::known
    review["Review<br/>/the-flow 7 review"]:::assumed
    merge["Merge<br/>/the-flow 8 merge"]:::assumed

    u_research>"🗣 new plan, start wiht explore. bring hta tworkshop across"]:::said
    u_ws1>"🗣 run a /workshop on this please"]:::said
    u_spec>"🗣 continue on with spec or what ever was next then validate"]:::said
    u_plan>"🗣 yes · i think we should call the things we have in the wf a sub-skill"]:::said

    research --> spec
    research -.-> ws1
    ws1 -.-> spec
    spec --> plan
    plan --> build
    build --> review
    review --> merge

    u_research -.- research
    u_ws1 -.- ws1
    u_spec -.- spec
    u_plan -.- plan
```

**Legend**: 🟩 done · 🟧 in progress · 🟥 blocked · 🟦 known (designed) · ⬜ dashed = assumed (speculative) · 🗣 verbatim user input · 🟪 harness loop (omitted — repo not provisioned)

- **Now**: Plan · READY v1.1.0 (`skills-flow-architecture-plan.md` — 16 tasks, 14 ACs, decisions D-A…D-F; validate-v2 applied 2 CRITICAL + 5 HIGH fixes)
- **Next**: Build · `/the-flow 6 implement --plan "docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md"`
- Mid-architect user decision (spec Clarification #5 / plan D-E): the reusable unit inside a flow is a **sub-skill** — named by a verb, composed by the flow's Registry+Graph.
- Harness: router installed, repo not provisioned — seams noop; the plan's T000/T0zz seam rows fire at build (expect calm noop).
