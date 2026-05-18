# Compound Schemas

The universal retro contract — JSON Schema definitions that govern every `.retro.md` file produced or consumed by compound, minih, and any other system that adopts the contract.

## Files

| File | Purpose |
|------|---------|
| [`retro.schema.json`](./retro.schema.json) | The universal retro contract. One retro per run/session. Frontmatter of every `.retro.md` file validates against this. |
| [`system.compound.schema.json`](./system.compound.schema.json) | Compound's namespace extension (`entry.system.compound.*`). Lifecycle metadata: `status`, `resolved_by`, harvest counters, `source`. |
| [`system.minih.schema.json`](./system.minih.schema.json) | Minih's namespace extension (`retro.system.minih.*` or `entry.system.minih.*`). Run metadata: `run_dir`, `events_count`, `status`. |
| [`fixtures/`](./fixtures/) | Test fixtures — example `.retro.md` files covering full / minimum / multi-kind / lifecycle-rich / malformed cases. |

## Wire format

`.retro.md` = markdown file with YAML frontmatter.

- **Frontmatter** validates against `retro.schema.json` (root) plus optional `system.*.schema.json` for namespace fields.
- **Body** (after the second `---`) is free-text reflection. Optional. Not schema-validated.

## Validating by hand

```bash
# With ajv-cli (npm install -g ajv-cli)
ajv validate -s retro.schema.json -d <(yq -o json '.' fixtures/full.retro.md)

# With python (yaml + jsonschema)
python3 -c "
import yaml, json, sys, jsonschema
with open('fixtures/full.retro.md') as f:
    content = f.read()
# Extract YAML frontmatter (between first two --- lines)
parts = content.split('---', 2)
frontmatter = yaml.safe_load(parts[1])
with open('retro.schema.json') as f:
    schema = json.load(f)
jsonschema.validate(frontmatter, schema)
print('OK')
"
```

## Versioning

`schema_version` in frontmatter follows SemVer:

- **Major** (1.x → 2.x): breaking — readers MUST reject
- **Minor** (1.0 → 1.1): additive — readers MUST accept (forward-compat)
- **Patch** (1.0 → 1.0.1): documentation only

Current version: `1.0`.

## Provenance

These schemas are the v1 home for the universal contract. Workshop 005 (universal retro contract) locked the design. In v2, after ~1 month of dogfood, the schemas will be extracted to a shared `@ai-substrate/retro-schema` npm package and consumed via `npm install` by both this repo and minih. Until extraction, minih vendors a copy with a known commit reference.

## See also

- [Workshop 005 — Universal retro contract](../../../docs/plans/023-difficulty-ledger-skill/workshops/005-universal-retro-contract.md)
- [Workshop 006 — Compound folder layout](../../../docs/plans/023-difficulty-ledger-skill/workshops/006-compound-folder-layout.md)
