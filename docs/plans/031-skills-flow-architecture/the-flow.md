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
    build["Build · Phase 1 (A→B→C→D, 17 tasks)<br/>/the-flow 6 implement --plan …<br/>✅ 17/17 tasks · 14/14 ACs · L1 163→0 · lint exit 0 · deployed"]:::done
    review["Review<br/>/the-flow 7 review --plan …<br/>✅ REQUEST_CHANGES → 5 fixes applied + verified · re-review waived"]:::done
    merge["Merge (administrative close)<br/>✅ no merge stage — main-only repo · committed b07ad7d + pushed"]:::done

    u_research>"🗣 new plan, start wiht explore. bring hta tworkshop across"]:::said
    u_ws1>"🗣 run a /workshop on this please"]:::said
    u_spec>"🗣 continue on with spec or what ever was next then validate"]:::said
    u_plan>"🗣 yes · i think we should call the things we have in the wf a sub-skill"]:::said
    u_build>"🗣 make sure we have commited our working changes first hten implement please · please stop at a natural seam for a compaction"]:::said
    u_merge>"🗣 commit and push please · close our the flow"]:::said

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
    u_build -.- build
    u_merge -.- merge
```

**Legend**: 🟩 done · 🟧 in progress · 🟥 blocked · 🟦 known (designed) · ⬜ dashed = assumed (speculative) · 🗣 verbatim user input · 🟪 harness loop (omitted — repo not provisioned)

- **Now**: **Flow closed.** Review fixes applied + verified (re-review waived by user); all plan-031 work committed directly to `main` as `b07ad7d` (36 files, +5510/−1890) and pushed.
- Review verdict was REQUEST_CHANGES — 5 fix tasks (FT-001..FT-005), all applied + verified: lint's next-step family made case-insensitive + plural (true L1 baseline ≈165, two `## Next Steps` leaks fixed), L3 now catches verb-led + id-only view literals, stale 61/stage-numbering prose cleaned ×4, AC7/AC13 reconciled to the four authorized literal classes.
- No merge stage executed: this repo works on **main only** — there was no branch to merge; stage 8's PROCEED gate never applied.
- Mid-architect user decision (spec Clarification #5 / plan D-E): the reusable unit inside a flow is a **sub-skill** — named by a verb, composed by the flow's Registry+Graph.
- Harness: router installed, repo not provisioned — all five seams (session-start, post-spec, pre-implement T000, phase-end T0zz, plan-complete at close-out) noop'd calmly, exactly as the plan expected.
- Build paused once mid-phase for a user-requested `/compact` (after T012) and resumed at T013 — seam logged in `execution.log.md`.
