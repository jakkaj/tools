# `harness checks` — agent briefing

The mandated quality gate for this repo (a skills repository + dev-tooling
installer). Run it before you consider work *done*, and before commit/push.

## What this verb computes (the deterministic part)

Runs each gate in `GATES` (see `extension.ts`) in order, from the repo root,
failing on the first non-zero exit:

1. **`skill-slugs`** — `scripts/check-skill-slugs.sh`: no two skills under
   `skills/<category>/<slug>/` share a slug (`npx skills` flattens on install,
   so a collision silently overwrites a skill).
2. **`flow-architecture`** — `scripts/check-flow-architecture.sh skills/SDD/the-flow`:
   the-flow satisfies the flow-architecture pattern (Registry/Graph/grammar,
   frontmatter parses, `description` ≤ 1024 chars).
3. **`skill-frontmatter`** — `scripts/check-skill-frontmatter.sh`: every
   `skills/**/SKILL.md` has valid frontmatter — `name` matches its folder slug,
   `description` present and ≤ 1024 chars.

Envelope `data` on success: `{ gates: [{gate, ok, code}], passed }`. On the
first failure: an `error` envelope (exit 1) with the gate name, the failing
command, the tail of its output in `details`, and a `next_action`.

## Your role (the inference part)

If `checks` is green, the deterministic gates passed — but green ≠ complete:
confirm the gate set actually covers what you changed. Adding/editing a **skill**
is covered by the slug, flow, and frontmatter gates. If `checks` is red, read
`next_action` and fix the named gate — never edit a gate to make it pass.

## Watch out for

- The gate list is intentionally **basic** — it does not yet run `just test`,
  `just lint`, or a per-skill frontmatter linter. A green run does not prove
  those.
- Gates run via `bash <script>` from the repo root; they need their scripts
  present and the working tree intact.
- Add a gate by appending one `Gate` entry in `extension.ts` — do not fork this
  verb.
