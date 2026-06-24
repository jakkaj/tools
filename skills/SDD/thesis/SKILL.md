---
name: thesis
description: >
  Brief pre-work alignment for any stage. Use before planning, coding, editing,
  reviewing, or delegating when the user asks you to understand the thesis,
  vibe, intent, current position, or direction of a request or existing thing.
  Returns 2–4 numbered one-sentence observations and one short synthesis, then
  stops.
---

# Thesis

Understand the work before doing the work. Flow-blind and read-only.

## Modes

`ask <request>` — what the work should become.

`thing <target>` — what the existing thing is and serves.

`fit <target> to <request>` — where it is, where it must go, and what must
survive.

No mode: ask only → `ask`; target only → `thing`; both → `fit`. Never infer
from workflow position alone.

## Method

1. Read the ask or target and only its nearest authoritative context.
2. Derive **Thesis** (purpose/promise), **Now** (position), **Toward** (outcome
   or next consumer), and **Keep** (vibe, invariant, tension, or anti-goal).
3. Mark inference plainly; invent no missing intent.
4. Keep only ideas that should steer more than one later decision.
5. Stop before planning, critique, edits, or execution.

## Output

Use 2–4 non-empty lines, renumbered sequentially, with exactly one sentence per
number:

```text
1. Thesis: <governing idea and promise>
2. Now: <current position or starting truth>
3. Toward: <destination or consumer need>
4. Keep: <character, invariant, tension, or anti-goal>
```

Then one paragraph of at most three sentences beginning `My read:` that
synthesises the list and shows what "right" should feel like.

No heading, praise, recap, plan, checklist, critique, or work. Do not repeat the
list in prose. If ambiguity would materially change the read, ask one question
instead of inventing. The output must stand alone when returned from a
subagent.
