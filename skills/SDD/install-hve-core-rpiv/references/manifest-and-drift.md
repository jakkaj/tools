# Manifest and Drift

The manifest is the boundary between installer-managed generated files and user-owned files.

## Manifest path

For default installs:

```text
.agents/skills/.hve-core-rpiv-install.json
```

For custom destinations, write the manifest at:

```text
<destination>/.hve-core-rpiv-install.json
```

## Manifest schema

```json
{
  "schema_version": 1,
  "installer": "install-hve-core-rpiv",
  "source_repo": "https://github.com/microsoft/hve-core",
  "source_ref": "origin/main",
  "source_commit": "<sha>",
  "installed_at": "<iso8601>",
  "destination": ".agents/skills",
  "managed_skills": [
    "task-research",
    "task-plan",
    "task-implement",
    "task-review"
  ],
  "managed_files": {
    "task-research/SKILL.md": "<sha256>",
    "task-plan/SKILL.md": "<sha256>",
    "task-implement/SKILL.md": "<sha256>",
    "task-review/SKILL.md": "<sha256>"
  },
  "previous_source_commit": "<sha-or-null>",
  "overwrites_confirmed": false
}
```

Only files listed in `managed_files` are installer-managed. Everything else in the destination is user-owned unless the user explicitly says otherwise.

## First install

1. Read any existing manifest.
2. If no manifest exists, check each target generated skill path.
3. If a target path exists and is not managed by this installer, refuse to overwrite unless the user explicitly confirms.
4. Render generated files to staging.
5. Hash staged files.
6. Copy staged files into destination only after validation passes.
7. Write the manifest last.

## Rerun at same commit

If `source_commit` matches the current upstream commit:

- Recompute hashes for managed files.
- If hashes match, report already up to date or revalidated.
- If hashes differ, treat the file as local drift and ask before overwriting.
- Do not rewrite files unnecessarily.

## Rerun at newer commit

If upstream resolved commit differs:

1. Render the new generated set in staging.
2. Compare each currently installed managed file hash to the manifest.
3. If installed file hash matches the manifest, it can be replaced by the new generated file.
4. If installed file hash differs from the manifest, stop and ask before overwriting.
5. Never update unmanaged files unless the user explicitly confirms.
6. Write the new manifest after all managed file writes succeed.

## Dirty destination and worktree safety

If the destination is inside a git worktree:

- Check whether managed files or the manifest have uncommitted changes when possible.
- If dirty generated files are present, refuse or clearly abort before writes unless the user explicitly accepts the risk.
- Do not block on unrelated dirty files outside the destination; report them only if they affect installer-managed paths.

If the destination is not in a git worktree:

- Use manifest hash comparison as the safety source.
- Treat hash mismatches as local drift.

## Rollback

For v1, rollback guidance is manifest-based:

- If the previous generated set is still available from the prior manifest and files were replaced during this run, restore the prior managed files from backup/staging when the installer created a backup.
- If no backup is available, rerun the installer from a previous commit only when the user provides a local source or future version supports explicit refs.
- Always report the current manifest path and source commit so the user can identify what is installed.

Because v1 intentionally does not expose pinned refs or SHAs as a normal user option, rollback is guidance-first unless a backup was created during the run.

## Uninstall

To uninstall:

1. Read the manifest.
2. Remove only files listed in `managed_files`.
3. Remove empty managed skill directories.
4. Remove the manifest.
5. Leave unmanaged files and directories untouched.

If a managed file has drifted since the manifest was written, ask before removing it.

## No partial install

The destination is considered unchanged unless all of these complete:

- source acquisition succeeds
- required upstream files are present
- generated files render to staging
- staged validation passes
- managed collision/drift checks pass
- file writes complete
- manifest write completes

If any earlier step fails, clean staging/temp files and leave the destination unchanged. If a write fails after managed files have changed, report the partial state and use any available backup to restore the previous managed set before returning.
