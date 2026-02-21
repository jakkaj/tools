# Lite Agent Command Pipeline Extraction

📚 This specification incorporates findings from research-dossier.md

## Research Context

- **Components affected**: 10 command files (plan-1a, 1b, 3, 5, 5b, 6, 7, didyouknow, 2c-workshop, deepresearch) + 2 documentation files
- **Critical dependencies**: FlowSpace MCP (283 refs), PlanPak (30+ refs), plan-6a mandatory auto-run, /flowspace-research subagent invocations, constitution gates, plan-ordinal tool
- **Modification risks**: 3 commands (plan-3, plan-6, plan-7) require major section rewrites; remaining 7 need minor-to-moderate edits
- **Link**: See `research-dossier.md` for full analysis (7 subagents, ~576 non-pure references cataloged)

## Summary

Extract a clean, self-contained "lite" version of the agent command pipeline into `agents/commands/lite/`. The lite set contains 10 commands that deliver the core planning-to-review workflow without requiring FlowSpace MCP, PlanPak, plan-ordinal, or any of the 14 excluded commands. The full pipeline remains completely untouched — this is a parallel extraction, not an overwrite.

**Who it's for**: Users who want a streamlined plan→implement→review workflow using only standard tools (grep, glob, view, bash) with no specialized infrastructure.

## Goals

- **G1**: Create 10 extracted command files in `agents/commands/lite/` that form a complete, self-contained planning pipeline
- **G2**: Remove all FlowSpace MCP references — no flowspace.tree(), flowspace.search(), /flowspace-research, fs2 install instructions, or FlowSpace node ID management
- **G3**: Remove all PlanPak conditional branches — lite always uses Legacy file placement (standard project directories)
- **G4**: Remove all references to the 14 excluded commands — no dangling next-step suggestions, no gates pointing to missing commands, no subagent invocations of excluded commands
- **G5**: Resolve the plan-6 → plan-6a mandatory dependency by inlining simplified progress tracking directly into plan-6
- **G6**: Replace plan-3's /flowspace-research subagent prompts with grep/glob/view equivalents
- **G7**: Ensure the lite command chain is self-referencing: each command's "Next step" section only points to commands that exist in the lite set
- **G8**: Create lite-specific `README.md` and `GETTING-STARTED.md` with simplified Mermaid diagrams, 10-command reference, and example walkthrough
- **G9**: Inline a simplified CS rubric (Complexity Score 1-5) in commands that reference it, removing the dependency on plan-0-constitution's `constitution.md`
- **G10**: Absorb essential plan-2-clarify functionality (testing strategy, mode selection) into plan-3-architect's entry gate — lite defaults to Simple Mode

## Non-Goals

- **NG1**: Modifying ANY existing file in `agents/commands/` — the full pipeline is untouched
- **NG2**: Creating a "third mode" — lite IS Simple Mode, hardcoded
- **NG3**: Supporting PlanPak in lite — always Legacy file placement
- **NG4**: Supporting FlowSpace in lite — always standard tools (grep/glob/view)
- **NG5**: Maintaining feature parity with the full pipeline — lite intentionally drops validation gates (plan-4), atomic 3-location progress tracking (plan-6a), requirements flow tracing (plan-5c), ADR generation (plan-3a), and other enhancement commands
- **NG6**: Backporting lite changes to the full pipeline
- **NG7**: Automated sync between full and lite command sets — they diverge independently
- **NG8**: Supporting Full Mode (multi-phase with `tasks/` subdirectories) in lite commands

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2, I=1, D=0, N=1, F=0, T=1
- **Confidence**: 0.85
- **Assumptions**:
  - The full command files are stable and won't change during extraction
  - Standard Mode subagent prompts in plan-1a-explore are sufficient as the basis for lite versions
  - Simple Mode branches in plan-3/5/6/7 are complete and functional without Full Mode context
  - TAD concepts embedded in plan-6/plan-7 can be simplified to "Lightweight/Standard" testing without breaking review logic
- **Dependencies**:
  - Research dossier complete (✅ done — 7 subagents, 576 findings)
  - Stable understanding of which concepts are "non-pure" (✅ cataloged)
- **Risks**:
  - Plan-3 subagent rewrite (1446→~800 lines) is the largest single editing task — risk of accidentally removing needed logic
  - Plan-7 validator strip (1614→~1100 lines) has deep conditional branches — risk of broken review rubric
  - Plan-6 progress tracking rewrite changes the completion contract — downstream plan-7 expectations must be verified
- **Phases**: 
  1. Extract & clean the 7 "easy" commands (deepresearch, didyouknow, plan-1b, plan-2c, plan-5b, plan-1a, plan-5)
  2. Rewrite the 3 "hard" commands (plan-3, plan-6, plan-7)
  3. Create lite documentation (README.md, GETTING-STARTED.md)
  4. Verify self-containment (no dangling references to full pipeline)

## Acceptance Criteria

1. **AC1**: `agents/commands/lite/` directory contains exactly 12 files: 10 command `.md` files + `README.md` + `GETTING-STARTED.md`
2. **AC2**: Zero files in `agents/commands/` (the full pipeline) are modified
3. **AC3**: Grep for `flowspace|FlowSpace|fs2|flow_squared|flowspace-tree|flowspace-search|flowspace-get_node|flowspace-research` across all `agents/commands/lite/*.md` files returns zero matches
4. **AC4**: Grep for `planpak|plan-pack|PlanPak|features/<` across all lite files returns zero matches
5. **AC5**: Grep for `plan-ordinal|jk-po` across all lite files returns zero matches
6. **AC6**: Grep for `/plan-0-constitution|/plan-2-clarify|/plan-2b-prep-issue|/plan-3a-adr|/plan-4-complete-the-plan|/plan-5c-requirements-flow|/plan-6a-update-progress|/plan-6b-worked-example|/plan-8-merge|/planpak|/tad|/util-0-handover|/code-concept-search|/flowspace-research` across all lite files returns zero matches (no references to excluded commands as invocable `/command` targets)
7. **AC7**: Each lite command's "Next step" section references only commands present in the lite set
8. **AC8**: `plan-6-implement-phase.md` in lite has no reference to plan-6a and includes inline progress tracking (task status update + execution log append, no footnotes)
9. **AC9**: `plan-3-architect.md` in lite uses grep/glob/view for research subagents (no /flowspace-research invocations)
10. **AC10**: `plan-3-architect.md` in lite skips directly to plan-5 as next step (no plan-4 gate)
11. **AC11**: Lite `README.md` contains a Mermaid flow diagram with only the 10 included commands
12. **AC12**: Lite `GETTING-STARTED.md` contains a quick-start walkthrough using only lite commands
13. **AC13**: Each lite command file has a valid YAML frontmatter `description` field
14. **AC14**: The lite pipeline folder structure uses only Simple Mode layout: `docs/plans/<ord>-<slug>/` with spec, plan, execution.log.md, and reviews/ as siblings (no `tasks/` subdirectory)
15. **AC15**: Grep for `footnote|Footnote|\[\^|Change Footnotes Ledger` across all lite files returns zero matches — no footnote system in lite

## Risks & Assumptions

### Risks
- **R1**: Plan-3 subagent rewrite may lose research quality — mitigate by modeling lite subagents on plan-1a's existing Standard Mode subagent pattern
- **R2**: Plan-7 review rubric may become incomplete after stripping PlanPak/TAD validators — mitigate by preserving core logic (diff analysis, test coverage, architecture alignment) and only removing tool-specific validators
- **R3**: Plan-6 inline progress tracking may not satisfy plan-7's expectations for task table format — mitigate by verifying plan-7 lite reads the same plan format plan-6 lite writes
- **R4**: Maintenance divergence — lite and full will drift apart over time. Accept this as intentional; the lite set is stable and simpler

### Assumptions
- **A1**: Users of the lite pipeline have standard CLI tools (grep, glob, view, bash) available
- **A2**: Users do NOT have FlowSpace MCP, plan-ordinal, or other specialized tooling
- **A3**: The lite pipeline targets CS-1 to CS-3 complexity features (CS-4+ should use the full pipeline)
- **A4**: Simple Mode file layout is sufficient for all lite use cases
- **A5**: The CS rubric can be meaningfully inlined in ~10 lines without the full constitution document

## Open Questions

- **OQ1**: Should lite commands use the same filenames as full commands (e.g., `plan-3-architect.md`) or have distinct names (e.g., `lite-3-architect.md`)? Same names keeps `/plan-3` slash-command compatibility but risks confusion.
- **OQ2**: Should the `agents.sh` installer support deploying lite commands to a separate path (e.g., `~/.claude/commands/lite/`)? Or should they be installable as a standalone pack?
- **OQ3**: Should lite `plan-3-architect` ask 2-3 inline clarification questions (testing approach, mock policy) to replace plan-2-clarify, or should it use sensible defaults and skip?

## ADR Seeds (Optional)

- **Decision Drivers**: Need for infrastructure-free command set; full pipeline complexity deters new users; specialized tooling (FlowSpace) not available in all environments
- **Candidate Alternatives**:
  - A: Extraction to `agents/commands/lite/` (parallel set) — chosen approach
  - B: `--lite` flag on existing commands (conditional branches) — rejected: adds complexity to already-complex commands
  - C: Separate repository for lite commands — rejected: too much overhead for 12 files
- **Stakeholders**: Command pipeline users, contributors maintaining the command set

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Plan-6 Inline Progress Tracking | State Machine | The plan-6a delegation handles 3-location atomic updates, footnote management, and bidirectional graph integrity. Inlining this into plan-6 requires a simplified state model. | 1. What's the minimum viable progress tracking for Simple Mode? 2. Does plan-7 lite need footnote ledger data? 3. Can execution.log.md alone serve as the progress record? 4. What format should inline task status updates use? |
| Plan-3 Research Subagent Rewrite | Integration Pattern | Plan-3's 4 parallel subagents deeply invoke /flowspace-research. Rewriting to grep/glob/view changes the research quality model. | 1. What research quality is acceptable for lite? 2. Can we reuse plan-1a's Standard Mode subagent pattern? 3. How many subagents should lite plan-3 use? 4. Should lite subagents do sequential or parallel exploration? |
