# `the-flow.md` - upstream-harness-improvements

**Plan**: upstream-harness-improvements . **Mode**: Simple
**Rail**: `[the-flow] ◆-◆-◆-[◆]-◆-◇` . **now**: Review approved . **next**: Merge analysis

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

    R[Research]:::done --> S[Spec]:::done --> PL[Plan]:::done --> P1[Phase 1: Upstream runtime-loop wording]:::done --> RV[Review]:::done --> M[Merge]:::wip
    S -.->|prove it skipped| BP[Backpressure survey]:::assumed
    BP -.-> PL

    UR>"🗣 let's get a plan going in the other repo to take our improveent here and ensure they are availvle upstrea in tools reapo, then we will have all our work there in the tools repo except harness setup which stays here"]:::said
    UR -.- R
```

**Legend**: done . in progress . blocked . known future . assumed future . user input . companion . worker

_Generated from `the-flow.json`._
