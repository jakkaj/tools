# the-flow · flow-skill-consolidation

**Plan**: flow-skill-consolidation · **Mode**: Simple · **Phases**: 1
**Rail**: `[the-flow] ◆─◆─◆─◆─◆─◆`   ·   **now**: COMPLETE — committed + pushed to main · **next**: — (flow complete)

```mermaid
flowchart TD
    classDef done    fill:#4CAF50,stroke:#388E3C,color:#fff
    classDef wip     fill:#FF9800,stroke:#F57C00,color:#000
    classDef blocked fill:#F44336,stroke:#D32F2F,color:#fff
    classDef known   fill:#90A4AE,stroke:#607D8B,color:#000
    classDef assumed fill:#ECEFF1,stroke:#B0BEC5,color:#90A4AE,stroke-dasharray:4 4
    classDef said    fill:#FFFDE7,stroke:#FBC02D,color:#000
    classDef companion fill:#E0F2F1,stroke:#00897B,color:#000
    classDef worker  fill:#E8EAF6,stroke:#3F51B5,color:#000
    classDef harness fill:#EDE7F6,stroke:#673AB7,color:#000

    %% ── spine (post-spec backpressure seam skipped — no adopted harness; pre-implement/phase-end/plan-complete seams nooped quietly) ──
    S["Spec ✔ · CS-3 Simple · 7 clarifications"]:::done --> PL["Plan ✔ · READY v1.1.0 · 15 tasks · 4-lens validated"]:::done
    PL --> PH["Build ✔ · tag 44ba70f → 11 modules + 83-line dispatch → 12 folders deleted → swept → deployed+tidied → drive verified"]:::done
    PH --> R["Review #1 ✔ · REQUEST_CHANGES — 2 HIGH (61 plan-complete pre-merge · 30 Simple-READY misroute) + 3 MEDIUM"]:::done
    R --> M["Merge ✔ · committed + pushed to main (explicit user instruction)"]:::done

    %% ── fix loop (excursion off review #1, rejoined at merge via waived re-review) ──
    R -.-> FIX["Fix loop ✔ · FT-001..FT-005 applied + redeployed — 61 plan-complete→stage 80 · 30 mode-branched · docs swept · manifest+4 · evidence"]:::done
    FIX -.-> R2["Re-review · WAIVED by user — fix-pass evidence accepted"]:::done
    R2 -.-> M

    %% ── verbatim user-said bubbles ──
    US>"🗣 plan to do it. get a new plan folder up. plan to bcakup our current skills somewhere so we can quickly get back if this sucks ;)"]:::said
    US -.- S
    UP>"🗣 run architect now"]:::said
    UP -.- PL
    UB>"🗣 yes  ·  oh make sure …getting-started.md is updated  ·  oh .vscode is an old folder, that should just be blown away"]:::said
    UB -.- PH
    UR>"🗣 Review completed: REQUEST_CHANGES."]:::said
    UR -.- R
    UF>"🗣 yeah do it run teh fixes  ·  remoe codebase.md"]:::said
    UF -.- FIX
    UM>"🗣 no its finde, commit and push. close it out"]:::said
    UM -.- M
```

**Legend**: 🟩 done · 🟧 in progress · 🟥 blocked · 🟦 known future (designed) · ⬜╴assumed future (dashed) · 🟨 🗣 verbatim user input · 🟪 harness seams (violet — routed via `/eng-harness-flow`)

_Generated from `the-flow.json` — never hand-edit this file as the primary. **Flow complete 2026-06-11**: the consolidated `the-flow` (83-line dispatch + 00-routing/coach + 11 stage modules) shipped — spec → plan → build → review (REQUEST_CHANGES) → fix pass (FT-001..FT-005, redeployed) → re-review waived by user → committed + pushed to main. Rollback anchor remains: git tag `pre-flow-consolidation` @ 44ba70f._
