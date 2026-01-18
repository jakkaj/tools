# Workflow Stage Execution Sample

**Mode**: Simple

## Summary

Create a concrete, testable sample of a workflow stage execution environment that demonstrates how the workflow orchestrator prepares and runs a single stage. This sample will:

1. Provide a **working sample** for the `/1a` (explore/research) stage with real files
2. Enable **manual testing** with a coding agent to validate the stage can produce outputs that feed into subsequent stages

The purpose is to validate the workflow schema design by creating a "pre-generated" folder structure that mimics what the WF system would produce, then manually testing it to ensure a coding agent can operate within this structure and produce expected outputs.

## Goals

- **Create stage entry point**: `prompt/wf.md` that instructs agents how to execute the stage
- **Create testable sample**: A complete `01-explore` stage with real content that can be run manually
- **Validate the schema**: Prove the folder structure from `workflow-schema-simple.md` works in practice
- **Enable iteration**: Quick feedback loop on the stage structure before building automation
- **Document the prompt transformation**: Show how `/plan-1a-explore.md` becomes `prompt/main.md`

## Non-Goals

- **Not building automation**: This phase does not automate folder creation (that's OOS)
- **Not building the orchestrator**: This is a static sample, not a running system
- **Not testing all stages**: Only the `01-explore` stage is in scope
- **Not implementing JSON schema validation**: Manual inspection suffices for now
- **Not defining abstract base classes**: Focus is on the concrete sample, not generalizations

## Complexity

**Score**: CS-2 (small)

**Breakdown**: S=1, I=0, D=0, N=1, F=0, T=0

- **Surface Area (S=1)**: Multiple files across a new directory structure
- **Integration (I=0)**: No external dependencies, self-contained sample
- **Data/State (D=0)**: No schema migrations, static files only
- **Novelty (N=1)**: Some ambiguity in exact prompt transformation approach
- **Non-Functional (F=0)**: Standard file creation, no performance/security concerns
- **Testing/Rollout (T=0)**: Manual testing by running with a coding agent

**Confidence**: 0.85

**Assumptions**:
- The folder structure in `workflow-schema-simple.md` is the correct target schema
- A coding agent can understand and operate within the stage structure
- The `/plan-1a-explore.md` prompt can be refactored without losing functionality

**Dependencies**:
- Existing `workflow-schema-simple.md` document
- Existing `/plan-1a-explore.md` command definition

**Risks**:
- The prompt transformation may lose context that was implicit in the command structure
- The sample may not fully represent edge cases in stage execution

**Phases**:
- Single phase: Create the sample folder structure and files

## Acceptance Criteria

1. **Directory structure exists**: `enhance/sample/sample_1/` contains the full stage hierarchy
2. **wf.md entry point exists**: Each stage has `prompt/wf.md` to instruct the agent
3. **01-explore stage complete**: All folders and sample files present with realistic content
4. **Prompt is functional**: `prompt/main.md` can be given to a coding agent with inputs
5. **Output files templated**: Output files have sample/placeholder content showing expected structure
6. **Manual test possible**: Point agent at `wf.md` with stage path, get reasonable outputs

## Risks & Assumptions

### Risks
- **Prompt transformation fidelity**: The command prompt may rely on implicit context (like the current conversation) that's hard to replicate in a standalone prompt
- **Sample data realism**: If sample inputs are too trivial, the test may not surface real issues

### Assumptions
- The workflow stage model (inputs → prompt → outputs) is sound
- A coding agent can produce structured outputs matching the expected schema
- The folder structure supports both human inspection and programmatic access

## Testing Strategy

- **Approach**: Lightweight / Manual
- **Rationale**: This is an exploratory test area to validate the workflow schema design before committing to automation. Manual verification that folder structure works and a coding agent can execute against it.
- **Focus Areas**: Can a coding agent read `prompt/wf.md`, understand the stage, and produce outputs?
- **Excluded**: No automated tests, no TDD - this is pre-decision validation
- **Mock Usage**: N/A - static file structure, no external dependencies to mock

## Documentation Strategy

- **Location**: None
- **Rationale**: Internal test sample - documentation lives in the spec and the sample files themselves
- **Target Audience**: Developer testing the workflow concept

## Clarifications

### Session 2025-01-18

| Question | Answer | Rationale |
|----------|--------|-----------|
| Workflow Mode | Simple | CS-2 task, single phase, quick validation before hard decisions |
| Testing Strategy | Lightweight/Manual | Initial test area - manual verification only |
| Documentation | None | Internal sample, self-documenting |

## Open Questions (Resolved)

1. ~~**Input discovery**~~: Just `user-description.md` - keep it minimal for first test
2. ~~**Output format**~~: Sample content showing expected structure (not empty placeholders)
3. ~~**Prompt format**~~: Natural language in prompt, JSON examples in stage-config.json
4. ~~**Stage config location**~~: Stage root (already in spec)

## ADR Seeds (Optional)

**Decision Drivers**:
- Need for static testability before building automation
- Separation between stage definition (static) and execution (runtime)
- Clear input/output contracts

**Candidate Alternatives**:
- A: Single sample stage (current approach)
- B: Multiple sample stages showing different patterns
- C: A minimal "hello world" stage instead of full explore

**Stakeholders**: Developer testing the workflow concept

---

## Appendix: Target Folder Structure

Based on `workflow-schema-simple.md`, the sample will create:

```
enhance/
└── sample/
    └── sample_1/
        └── runs/
            └── run-2024-01-18-001/
                ├── wf-run.json            # Run-level metadata (empty initially)
                │
                └── stages/
                    └── 01-explore/
                        ├── stage-config.json    # Stage definition
                        │
                        ├── inputs/
                        │   └── user-description.md    # User-provided feature description
                        │
                        ├── prompt/
                        │   ├── wf.md            # WF entry point - read this first
                        │   └── main.md          # Refactored /plan-1a-explore prompt
                        │
                        └── run/
                            ├── runtime-inputs/
                            │   └── manifest.json      # Log of files actually read
                            ├── output-files/
                            │   └── research-dossier.md    # Primary output document
                            └── output-data/
                                ├── wf-result.json     # Stage execution result
                                └── findings.json      # Structured findings data
```

## Appendix: wf.md Entry Point Prompt

The `prompt/wf.md` file is the entry point for executing the stage. When a coding agent is pointed at this prompt, it:

1. **Understands context**: Knows it's operating within a workflow system
2. **Reads stage-config.json**: Learns what inputs are available and what outputs are expected
3. **Loads main.md**: Reads the stage-specific prompt from `prompt/main.md`
4. **Executes the stage**: Performs the work described in main.md
5. **Writes outputs**: Produces files in `run/output-files/` and data in `run/output-data/`

**Usage**: Point the coding agent at the stage's `prompt/wf.md`:
```
"Read and execute: runs/run-2024-01-18-001/stages/01-explore/prompt/wf.md"
```
