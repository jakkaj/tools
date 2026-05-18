# Failure Branches

The live skill handles these branches inline.

| ID | Condition | Response |
|----|-----------|----------|
| F-01 | Slash command unavailable | Refuse, point to `installation-check.md`, do not create state. |
| F-02 | RPI agent run fails or is interrupted | Ask for the error/output tail; offer retry or re-scope. |
| F-03 | Artifact missing after dispatch | Offer re-run, re-point to a different path, or continue with a warning. |
| F-04 | Repeated red or over-scoped task | Offer fallback catalogue; after repeated refusal, suggest pausing. |
| F-05 | No tests or run command exists | Continue artifact-only and record a verification gap. |
| F-06 | Dirty git state mid-tutorial | Pause for commit, stash, or explicit acknowledgement. |
| F-07 | Learner says "just do it for me" | Skip one level of explanation, but keep learner in control; recalibrate if repeated. |
| F-08 | Learner disappears mid-phase | On resume, detect stale timestamp and resume from the boundary. |
| F-09 | Resume state points to missing files | Offer re-run, re-point, continue-with-warning, or fresh start. |
| F-10 | Protected branch | Block and offer `git checkout -b sdd-tutorial-<learner-slug>`. |
| F-11 | Red task category | Refuse until a green task is chosen; logging only with consent. |
