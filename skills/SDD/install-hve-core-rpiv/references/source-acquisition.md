# Source Acquisition

Use this contract when `install-hve-core-rpiv` needs the current HVE Core RPIV source.

## Source of truth

- Repository: `https://github.com/microsoft/hve-core`
- Source ref: latest default branch in v1.
- Resolved commit: record the exact commit used for generation.

Do not modify HVE Core source. When `gh` is available, do not clone the repository; fetch only the required metadata and file contents. Treat any fallback git clone as temporary/cache state used only to read upstream files.

## Acquisition order

1. Detect GitHub CLI:

   ```bash
   command -v gh
   ```

2. If `gh` exists, use it to resolve the default branch and commit without cloning:

   ```bash
   DEFAULT_BRANCH="$(gh repo view microsoft/hve-core --json defaultBranchRef --jq '.defaultBranchRef.name')"
   SOURCE_COMMIT="$(gh api "repos/microsoft/hve-core/commits/${DEFAULT_BRANCH}" --jq '.sha')"
   ```

3. With `gh`, fetch each required source file directly from the resolved commit into a temporary file cache:

   ```bash
   gh api "repos/microsoft/hve-core/contents/.github/prompts/hve-core/task-research.prompt.md?ref=${SOURCE_COMMIT}"
   ```

   Decode the returned `content` field and write it to the same relative path under the temporary file cache. Repeat for every required upstream file listed below. The installer may use any platform-safe decoder; the important contract is that `gh` mode fetches files directly and does not clone.

4. If `gh` is unavailable or the user asks not to use it, fall back to plain git:

   ```bash
   git clone https://github.com/microsoft/hve-core "$TEMP_DIR/hve-core"
   ```

5. For the git fallback, resolve the commit from the cloned source:

   ```bash
   git -C "$TEMP_DIR/hve-core" rev-parse HEAD
   git -C "$TEMP_DIR/hve-core" rev-parse --abbrev-ref HEAD
   ```

Record both source ref and commit in the install manifest.

## Required upstream files

Validate these files exist before rendering generated skills:

| Generated skill | Source prompt | Source agent |
|-----------------|---------------|--------------|
| `task-research` | `.github/prompts/hve-core/task-research.prompt.md` | `.github/agents/hve-core/task-researcher.agent.md` |
| `task-plan` | `.github/prompts/hve-core/task-plan.prompt.md` | `.github/agents/hve-core/task-planner.agent.md` |
| `task-implement` | `.github/prompts/hve-core/task-implement.prompt.md` | `.github/agents/hve-core/task-implementor.agent.md` |
| `task-review` | `.github/prompts/hve-core/task-review.prompt.md` | `.github/agents/hve-core/task-reviewer.agent.md` |

Also check `collections/hve-core.collection.yml` when present so the report can show which HVE Core collection layout was used.

## Failure behavior

If `gh` or `git` fails because of network, authentication, or repository access:

1. Stop before writing generated skills.
2. Report the failed command category (`gh` or `git`) without leaking credentials.
3. Say the destination was left unchanged.
4. Clean up temporary file caches, fallback clone directories, and staging directories.
5. Point the user to the official HVE Core install guide if they need the native install path: <https://microsoft.github.io/hve-core/docs/getting-started/install>.

If source validation fails because an expected prompt or agent file is missing:

1. Stop before writing generated skills.
2. Report the missing relative paths.
3. Record the resolved commit in the failure report so the upstream shape can be investigated.
4. Leave the destination unchanged.

## Cleanup

Use a temporary working directory for direct-fetched source files, fallback source clones, and staging. Remove it on both success and failure.

If cleanup cannot complete, do not claim a clean exit. Report the leftover path and say it can be removed manually after the run.
