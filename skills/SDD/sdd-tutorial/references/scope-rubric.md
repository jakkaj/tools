# Task Scope Rubric

Use this in Phase 3 after inviting a real task from the learner's repo.

## Green: proceed

- Touches 1-3 files.
- Has one clear acceptance condition.
- No schema or database migration.
- No production credentials, secrets, or auth-token handling.
- No auth, payment, or security-critical behaviour change.
- Can be verified locally or manually.

## Yellow: narrow before proceeding

- File boundary is unclear.
- Multiple acceptance conditions.
- Unfamiliar subsystem.
- No obvious verification path.

Coach a smaller green slice before proceeding.

## Red: refuse

- Broad refactor or vague cleanup.
- Architecture change.
- Production data manipulation.
- Secrets, credentials, or API keys.
- Deployment, CI, or infrastructure changes.
- Auth, payment, or security-critical behaviour.
- Vague aspiration such as "make this app better".

For red tasks, refuse and ask for a safer task. Offer the fallback catalogue after one red refusal or two failed yellow narrowing attempts.
