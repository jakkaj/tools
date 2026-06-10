# `the-flow.md` template (flight view)

> **Worked-example template** — copy this shape. It is **generated from [`flight-plan.template.json`](./flight-plan.template.json)** (the source of truth); never hand-edit the rendered `the-flow.md` as the primary. Snapshot: a 6-phase Full plan, Phases 1–2 done, **Phase 3 in progress**. Every workshop is its **own node**; each stage where the user typed shows a **verbatim 🗣 speech bubble**; the `code-review-companion` **wraps** the build phases (subgraph); a `docs-writer` **worker** is a side-node; the **harness seams** appear as first-class violet nodes whose commands are router invocations (`/eng-harness-flow --event …`) — they vanish entirely when the router isn't installed.

**Plan**: project-setup · **Mode**: Full · **Phases**: 6
**Rail**: `[the-flow] ◆─◆─◆─[◆─◆─◇─◇─◇─◇]─◇`   ·   **now**: Phase 3 (Next.js) · **next**: Phase 4 (CLI) · **phase 3/6**
> _The `now · next` segment after the diamonds renders in a distinct accent colour in the live terminal._

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

    %% ── spine (vertical); the post-spec seam (Backpressure Check) sits between Spec and Plan; companion WRAPS the build phases ──
    R[Research]:::done --> S[Spec]:::done --> BP["Backpressure Check · /eng-harness-flow --event post-spec"]:::harness --> PL[Plan]:::done

    subgraph CRC["⊞ code-review-companion · 🟢 live · reviews every commit (minih)"]
        direction TB
        P1[Phase 1 · Monorepo Foundation]:::done --> P2[Phase 2 · Shared Package]:::done
        P2 --> P3[Phase 3 · Next.js + Clean Arch]:::wip --> P4[Phase 4 · CLI Package]:::known
        P4 --> P5[Phase 5 · MCP Server]:::known --> P6[Phase 6 · Docs & Polish]:::known
    end
    style CRC fill:#E0F2F1,stroke:#00897B,stroke-width:2px

    PL --> P1
    P6 --> M[Merge]:::known

    %% ── excursions: deep-research + each workshop as its own node ──
    R -.->|dig deeper| DR[["deep research ×3"]]:::done
    DR -.-> S
    S -.->|design| W1[Workshop 1 · clean-arch boundaries]:::done
    W1 --> W2[Workshop 2 · fake/adapter strategy]:::done
    W2 -.-> BP

    %% ── harness seam nodes (first-class; shown because the router IS installed — omit all when the Layer-1 probe misses) ──
    PL -.->|pre-flight| HB[["pre-implement seam · /eng-harness-flow --event pre-implement"]]:::harness
    HB -.-> P1
    P2 -.->|at seam| HR[["phase-end seam · /eng-harness-flow --event phase-end"]]:::harness
    M -.->|reflection| HH[["plan-complete seam · /eng-harness-flow --event plan-complete"]]:::harness

    %% ── assumed conditional ──
    P3 -.->|if review fails| FX[["fix loop?"]]:::assumed
    FX -.-> P4

    %% ── verbatim user-said bubbles (no detail hidden) ──
    UR>"🗣 set up the monorepo: web app, cli, mcp; clean-arch; TDD-first"]:::said
    UR -.- R
    UDR>"🗣 double-check the cli name + parser online"]:::said
    UDR -.- DR
    US>"🗣 clean-arch with fakes for every adapter; full TDD"]:::said
    US -.- S
    U1>"🗣 where exactly do the layer boundaries sit?"]:::said
    U1 -.- W1
    U2>"🗣 one fake per adapter, or shared fakes?"]:::said
    U2 -.- W2

    %% ── parallel agents (minih): companion WRAPS the phases (subgraph above); workers build a phase ──
    DOCW[["docs-writer<br/>worker · queued (minih)"]]:::worker
    DOCW -. builds .-> P6
```

**Legend**: 🟩 done · 🟧 in progress · 🟥 blocked · 🟦 known future (designed) · ⬜╴assumed future (dashed) · 🟨 🗣 verbatim user input · companion (teal, wraps) · worker (indigo, side) · 🟪 harness seams (violet — routed via `/eng-harness-flow`)

_Generated from `the-flow.json`. Each spine/excursion node links its artifacts and carries a note (what & why); nodes the user spoke at hang a yellow bubble with their **exact words**. Workshops are shown individually (W1, W2) — never collapsed. The **harness seams are first-class**, and every one routes through the single external entry point `/eng-harness-flow` (child skills are private and never named): the post-spec seam (Backpressure Check) sits on the spine between Spec and Plan; pre-implement pre-flights each phase; phase-end fires at seams; plan-complete fires at merge. **All harness nodes are omitted entirely when the router isn't installed** (probe `~/.agents/skills/eng-harness-flow/SKILL.md`, fallback `~/.claude/skills/`) — a repo without a harness simply shows the spine + workshops. Before `/plan-3`, P4–P6 + Merge were `assumed`; locking the plan flipped them `known`. If Phase 3's review fails, `fix loop?` flips `assumed → in_progress`._
