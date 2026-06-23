# validate-v2 — durable record (compact sidecar)

Backs `SKILL.md` §10. The validator is **read-only through adjudication**; the only artifact it may create is this sidecar, and only in a durable plan/review context.

## Where (and whether)

No live consumer reads an inline `## Validation Record`, so **do not append records to the validated target**. Instead, for plan-associated work write **one sidecar per artifact**:

```text
docs/plans/<plan>/validations/<artifact-stem>-validation.md
```

- **Overwrite** it on revalidation — git preserves prior versions, so the file stays one compact current record, never a growing log.
- Outside a durable plan/review context (a loose file, a console-only check, a non-markdown target) **print the verdict and create nothing**.
- Do **not** repeat the full Validation Contract or an agent/lens roster in the sidecar. No worker counts.

## Template

```markdown
# Validation — <artifact>

- **Validated**: <ISO>
- **Target**: <path + hash, or base..head>
- **Contract sources**: <paths/ids>
- **Checks**: <commands / material source checks actually run>
- **Verdict**: VALIDATED | VALIDATED WITH FIXES | NEEDS ATTENTION
- **Thesis / proof**: <one line — purpose met?; target proof → actual proof>
- **Consumers**: <one line — N/N satisfied | STANDALONE | N/A>

## Findings
| Severity | Finding | Evidence | Status |
|---|---|---|---|

## Repairs
_Omit this section when no repair was made._
```

- `VALIDATED WITH FIXES` requires that the targeted re-check of each repaired item **passed** (`SKILL.md` §9). A repair that wasn't reverified is not a fix.
- A finding appears **once** — in the Findings table. Don't echo it into the header lines.

## Migration note

Earlier `validate-v2` appended a long inline `## Validation Record` (thesis block + agent/lens table + forward-compat matrix) to the target itself, mutating its line numbers. That is **retired**. Existing inline records already committed in `docs/plans/**` are point-in-time history — leave them; git and a maintainer changelog own that past. New runs write the compact sidecar above.
