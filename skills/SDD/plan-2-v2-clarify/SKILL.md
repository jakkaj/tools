---
name: plan-2-v2-clarify
description: |
  Mid-plan clarification re-entry. Opens a new `### Session YYYY-MM-DD` block in an existing spec's `## Clarifications` section and asks up to 4 targeted questions to resolve remaining ambiguities or new ones surfaced after architect/workshop/implementation. Does NOT generate a spec — for NEW specs use plan-1b-v3-specify-and-clarify (which front-loads the initial question batch). Soft-deprecated: most original behaviour now lives in plan-1b-v3.
---
Please deep think / ultrathink as this is a complex task.

# plan-2-v2-clarify (soft-deprecated)

This skill is the **mid-plan re-entry point** for clarifications. The original "create-spec-then-interrogate-spec" two-skill flow has been collapsed into [`plan-1b-v3-specify-and-clarify`](../plan-1b-v3-specify-and-clarify/SKILL.md), which front-loads questions before the spec is sketched.

Use this skill ONLY when:
- A spec already exists (created by plan-1b-v3 or the legacy plan-1b-v2)
- Plan-3 / plan-2c-workshop / plan-6 implementation surfaced new ambiguities
- The user wants to add a clarification round mid-stream without regenerating the spec

For new specs, use `/plan-1b-v3-specify-and-clarify` instead.

```md
User input:

$ARGUMENTS

# Expects: path to an existing spec, or a plan slug.
```

## Tool-capability detection

- **Batched host** (e.g., Claude Code's `AskUserQuestion`): submit the round as ONE batched call (up to 4 questions).
- **Sequential host**: submit one at a time, preserving the cap.

## Flow

1. Resolve `PLAN_DIR` from the spec path provided; set `FEATURE_SPEC = ${PLAN_DIR}/<slug>-spec.md`.
2. Scan the existing spec for unresolved gaps:
   - `[NEEDS CLARIFICATION: …]` markers
   - Missing or thin Testing Strategy / Documentation Strategy / Target Domains
   - Open Questions section entries
   - Domain Review needed (Target Domains contains new/contested entries not yet reviewed)
   - Agent Harness decision missing
3. Choose **up to 4 highest-impact questions** from the gap list. Skip questions already answered in earlier `### Session` blocks.
4. Submit as ONE batched prompt (batched host) or sequentially (fallback). Cap = 4.
5. Append answers to `## Clarifications` → `### Session YYYY-MM-DD` (new block — do not modify earlier sessions).
6. Update affected spec sections immediately (Target Domains, Testing Strategy, Documentation Strategy, ACs, Risks, etc.). Save.
7. Emit a one-line coverage summary: "Resolved N/M open gaps. Remaining: …".

## Question catalogue (draw from these, only if relevant)

See [`plan-1b-v3-specify-and-clarify/SKILL.md`](../plan-1b-v3-specify-and-clarify/SKILL.md) → **Standard Questions** for the full answer tables. Categories:

- **Workflow Mode** — only if Mode is unset (rare for re-entry)
- **Testing Strategy** — only if `## Testing Strategy` is missing
- **Mock Usage** — only if testing exists but mock policy is unset
- **Documentation Strategy** — only if `## Documentation Strategy` is missing
- **Domain Review** — only if Target Domains has unreviewed NEW/contested entries
- **Agent Harness Readiness** — only if harness decision not recorded
- **Topic-specific** — drawn from `[NEEDS CLARIFICATION]` markers (data model, FRs, NFRs, integrations, edge cases, terminology)

## Gates

- Spec file must exist; ERROR if not found
- At least one unresolved gap identified; if none, exit silently with "No clarifications needed."
- Cap of 4 questions per invocation (run again for further rounds)
- No critical `[NEEDS CLARIFICATION]` markers remaining after the session (or surface the survivors in the coverage summary)

## Output

Updated `SPEC_FILE` with a new `### Session YYYY-MM-DD` block and any section updates the answers triggered.
```

Next step: Run **/plan-3-v3-architect** (if architect hasn't run) or re-run the downstream skill that surfaced the ambiguity.
