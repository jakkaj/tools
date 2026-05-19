---
name: compound-2-bubble
description: |
  Session-end soft prompt for the compounding-value loop. Reads `docs/compound/_buffers/<agent>.session-buffer.md`; if non-empty, presents a single soft prompt with `[s/t/p/e/d/a]` action menu and one-line encoding hint per entry; routes saved entries into per-run `.retro.md` files under `docs/compound/agents/<agent>/<date>/`. Empty buffer = silent. Default action = `[a]ll-save`. Never asks twice in a session.
---

# compound-2-bubble

The consumer-side surface of the compound loop. The ONE place compound talks to the user.

## When to fire

- **Auto-fired** by pipeline skills at natural logical pauses (plan-1a end, plan-3 end, plan-6 end-of-phase, plan-6-companion end-of-phase, plan-7 end, plan-8 end)
- **Manually fired** by the user (`/compound-2-bubble`) at any time
- **Start-of-skill** check on any auto-firing skill — if the buffer has leftover entries from a prior session (cross-session carryover), bubble immediately

Each firing handles entries accumulated since the last drain. Once drained, the buffer is empty; the next firing on an unchanged buffer is silent.

## Sentinel check

If `docs/compound/.disabled` exists → silently no-op. No prompt, no output.

## Step 1 — Read the buffer

Path: `docs/compound/_buffers/<agent>.session-buffer.md`

Where `<agent>` is the calling CLI's slug (claude-code, codex, github-copilot, opencode, pi, or a companion slug like plan-6-companion).

If the file is missing or empty → silent (no prompt). Exit.

If non-empty → parse it as a sequence of YAML entry blocks (each prefixed with `- id: …`).

## Step 2 — Present the soft prompt

Single prompt at end of session. **Never asks twice.** Format:

```
💡 compound — 3 entries from this session:

  1. [difficulty/tooling] grep on src/ took 47s
     → encode as: justfile recipe wrapping ripgrep

  2. [magic-wand/project] A `just rg <pattern>` recipe would shave 40+s per search
     → encode as: justfile recipe

  3. [gift/compound] compound-0-setup scaffolded cleanly
     → no encoding needed (it's a gift)

[s]ave all to scope file
[t]ask: emit /plan-5 --fix invocations for the encodable ones
[p]lan: emit /plan-1b invocations for the bigger ones
[e]ncode: stage diffs in scratch/encode-<id>-<target>.diff
[d]ismiss all (entries dropped, not saved)
[a]ll-save (default — press Enter)

[s/t/p/e/d/a]: ▮
```

Notes on the prompt:
- One line per entry, prefixed `[kind/target]`
- One-line encoding hint per entry (from `suggested_encoding` or a sensible default)
- Action menu fits in two screen-lines
- Pressing Enter without typing = `[a]ll-save` (the default)

## Step 3 — Route by action

### `[a]ll-save` (default)

Wrap all buffer entries in a single universal retro envelope and write one `.retro.md` file:

```yaml
---
schema_version: "1.0"
retro_id: "<ISO>-<agent>-<short-hash>"
agent: <agent>
plan_id: <plan-id-from-cwd-or-branch-detection-or-null>
started_at: "<ISO of first entry's first_seen_at, or session start>"
ended_at: "<now in ISO UTC>"
summary: "compound-2-bubble session-end save (N entries)"
entries:
  # ... all buffer entries verbatim
system:
  compound:
    bubble_action: "all-save"
---
```

File path via `resolvePath()` (workshop 006 § Path Resolver):

`docs/compound/agents/<slugified-agent>/<YYYY-MM-DD>/T<HH-MM-SS>Z-<hash>.retro.md`

Then **clear the buffer** (truncate to empty; keep the file).

### `[s]ave` (selective save)

Prompt: "Which entries to save? [1,2,3 or a]". Save the selected ones into a `.retro.md` (same envelope as `[a]ll-save`); discard the rest. Clear buffer.

### `[t]ask` — emit copy-pasteable `/plan-5 --fix` invocations

For each encodable entry, print:

```
/plan-5 --fix --description "<entry.description>" --target <entry.target>
```

The user copy-pastes one or more of these. The entries are ALSO saved to a `.retro.md` (so the suggestion is captured even if the user doesn't run all of them). Clear buffer.

### `[p]lan` — emit copy-pasteable `/plan-1b` invocations

For each entry suggesting a larger piece of work, print:

```
/plan-1b "<one-line spec derived from entry.description + entry.suggested_encoding>"
```

User copy-pastes the ones they want. Entries also saved to `.retro.md`. Clear buffer.

### `[e]ncode` — stage diffs

For each entry where the encoding is a small mechanical edit (frequently true for `kind: difficulty` with a clear `suggested_encoding`):

1. Generate the diff (the agent makes a best-effort guess at the change)
2. Append the **Validation footer** (mandatory — see template below) so the staged diff documents how a reviewer verifies the encoded fix actually works
3. Write to `scratch/encode-<entry-id>-<target-slug>.diff`
4. Print the file path: "Staged scratch/encode-DL-001-tooling.diff — review and `git apply` to land"

**Nothing is auto-applied.** The diff is staged for user review. This is the "encode, don't document" mechanism — the encoding is in the diff, not in a doc.

Entries are also saved to `.retro.md` with `system.compound.status: suggested` and `system.compound.resolved_by: scratch/encode-<id>-<target>.diff`. Clear buffer.

#### Validation footer template (mandatory on every encoded diff)

Every staged `scratch/encode-<id>-<target>.diff` MUST end with a literal `## Validation` block of this shape:

```markdown
## Validation

Run:
  <command 1>
  <command 2 — optional>

Expected:
  - <observable outcome 1>
  - <observable outcome 2 — optional>

Compound lifecycle:
  <entry-id> transitions system.compound.status: suggested → encoded when this diff lands.
  resolved_by: <commit-sha-after-land>
```

How the three sub-sections are filled:

- **`Run:`** — best-effort shell command(s) that exercise the encoded change. If the entry's `suggested_encoding` mentions a recipe/command, use it; otherwise the agent picks a sensible reproduction or verification command (compile / test / grep / curl). If genuinely unknown, write `Run: (manual review only)`.
- **`Expected:`** — observable outcomes (file content matches, command exits 0, output contains substring). Plain bullets — no full test framework needed.
- **`Compound lifecycle:`** — names the entry id and the transition compound-3-harvest's `[r]esolved` lifecycle action will execute on this entry. The `resolved_by` line is a placeholder the user fills with the actual SHA after the diff lands.

The footer makes "encoded" mean *the loop changed AND we can prove it*, not just *we wrote a patch*. Reviewers see the verification path inline with the change.

### `[d]ismiss all`

Truncate the buffer. Entries are dropped — not saved anywhere. Print one line: "✓ buffer dismissed (3 entries dropped)".

This is the "I don't want this captured" escape hatch. Use sparingly — entries dismissed here can't be recovered.

## Step 4 — Plan ID detection

When saving, populate `frontmatter.plan_id` from:

1. Current working directory: if cwd matches `docs/plans/<NNN-slug>/`, set `plan_id: <NNN-slug>`
2. Else: current git branch: if branch matches `<NNN>-<slug>`, set `plan_id: <branch-name>`
3. Else: `plan_id: null` (no plan context)

## Cross-session leftover check

At the start of any auto-firing skill, before doing its primary work, check the buffer:

- If `_buffers/<agent>.session-buffer.md` is non-empty → fire `compound-2-bubble` immediately
- Then proceed with the skill's primary work

This catches entries left over from a prior session (e.g. the user pressed Ctrl-C before the auto-bubble fired).

## What this skill does NOT do

- **No mid-session prompting**. Only at end-of-session / logical pauses / next-session leftover.
- **No auto-applying** any encoded diff. Staged-only.
- **No editing of `.retro.md` files** after writing them. (That's `compound-3-harvest`'s job for lifecycle status mutations.)
- **No reading or aggregating** retros from other sessions. Each bubble drains its OWN buffer; cross-session aggregation is `compound-3-harvest`.

## Edge cases

- **Empty buffer**: silent. No prompt. Exit cleanly.
- **Sentinel during bubble**: if `.disabled` appears mid-bubble, abort (don't write). Buffer stays as-is.
- **Concurrent bubbles** (two agents simultaneously): each has its own buffer, no collision.
- **Save to a path that already exists** (extremely rare hash collision): append `-2`, `-3`, etc. to the filename per workshop 006 § EC3.
- **User interrupts mid-prompt**: buffer stays unchanged. Next bubble will see the same entries.
- **Malformed entry in buffer**: skip with a warning ("⚠ skipped 1 malformed entry"); save the valid ones; clear buffer (the malformed one is lost — better than corrupting a `.retro.md`).

## One-line encoding hint generation

For each entry, the prompt shows a one-line encoding hint. Source:

1. If `entry.suggested_encoding` is set → use it verbatim
2. Else, derive from `entry.kind` + `entry.target`:
   - `difficulty/tooling` → "wrap in a justfile recipe"
   - `difficulty/skill` → "edit the SKILL.md"
   - `magic-wand/<any>` → "encode as the suggestion above"
   - `gift/<any>` → "no encoding needed"
   - `insight/<any>` → "document in AGENTS.md or a docs/how article"
3. Else → "(no encoding hint — review manually)"

## References

- Workshop 001 — Self-improvement vibe (§ Anti-vibe 1 nag-ware; § D5 terse one-line hints)
- Workshop 004 — SDD pipeline integration (§ Walkthrough D)
- Workshop 005 — Universal retro contract (§ envelope; § D9 round-trip)
- Workshop 006 — Compound folder layout (§ Path Resolver; § EC2 cross-session carryover)
- Spec § Acceptance Criteria #7-12, #23
