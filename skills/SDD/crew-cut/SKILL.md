---
name: crew-cut
description: >
  Terse second pass for any artifact, at any workflow stage. Use `review` to
  check code, plans, docs, reviews, or other work and return only material
  corrections. Use `prime` to turn prior work into the few instructions the
  next agent must obey. Works inline or in a subagent. Never infer the mode
  from workflow position alone.
---

# Crew Cut

Flow-blind and read-only. Review named work or prime the next agent. Do not
edit, route, or continue the workflow.

## Modes

`review <target> [against <ask/context>]`

Judge the target. Tags: `fix` wrong · `add` missing · `cut` extra · `decide`
unresolved · `prove` unsupported.

`prime <source> for <next task>`

Treat the source as context, not a review target. Extract only what the next
agent must do, preserve, resolve, and prove. Surface source defects only when
they block or endanger the task.

If mode is omitted, infer it only from explicit verbs. If ambiguous, ask:
`Review it, or prime the next task?`

## Method

1. Read the target or source, the user's ask, and directly referenced evidence.
   Expand only when needed.
2. Preserve explicit intent, accepted decisions, repo rules, correctness, and
   safety. Invent no requirements or preferences.
3. Merge duplicates. Keep only points that change the next action.
4. Write imperatives to the agent doing the work. Cite a location or evidence
   when available.
5. Stop. No praise, recap, score, edits, or execution.

## Output

### review

Highest impact first; one line each:

`<location> — <tag>: <imperative>. <evidence or consequence>.`

No material change: `Ready.`

### prime

Use only non-empty lines:

`DO: <next action>`
`KEEP: <constraints and decisions>`
`ASK: <unresolved blocker>`
`CHECK: <observable proof>`

The result must stand alone when returned from a subagent. Brevity never hides
a correctness, safety, data-loss, or irreversible-action risk.
