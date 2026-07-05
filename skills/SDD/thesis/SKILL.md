---
name: thesis
description: >
  Brief pre-work alignment for any stage. Use before planning, coding, editing,
  reviewing, or delegating when the user asks you to understand the thesis,
  vibe, intent, current position, or direction of a request or existing thing.
  Returns 2–4 bold-labelled one-sentence observations and one short synthesis,
  then stops.
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

Emit only the axes that apply (2–4 of them), each as its own paragraph separated
by a blank line, one sentence each, the label in **bold** followed by an em dash:

```text
**Thesis** — <governing idea and promise>

**Now** — <current position or starting truth>

**Toward** — <destination or consumer need>

**Keep** — <character, invariant, tension, or anti-goal>
```

Then a blank line and a blockquote synthesis — one paragraph of at most three
sentences that ties the axes together and shows what "right" should feel like:

```text
> **My read:** <synthesis>
```

Formatting adds air, not words. The blank lines, bold labels, and blockquote
exist to make the *same short read* scannable — never to invite more content.
Hold to 2–4 axis lines and a ≤3-sentence synthesis.

No heading, praise, recap, plan, checklist, critique, or work. Do not repeat the
axes in prose. If ambiguity would materially change the read, ask one question
instead of inventing. The output must stand alone when returned from a subagent.
