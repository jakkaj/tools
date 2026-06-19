# ship

> Sub-skill — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: ship
**Purpose**: Get the work **out** — push the branch, open a pull request (using repo PR guidance when present), watch the PR's CI checks, and report problems. The actual merge is **optional** (platform auto-merge, or a separate confirm-gated step); a meaningfully diverged base is handed off to the upstream-**reconcile** excursion rather than merged locally here. Best-effort throughout: degrades to a printed instruction when `gh` is absent, the repo is on its default branch with nothing to push, or no CI is configured — it never crashes out of a `gh` call.

**Consumes**: an implemented + reviewed plan (review verdict APPROVE / clean, or an explicit user override); plan folder resolvable (`*-plan.md`, or a legacy `*-spec.md`); a git repository. Optional inputs (all best-effort, each degrades): a working branch with commits ahead of the base; `gh` CLI present + authenticated; repo PR guidance — `.github/pull_request_template.md` (or `.github/PULL_REQUEST_TEMPLATE*`), `CONTRIBUTING*`, `CODEOWNERS`, the repo's default base branch.

**Flags**: `--plan "<abs path to docs/plans/<ordinal>-<slug>/>"` (optional; auto-detect from cwd) · `--base "<branch>"` (optional; PR base, default = repo default branch) · `[--no-watch]` (optional; open the PR but skip the CI-check watch) · `[--draft]` (optional; open the PR as a draft) · `[--watch-cap "<minutes>"]` (optional; bound the check-watch, default 20).

**Produces**: a pushed branch; an opened (or reused) PR behind an explicit confirm; a ship report at `${PLAN_DIR}/ship/${DATE}/ship-report.md` (PR URL, base, check results, any failing checks + their details link, resume note); terminal summary = PR URL + check status + (on red) the fix-loop offer. An actual merge is produced **only** on a separate typed `PROCEED`.

**Side effects**: outward-facing — `git push` (confirm #1), `gh pr create` (confirm #2), and an **optional** `gh pr merge` / `git merge` **only** on typed `PROCEED`. Each is public; **never** fired on a generic "yes". No source files are modified.

---

## Procedure

Get the work out: push → open PR (repo-guidance-aware) → watch checks → report problems → (optional) merge. Every outward-facing action is behind its own explicit confirmation; everything degrades to a printed instruction rather than an error.

> Elegance: the ship report is **output**. Record the PR URL, the base, the check verdicts, and the resume note — the facts a human needs to act — not a play-by-play. Doctrine + the seven-function line test: `references/00-routing.md` § Shared conventions.

> **Safety**: push, PR-open, and merge are outward-facing. They each pause for an explicit go-ahead, the merge for a typed `PROCEED` specifically. Reading state (`git status`, `gh pr view`, `gh pr checks`) is always safe and never gated.

---

```md
User input:

$ARGUMENTS
# Optional flags:
# --plan "<abs path to docs/plans/<ordinal>-<slug>/>"  # plan folder (auto-detect if in plan dir)
# --base "<branch>"                                     # PR base (default: repo default branch)
# --no-watch                                            # open the PR, skip the CI-check watch
# --draft                                               # open the PR as a draft
# --watch-cap "<minutes>"                               # bound the check-watch (default: 20)

## Execution Flow

1) Input Resolution

   - PLAN_DIR = provided --plan OR auto-detect from cwd (look for *-plan.md, or a legacy *-spec.md)
   - PLAN_SLUG = plan folder name minus ordinal (e.g. "035-flow-ship-stage" -> "flow-ship-stage")
   - BASE = provided --base OR repo default branch:
     `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` (fallback:
     `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's@^origin/@@'`, then `main`)
   - DATE = `date +%Y-%m-%d`
   - BRANCH = `git symbolic-ref --short HEAD 2>/dev/null` (empty = detached HEAD)

2) Preconditions & degradation (read-only probes; on any miss, PRINT an instruction and STOP
   the affected outward action — never crash, never call `gh pr create` blindly):

   a) **Nothing to ship as a PR** — detect and degrade to a printed instruction (AC-10):
      - `BRANCH` is empty (detached HEAD), OR
      - `BRANCH == BASE` (on the default branch — the common "main-only" case), OR
      - no commits ahead of base: `git rev-list --count ${BASE}..HEAD` is `0`
      → print, then stop the PR path:
      ```
      ⚠️ Nothing to open a PR from: you're on "${BRANCH:-detached HEAD}" with no commits ahead of ${BASE}.
         Create a feature branch first, then re-run:
           git switch -c ${PLAN_SLUG}
           git push -u origin ${PLAN_SLUG}
      ```
      (Do NOT invoke `gh pr create` with head == base — it fails; this printed instruction replaces it.)

   b) **No remote / no upstream** (AC-06): `git remote get-url origin` fails →
      print `git remote add origin <url>` guidance and stop the push path.

   c) **`gh` absent or unauthenticated** (AC-06): `gh auth status` fails (or `command -v gh` empty) →
      the whole PR path degrades to push + a compare URL:
      ```
      gh not available — pushing the branch and printing a compare URL instead:
        git push -u origin ${BRANCH}
        <remote-web-url>/compare/${BASE}...${BRANCH}
      ```
      Run the push (still behind confirm #1), print the compare URL, write the report, stop.

   d) **Dirty tree**: `git status --porcelain` non-empty → note the uncommitted files; only committed
      work ships. Offer to proceed (push existing commits) or stop so the user can commit.

3) Read repo PR guidance (best-effort; each optional — absence is normal, never an error) (AC-03):

   | Source | Read | Use |
   |---|---|---|
   | `.github/pull_request_template.md` / `.github/PULL_REQUEST_TEMPLATE*` | template body | seed the PR body |
   | `CONTRIBUTING*` (root or `.github/`) | PR conventions | honor any title/label/checklist convention |
   | `CODEOWNERS` | owners | let `gh` auto-request reviewers; do not hand-assign |
   | `gh repo view --json defaultBranchRef` | default base | confirm BASE when `--base` not given |

   **Absent (default path)**: title = the plan's feature name (from `*-plan.md` h1 / Summary);
   body = the plan's `## Business Specification` § Summary (or the plan summary) + a trailing
   "🤖 Generated with the SDD flow" line. Quote the plan, don't invent scope.

4) Confirm gate #1 — PUSH (its own gate; AC-04). Print the exact command, then ask to proceed:
   ```
   git push -u origin ${BRANCH}
   ```
   On a clear go-ahead → run it. (This confirm covers ONLY the push.)

5) Confirm gate #2 — OPEN PR (separate, outward-facing; NEVER inherits the push "yes"; AC-04, AC-06):
   - **PR already exists** for the branch? `gh pr view --json url,state,number 2>/dev/null` returns one →
     skip create, reuse it (capture URL + number), jump to step 6.
   - Else print the exact command, then ask to proceed:
     ```
     gh pr create --base ${BASE} --head ${BRANCH} \
       --title "<title>" --body "<body>" [--draft]
     ```
     On a clear go-ahead → run it. Capture PR_URL + PR_NUMBER from the output.

6) Watch CI checks (skip entirely if `--no-watch`) — BOUNDED (AC-05):
   - Enumerate once: `gh pr checks ${PR_NUMBER}`.
     - **No checks reported** ("no checks reported on the … branch") → report "no CI configured for
       this PR", write the report, STOP (this is success, not failure).
   - Else watch with a bound = `--watch-cap` minutes (default 20), interval 30s. Either
     `timeout ${cap}m gh pr checks ${PR_NUMBER} --watch --interval 30`, or a polling loop that
     re-reads `gh pr checks ${PR_NUMBER}` until all checks resolve or the cap elapses:
     - **all pass** → report green.
     - **any fail** → capture the failing check name(s) + details URL from `gh pr checks` output;
       report fail; **offer a fix-loop** (the bundling flow renders the actual command — describe it in
       verb terms: "a red check's fixes go back through the **implement** verb, then re-run **ship**").
       Never block.
     - **still pending at the cap** → report "checks still running after ${cap}m — not blocking;
       re-check with `gh pr checks ${PR_NUMBER}`", STOP.

7) Optional merge — NEVER automatic; present two gated paths (AC-04):
   - **Platform auto-merge** (preferred — lets the platform merge when checks pass + approvals land),
     behind a confirm:
     ```
     gh pr merge ${PR_NUMBER} --auto --squash
     ```
   - **Immediate merge** — ONLY on a typed `PROCEED` (outward + irreversible-ish):
     ```
     gh pr merge ${PR_NUMBER} --squash   # or --merge, per repo convention
     ```
     On `ABORT` (or anything but `PROCEED`) → leave the PR open; the ship report records where to resume.
   - **Diverged base** — if the base has meaningfully advanced since the branch point
     (`git rev-list --count HEAD..origin/${BASE}` is large, or a quick `git merge-tree` shows overlap),
     do NOT attempt a local merge here. Report the divergence and hand off to the upstream-reconcile
     excursion (the bundling flow offers it). All handoff context is git-derived.

8) Write the ship report + terminal summary (templates below).

## Ship Report Template

Write to `${PLAN_DIR}/ship/${DATE}/ship-report.md`:

```markdown
# Ship Report — ${PLAN_SLUG}

**Generated**: ${TIMESTAMP}
**Branch**: ${BRANCH} → **Base**: ${BASE}
**PR**: ${PR_URL} (#${PR_NUMBER})  ·  **State**: ${open|merged|reused|degraded-no-gh}

## Checks

| Check | Status | Details |
|-------|--------|---------|
| ${name} | ✅/❌/⏳ | ${url} |

**Verdict**: all green | ${N} failing | no CI configured | still running at cap

## Failing checks (if any)

- **${check}** — ${details-url}
  Recommended: fix via the implement verb, then re-run ship.

## Repo guidance applied

- PR template: ${found|none → default body}
- Base: ${BASE} (${default branch|--base override})
- Reviewers: ${CODEOWNERS auto-requested|none}

## Resume

- Merge not yet done → ${platform auto-merge armed | awaiting typed PROCEED | base diverged → reconcile}
- Re-check checks: `gh pr checks ${PR_NUMBER}`
```

## Success Message

```
✅ Shipped: PR ${PR_URL} (#${PR_NUMBER})
   Branch ${BRANCH} → ${BASE}
   Checks: ${all green | N failing | no CI | still running}
   Report: ${PLAN_DIR}/ship/${DATE}/ship-report.md
   ${on red: "Red check — fixes go back through implement, then re-run ship." }
   ${merge: "Merge is optional — auto-merge armed / type PROCEED to merge now / base diverged → reconcile." }
```

Degraded (no `gh`):
```
✅ Pushed ${BRANCH} → compare: <remote-web-url>/compare/${BASE}...${BRANCH}
   (gh unavailable — open the PR in the web UI; re-run ship once gh is authed to watch checks.)
```

## Notes

- **Read-only by default until a confirm.** Probes (`git status`, `gh pr view/checks`) never change state.
- **Push / PR / merge are three separate gates.** A "yes" to push is not a "yes" to open a PR;
  a merge needs a typed `PROCEED`.
- **All context is git/`gh`-derived.** No external services beyond the repo's own remote + checks.
- **Best-effort.** Missing `gh`, main-only repo, no CI, existing PR — each degrades to a printed
  instruction or a reused artifact, never a hard failure.
```

---

## Exit

Print the output-contract summary (✅ block: PR URL, base, check status, report path; on red the fix-loop offer; merge left optional). Then STOP. Do not name a next stage. If invoked standalone, end with exactly: "Routing is the flow's job — run the parent flow bare to continue."
