# Workshop: New Repo Extraction (harness-nucleus Standalone Repo)

**Type**: Storage Design / Integration Pattern
**Plan**: 024-harness-nucleus
**Spec**: [../harness-nucleus-spec.md](../harness-nucleus-spec.md)
**Created**: 2026-05-28
**Status**: Draft

**Value Thesis**: This workshop makes the eventual plan-025+ extraction safer and cheaper by mapping the contract surface between the tools-repo SDD pipeline and the standalone harness skills BEFORE any code moves — so the cross-repo coordination (slug collisions, orphan prune, minih back-compat, deletion-PR sequencing) is a known decision space rather than a discovered hazard mid-flight.
**Target Proof Level**: Preferred Direction
**Current Proof Level**: Decision Space

**Selected Value Axes**:
- **Cross-Domain Coordination**: The whole topic is two repos publishing skills into one shared on-disk store (`~/.agents/skills/`). The contract between them — what the SDD pipeline names and what the new repo provides — is the load-bearing artifact.
- **Migration Safety**: Skills must move without breaking the 8 SDD consumers that invoke `harness-2-observe` / `harness-3-retro` by name. Sequencing + back-compat are the risk.
- **Learning Compounding**: Records the rejected boundaries (everything-moves vs schemas-only) and the npm-extraction trigger so the next loop does not re-litigate them.
- **Safety to Change**: Identifies which contracts are frozen (schema `$id`, `.retro.md` path, `docs/compound/` root) so the extraction cannot silently break minih or the SDD pipeline.

**Related Documents**:
- [002-cli-extension-architecture.md](./002-cli-extension-architecture.md) — the new repo's CLI surface + extension boundary (DEFERRED here; cross-referenced for the CLI verb / entry-point questions)
- [003-harness-backpressure-eval.md](./003-harness-backpressure-eval.md) — the net-new backpressure skill (DEFERRED here; affects whether a 4th skill ships in the new repo)
- [004-harness-compound-domains.md](./004-harness-compound-domains.md) — formalizing harness + compound as registered domains (DEFERRED here; the domain registry is the formal home for the contract surface this workshop sketches informally)
- Spec § Workshop Opportunities row "New repo extraction"
- [../research-dossier.md](../research-dossier.md) § Domain Context (DB-04/05/06/07), § Cross-System Dependencies, PL-04

**Domain Context** (no `docs/domains/registry.md` exists yet — domains are proposed-but-unregistered per spec § Target Domains):
- **Primary Domain**: harness (the loop family — the thing being extracted)
- **Related Domains**: compound (the `schemas/` substrate — extraction-timing decision lives here), sdd-pipeline (the 8 consumers that stay in tools-repo), dev-tooling (`src/jk_tools/` mirror, `npx skills` install path)

---

## Purpose

Explore what STAYS in `jakkaj/tools` versus what MOVES to a future standalone `harness-nucleus` repo, recommend an extraction boundary, and pin down the two open contract questions: (a) the name-based contract surface between the tools-repo SDD skills and the new repo's harness skills, and (b) the trigger condition for extracting `skills/compound/schemas/` into an `@ai-substrate/retro-schema` npm package. This is exploratory seeding for the plan-025+ extraction track — NOT an implementation spec.

## Fresh Entrant Outcome

A fresh human or agent should be able to use this workshop to reach **Preferred Direction** with no additional context.

They should be able to:

- State which artifacts stay in tools-repo and which move to `harness-nucleus`, and why (the contract surface is name-based, not code-based — compound+harness have zero dependencies on SDD; SDD has soft name-references back).
- Explain how two `npx skills add` sources co-install into one `~/.agents/skills/` canonical store without slug collision, and what orphan-prune step the cross-repo rename requires (PL-04).
- Sequence a safe migration: when to publish the new repo, when to land the deletion PR in tools-repo, and how to keep the 8 SDD consumers working mid-flight.
- Pick the recommended extraction boundary from a Decision Space table and name the rejected alternatives + open questions.
- State the concrete trigger that flips `skills/compound/schemas/` from in-repo (the frozen v1 home with minih) to an `@ai-substrate/retro-schema` npm package.

## Key Questions Addressed

- **KQ1**: What is the contract surface between tools-repo SDD skills and the new repo's harness skills? (Frozen as name-based per dossier DB-04/05.)
- **KQ2**: When does `skills/compound/schemas/` extract to an `@ai-substrate/retro-schema` npm package? (Trigger condition, not a date.)
- **KQ3**: If the 8 SDD consumers live in `jakkaj/tools` but the harness skills live in `harness-nucleus`, how do they co-install — and what is the slug-collision + orphan-prune risk per PL-04?
- **KQ4**: How is the move sequenced (publish / deletion-PR / verify) so no SDD consumer breaks mid-flight?
- **KQ5**: How does `harness-nucleus` version relative to `jakkaj/tools`?

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | Preferred Direction | Plan-025+ needs a recommended boundary + rejected alternatives, not a buildable spec. Locking the boundary now stops the extraction track re-opening "everything vs schemas-only" later. |
| Primary Value Axis | Cross-Domain Coordination | The extraction is fundamentally a two-repo / one-store coordination problem; the contract surface is the deliverable. |
| Supporting Value Axes | Migration Safety, Learning Compounding, Safety to Change | Sequencing prevents mid-flight breakage; recording rejected options prevents re-litigation; freeze-awareness prevents silent minih/SDD breakage. |
| Downstream Loop Improved | Migration (plan-025+ extraction track) + Agent execution | A plan-025 architect can phase the extraction from this boundary; an implementer can run the deletion-PR sequence without rediscovering the orphan trap. |

## Glossary (Orientation)

| Term | Meaning |
|------|---------|
| **tools-repo** | `jakkaj/tools` — current home of all skills (SDD pipeline + the 3 harness skills + `compound/schemas/`). |
| **harness-nucleus** | The proposed standalone repo that would host the harness loop skills + (eventually) a CLI + extension architecture. |
| **canonical store** | `~/.agents/skills/<slug>/` — real directories written by `npx skills add`; the single on-disk source of truth (per CLAUDE.md § Skills deployment architecture). |
| **symlinked view** | `~/.claude/skills/<slug>` / `~/.pi/skills/<slug>` — symlinks back to the canonical store. |
| **orphan trap (PL-04)** | `npx skills` does not auto-prune; a renamed/moved slug leaves a stale real dir at the old path → duplicate skill discovery with divergent content. |
| **contract surface** | The name-based + path-based promises the two repos make to each other (skill slugs, buffer path, `.retro.md` layout, schema `$id`, governance-doc filename). |
| **frozen contract** | A promise that must NOT break during extraction (spec § Non-Goals + dossier § Cross-System Dependencies). |

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| Contract surface is name-based (4 elements) | § The Contract Surface (KQ1) | KQ1 boundary decision | Ready |
| compound+harness have zero deps on SDD; SDD has soft name-refs back | dossier DB-04/05 | "clean extraction" claim | Ready |
| Two-source co-install into one canonical store | § Co-Install Model (KQ3) + CLAUDE.md § Skills deployment architecture | KQ3 slug-collision analysis | Draft (needs `npx skills` two-source smoke) |
| Orphan trap on cross-repo rename | dossier PL-04, CLAUDE.md "Known orphan path" | KQ3 prune step | Ready |
| Frozen contracts list | spec § Non-Goals, dossier § Cross-System Dependencies | what cannot move/break | Ready |
| Deletion-PR coordination requirement | dossier DB-07 | KQ4 sequencing | Ready |
| Proposed `harness-nucleus` file tree | § Proposed Repo Structure | extraction boundary | Draft (illustrative) |
| npm-extraction trigger condition | § Schema Extraction Trigger (KQ2) | KQ2 | Preferred Direction |
| Extraction boundary options | § Decision Space | recommendation | Preferred Direction |

---

## The Contract Surface (KQ1)

The dossier's central finding (DB-04/05): **compound + harness have zero dependencies on SDD; SDD has soft name-references back.** This means the contract is not code — there is no import to break. The contract is a small set of **names and paths** that both repos must agree on. Extraction requires schematizing these, not re-architecting code.

Sequence at runtime today (all communication is file-based, never skill-to-skill calls — dossier DE-03 F2):

```
SDD skill (tools-repo)                  harness skill (would-be new repo)
        |                                          |
        |  invokes BY NAME: "harness-2-observe"    |
        |----------------------------------------->|  (host resolves slug in ~/.agents/skills/)
        |                                          |
        |                                          |  appends to docs/compound/_buffers/<agent>.session-buffer.md
        |                                          |
        |  invokes BY NAME: "harness-3-retro       |
        |    --drain" / "--harvest"                |
        |----------------------------------------->|  reads buffer, writes docs/compound/agents/<agent>/<date>/*.retro.md
        |                                          |          conforming to retro.schema.json ($id)
        v                                          v
   reads back docs/project-rules/engineering-harness.md  (§ Known Difficulties, seeded from the ledger)
```

The four contract elements (dossier DB-05; all FROZEN per spec § Non-Goals):

| # | Contract element | Concrete value | Who depends | Freeze classification |
|---|------------------|----------------|-------------|----------------------|
| C1 | **Skill slugs** | `harness-1-boot`, `harness-2-observe`, `harness-3-retro` | 8 SDD `## Compound integration` appendices invoke by name | Name-stability contract — public API of new repo |
| C2 | **Buffer path** | `docs/compound/_buffers/<agent>.session-buffer.md` | observe writes, retro `--drain` reads | Path frozen (IC-03 internal but cross-repo now) |
| C3 | **Retro schema + layout** | `retro.schema.json` (`$id`), `.retro.md` at `docs/compound/agents/<agent>/<date>/` | minih, future npm pkg, all retro consumers | Frozen (IC-01/IC-02, cross-system with minih) |
| C4 | **Governance doc filename** | `docs/project-rules/engineering-harness.md` (3-deep fallback) | 8 SDD readers + harness-1-boot | Frozen (IC-07) |

**Why this matters for the boundary**: because the contract is name+path based, the *skill bodies* can live in either repo with no functional difference — the host resolves the slug from the shared canonical store regardless of which repo published it. The decision is therefore about **publishing ownership and coordination cost**, not about breaking code.

## Co-Install Model (KQ3) — Two Sources, One Canonical Store

`npx skills add` writes real directories into `~/.agents/skills/<slug>/` and symlinks per-CLI views (`~/.claude/skills/`, `~/.pi/skills/`) back to it (CLAUDE.md § Skills deployment architecture). After extraction, two `add` invocations target the same store:

```
$ npx skills add jakkaj/tools          # publishes the 8 SDD skills (plan-*)
$ npx skills add jakkaj/harness-nucleus  # publishes harness-1-boot / -2-observe / -3-retro

                          writes into the SAME store
                                     |
                                     v
~/.agents/skills/
  ├── plan-1a-v2-explore/        <- from jakkaj/tools
  ├── plan-3-v3-architect/       <- from jakkaj/tools
  ├── ...                        <- from jakkaj/tools
  ├── harness-1-boot/            <- from jakkaj/harness-nucleus
  ├── harness-2-observe/         <- from jakkaj/harness-nucleus
  └── harness-3-retro/           <- from jakkaj/harness-nucleus
        |
        +-- symlinked into ~/.claude/skills/, ~/.pi/skills/ (per-CLI views)
```

**Slug-collision risk (DB-07)**: `npx skills` flattens by slug. Collision happens only if the SAME slug is published by BOTH repos. The boundary MUST therefore be slug-disjoint: tools-repo keeps `plan-*` (and `general/`, `personal/`), harness-nucleus owns `harness-*`. As long as the deletion PR in tools-repo removes the `harness-*` slugs in the same window the new repo starts publishing them, there is exactly one publisher per slug and no collision.

**Orphan trap (PL-04)**: the move is a cross-repo rename of the publishing source. `npx skills` does NOT auto-prune. After the new repo takes over `harness-*`, a re-run of `npx skills add jakkaj/tools` will simply stop writing `harness-*` — but it will NOT remove the previously-written `~/.agents/skills/harness-*/` real dirs. They become orphans that drift from the new repo's versions. Required prune (mirrors the existing `~/.copilot/skills` orphan fix in CLAUDE.md):

```bash
# After harness-nucleus becomes the publisher of harness-*:
rm -rf ~/.agents/skills/harness-1-boot ~/.agents/skills/harness-2-observe ~/.agents/skills/harness-3-retro
npx skills add jakkaj/harness-nucleus   # re-add from the new authoritative source
just doctor-skills                      # verify no orphans, symlinks valid
```

`just doctor-skills` already validates canonical-store size + symlinks + flags orphan real-dir stores at legacy paths (CLAUDE.md). The extraction track should extend its known-legacy-path list, not invent new tooling (KISS — no new derived state).

## Schema Extraction Trigger (KQ2)

`skills/compound/schemas/` is **frozen in place** for plan-024 (spec § Non-Goals: "v1-home commitment with minih until npm-package extraction"). The question is the TRIGGER, not a date. The schema is currently consumed by: the 3 harness skills (write/validate `.retro.md`), minih (pending RFC), and a future `@ai-substrate/retro-schema` npm package.

**Recommended trigger (Preferred Direction)** — extract to npm only when BOTH conditions hold:

1. **A third independent consumer needs it at install-time.** Today the only consumers are this repo's skills + minih (which reads the file format, not the package). Two repos can share a schema by copying a frozen file or by one referencing the other's raw `$id` URL. A *third* system (or minih formally adopting the universal contract via its pending RFC — dossier IC-04) that wants programmatic `import { retroSchema }` rather than file-read is the signal that a published package earns its keep.
2. **The `$id` is stable enough to semver.** The schema `$id` is the real contract (C3). Extraction to npm makes the `$id` a versioned package surface. Do not extract while the schema is still churning — a 4th-rename-saga-style churn (CF-05) on the schema would thrash dependents.

Until both hold, the cheaper path is: **harness-nucleus references the schema by its frozen `$id` / vendors a copy under its own `schemas/`, and tools-repo keeps the authoritative copy** (or vice versa once the harness skills move — see Decision Space). No npm package, no publish pipeline, no version-skew surface. This is the KISS posture: the npm package is derived distribution, not source-of-truth, so defer it until a real consumer demands it.

```
Trigger NOT met (now):                Trigger met (future):
  schemas/ lives in one repo            @ai-substrate/retro-schema (npm)
  other repo vendors/refs by $id          |
  no publish pipeline                      +-- imported by harness-nucleus
                                           +-- imported by minih (post-RFC)
                                           +-- imported by 3rd consumer
                                           $id versioned via semver
```

## Decision Space — The Extraction Boundary

What moves to `harness-nucleus` vs what stays in `jakkaj/tools`?

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A — Everything moves (skills + schemas)** | `harness-1/2/3` skill bodies AND `skills/compound/schemas/` move to harness-nucleus; tools-repo deletes them and references the schema by `$id`. | Single clean home for the whole loop family; new repo is self-contained; matches the "nucleus" framing. | Forces the npm-package or `$id`-reference decision NOW (KQ2 trigger may not be met); minih back-compat coordination (IC-04) must land in the same window; biggest deletion-PR blast radius. | **Rejected (for first extraction)** — couples the boundary move to the unmet schema-extraction trigger. |
| **B — Schemas-only npm + skills stay** | Extract ONLY `skills/compound/schemas/` to `@ai-substrate/retro-schema`; the 3 harness skills stay in tools-repo. | Smallest move; isolates the cross-system (minih) contract into a versioned package. | Does not deliver the "standalone harness repo" goal at all — the skills (the user-facing product) never leave; inverts the dependency (skills would depend on an external npm pkg for a file format they currently own). | **Rejected** — solves the wrong half; schema is the frozen part, skills are the part wanting a new home. |
| **C — Phased: skills move first, schema stays frozen in tools-repo (referenced by `$id`); npm extraction deferred to its own trigger** | Phase 1: `harness-1/2/3` skill bodies move to harness-nucleus; harness-nucleus references `retro.schema.json` by its frozen `$id` (authoritative copy stays at `jakkaj/tools/skills/compound/schemas/` per the v1-home commitment). Phase 2 (later, trigger-gated): extract schema to `@ai-substrate/retro-schema` when KQ2 conditions hold. | Delivers the standalone repo goal immediately; respects the frozen v1-home commitment (no schema move, no minih coordination this round); decouples the two hard problems; smallest coordination window per phase. | Two repos transiently share a schema by reference (acceptable — it is frozen); requires the deletion PR + orphan prune for the skill slugs only. | **Selected (Recommended)** |

### Recommendation: Option C (phased)

Move the **skills** to `harness-nucleus` first; keep `skills/compound/schemas/` authoritative in `jakkaj/tools` (its frozen v1 home with minih) and have `harness-nucleus` reference it by `$id`. Defer the npm-package extraction (`@ai-substrate/retro-schema`) to a later, trigger-gated phase (KQ2). Rationale:

- It delivers the actual goal (a standalone harness repo) without touching the one genuinely frozen cross-system contract (the schema / minih interop, IC-04/IC-08).
- It decouples the two hardest problems — repo split and schema-package publishing — so neither blocks the other.
- The contract surface is name-based (C1-C4), so the skills move with zero code-dependency breakage; only the publishing source and the deletion-PR sequence change.
- It keeps coordination windows small: Phase 1 coordinates only the `harness-*` slug handoff; Phase 2 coordinates only minih.

**Open within Option C** (carry to plan-025+):
- Should the *authoritative* schema copy eventually live in harness-nucleus rather than tools-repo once the skills are there? (Likely yes at npm-extraction time; the package would publish from wherever the harness skills live.) — defer to KQ2 Phase 2.
- Does the deletion PR also relocate `scripts/compound-value.sh` + the `just compound-value` recipe (which parse `harness-3-retro --harvest --json`)? They consume the harness skill output — candidate to move WITH the skills, or stay as a tools-repo-side consumer. — defer to workshop 002 (CLI/tooling).

## Proposed Repo Structure (`harness-nucleus`)

Illustrative target tree for Option C, Phase 1 (skills moved; schema referenced by `$id`; CLI shape DEFERRED to workshop 002):

```
harness-nucleus/
├── README.md                      # human entry; carries the 5 retired principles (per spec § Phases Step 2)
├── skills/
│   └── harness/
│       ├── harness-1-boot/
│       │   └── SKILL.md           # VALIDATE + STATUS bodies (moved from engineering-harness-v2)
│       ├── harness-2-observe/
│       │   └── SKILL.md           # silent producer (moved from compound-1-track)
│       └── harness-3-retro/
│           └── SKILL.md           # --drain + --harvest (merged compound-2-bubble + compound-3-harvest)
├── schemas/
│   └── REFERENCE.md               # points at retro.schema.json $id (authoritative copy stays in jakkaj/tools until KQ2 Phase 2)
├── docs/
│   └── contract-surface.md        # C1-C4: the name+path promises tools-repo SDD skills rely on
├── cli/                           # DEFERRED -> workshop 002-cli-extension-architecture.md
│   └── (entry points, extension boundary)
└── justfile                       # doctor-skills equivalent; orphan-prune helper

jakkaj/tools/  (after deletion PR)
├── skills/
│   ├── SDD/                       # 8 plan-* consumers STAY; appendices invoke harness-* by name (slug contract C1)
│   ├── general/                   # grill-me STAYS
│   └── personal/                  # shopping-hunter STAYS
│   # NOTE: skills/harness/ deleted here in the same window harness-nucleus starts publishing it
├── skills/compound/
│   └── schemas/                   # AUTHORITATIVE schema copy STAYS (frozen v1 home with minih, IC-08)
├── docs/compound/                 # runtime ledger root STAYS (path frozen, IC-09; written by harness skills at runtime)
└── scripts/compound-value.sh      # consumer of harness-3-retro --json (move-or-stay = open, see Option C)
```

**Why `docs/compound/` stays in tools-repo**: it is the *runtime* ledger root (`.disabled` sentinel, `_buffers/`, `agents/<agent>/<date>/`), not skill source. The skills write there wherever they run; the path is frozen cross-system (IC-09, 9+ consumers + minih). Extracting skill *source* does not move runtime *state* — they are separate concerns.

## Migration & Deletion Sequencing (KQ4)

The hazard: if both repos publish `harness-*` slugs at once → slug collision; if neither does → the 8 SDD consumers invoke a missing slug. The window must be coordinated so there is exactly one publisher at all times.

```mermaid
sequenceDiagram
    participant T as jakkaj/tools (SDD consumers + harness skills)
    participant N as jakkaj/harness-nucleus (new)
    participant S as ~/.agents/skills (canonical store)

    Note over T: Pre-state: tools-repo publishes harness-* AND plan-*
    N->>N: 1. Create repo; copy harness-1/2/3 SKILL.md bodies (git mv history optional)
    N->>N: 2. Add schemas/REFERENCE.md pointing at frozen $id
    N->>N: 3. Add docs/contract-surface.md (C1-C4)
    N->>S: 4. Publish: npx skills add jakkaj/harness-nucleus (smoke install, isolated)
    Note over T,N: BOTH now publish harness-* -> collision window OPEN (do not leave open)
    T->>T: 5. Deletion PR: remove skills/harness/* ; keep schemas/ + docs/compound/
    T->>T: 6. SDD appendices already invoke harness-* by NAME -> unchanged (contract C1 holds)
    Note over T,N: Collision window CLOSED -> exactly one publisher of harness-*
    S->>S: 7. Orphan prune: rm -rf ~/.agents/skills/harness-{1-boot,2-observe,3-retro}
    S->>S: 8. npx skills add jakkaj/harness-nucleus (re-add from authoritative source)
    S->>S: 9. just doctor-skills -> verify no orphans, symlinks valid
```

**Mid-flight safety**: the 8 SDD consumers invoke `harness-*` BY NAME (contract C1). As long as *some* repo publishes the slug, they keep working. The only unsafe instant is between step 5 (tools-repo deletes) and step 8 (new repo re-added) on a machine that has not yet installed the new repo — mitigated because the new repo is published (step 4) BEFORE the deletion PR lands (step 5). Recommendation: **publish-then-delete**, never delete-then-publish.

**Deletion-PR coordination (DB-07)**: the tools-repo deletion PR and the harness-nucleus first release should be reviewed together (linked PRs / same change window). The deletion PR's Done-When: `grep -rl 'skills/harness/' jakkaj/tools` returns empty AND `npx skills add jakkaj/tools` no longer offers the `harness-*` slugs.

## Versioning (KQ5)

| Surface | Versioning approach | Rationale |
|---------|--------------------|-----------|
| `harness-nucleus` repo | Independent semver, its own tags | Decoupled release cadence is the point of extraction; tools-repo SDD pipeline evolves on its own clock. |
| Contract surface (C1-C4) | Name-stability contract documented in `docs/contract-surface.md`; breaking a slug name = major bump + tools-repo coordination | Slugs are the public API; PL-05 (vocabulary fragility) says do NOT churn them — freeze post-plan-024. |
| `retro.schema.json` `$id` | Versioned in place (frozen v1) until npm extraction; then semver via `@ai-substrate/retro-schema` | KQ2 trigger; the `$id` is the real contract, additive `system.<name>.*` blocks are minor (dossier extension point 3). |
| tools-repo ↔ harness-nucleus | No version lockstep; coupled only by C1-C4 names + frozen schema `$id` | Best-effort, file-based integration (DE-03) means no build-time version pin is needed. |

**No version lockstep** between the repos is the KISS win: because integration is name+path+file based (not import based), neither repo needs to pin the other's version. The contract is the names, frozen.

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Migration (plan-025+ extraction) | "Do we move schemas too? When? What breaks?" rediscovered each time | Boundary recommended (Option C); schema deferred to a named trigger (KQ2); 4-element contract surface enumerated |
| Agent execution (deletion PR) | Risk of delete-then-publish breaking consumers; orphan dirs silently drift | Publish-then-delete sequence + explicit `rm -rf` orphan prune + `just doctor-skills` gate |
| Review (cross-repo PR pair) | Reviewer reconstructs which slugs collide and which contracts are frozen | Slug-disjoint boundary + frozen-contract table (C1-C4) checkable directly |
| Cross-domain coordination (minih) | Unclear when minih interop must be touched | Decoupled: Phase 1 touches no schema/minih contract; minih coordination gated to Phase 2 |

## Validation / Acceptance

This workshop reaches its target proof level (Preferred Direction) when:

- A reader can name the recommended extraction boundary (Option C, phased) and state why A and B were rejected.
- The 4-element name-based contract surface (C1-C4) is enumerated with its freeze classification, so a plan-025 architect knows what cannot break.
- The two-source co-install model is explained, including the slug-disjoint requirement and the PL-04 orphan-prune step.
- The publish-then-delete migration sequence is specified well enough that an implementer would not delete-then-publish.
- The npm-extraction trigger (KQ2) is stated as a condition (third install-time consumer + stable `$id`), not a date.
- CLI/extension specifics, the backpressure skill, and the domain registry are explicitly DEFERRED to workshops 002 / 003 / 004 (not designed here).

## Open Questions

### Q1: Authoritative schema copy — does it eventually move to harness-nucleus?

**OPEN** — Option C Phase 1 keeps it in `jakkaj/tools` (frozen v1 home). At KQ2 Phase 2 (npm extraction), the package likely publishes from wherever the harness skills live (harness-nucleus). Decision deferred to the npm-extraction phase.

### Q2: Do `scripts/compound-value.sh` + `just compound-value` move with the skills?

**OPEN** — they consume `harness-3-retro --harvest --json`. Candidate to move to harness-nucleus (co-located with producer) OR stay as a tools-repo-side consumer. Cross-reference workshop 002 (CLI/tooling). Whichever way, the `--json` shape (`harness.maturity` / `harness.verdict` / `harness.boot_ms`) is the contract to preserve (spec AC4).

### Q3: Does `docs/compound/` ever rename to `docs/harness/` in the new repo?

**RESOLVED (defer-to-keep)** — KEEP `docs/compound/` per IC-08/IC-09 cross-system commitment with minih (spec § Non-Goals). A `docs/harness/` rename would require coordinated minih back-compat work and is out of scope for the extraction track unless the npm-extraction phase forces it.

### Q4: Is the new repo `jakkaj/harness-nucleus` or an `@ai-substrate/*` org?

**OPEN** — the schema package name (`@ai-substrate/retro-schema`) implies an `ai-substrate` npm scope. Whether the skills repo shares that org/namespace or stays under `jakkaj/` is a naming decision for plan-025+. Does not affect the contract surface (C1-C4 are slug/path based, repo-name independent).

### Q5: CLI + extension architecture — where designed?

**DEFERRED** — to [002-cli-extension-architecture.md](./002-cli-extension-architecture.md). This workshop only notes the `cli/` slot in the proposed tree; entry-point mechanism (Python vs shell vs in-repo skills) and the `harness <verb>` surface are that workshop's job.
