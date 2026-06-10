# Original ask — eng-harness-switchover
**Captured**: 2026-06-10T07:38:36Z  ·  **By**: /the-flow

> lets plan this updat eproperly as the flow is very imporatnt

**Context — the "update" refers to the switch-over scoped earlier in the same session (verbatim):**

> please read /Users/jordanknight/substrate/harness-engineering/skills. note the eng-harness-loop and expecailly eng-harness-flow. this is main re-entrant skill now that is called every tiem we need to re-call a eng harness skill. instead of calling the harness- skills as seen in our own repo now, we will remove those skills and instead we will have our SDD flow replaced to just call eng-harness-loop at teh righ tplaces and pass in some helpful context to it to help us work. First do the discovery on those other new skills. relearn out own the flow skill skills/SDD/the-flow/SKILL.md and then report in a paragraph or two on what we think we need to do to siwthc over form our own harness skills ot the other skills. this will of course includie updating skills/SDD/the-flow/references/getting-started.md/

> we would also need to detect if the harness skills are availale and the harness is terhe too and if not warn the user that no engineering harness detected, and that we are goign to work without one (no drama, just a good solid warning).

> just ensure you know that we only call the main eng-harness-flow skill, we should never call the others directly, they ight change later or move around.

**Implication (recorded at capture time)**: every harness touchpoint in the SDD skills and the-flow routes through `/eng-harness-flow` (with `--event`/`at=` + context) — never `eng-harness-1-boot`, `-2-backpressure`, `-4-retro`, or the `-0-*` setup skills directly. Those child slugs are private implementation detail owned by the substrate repo. Open question for the spec: does the rule extend to the `npx harness observe` CLI verb (in-flight capture), or is the CLI verb an allowed direct surface since it is not a skill?
