# Compound Schemas

The universal retro contract — JSON Schema definitions that govern every `.retro.md` file produced or consumed by compound, minih, and any other system that adopts the contract.

## Files

| File | Purpose |
|------|---------|
| [`retro.schema.json`](./retro.schema.json) | The universal retro contract. One retro per run/session. Frontmatter of every `.retro.md` file validates against this. |
| [`system.compound.schema.json`](./system.compound.schema.json) | Compound's namespace extension (`entry.system.compound.*`). Lifecycle metadata: `status`, `resolved_by`, harvest counters, `source`. |
| [`system.minih.schema.json`](./system.minih.schema.json) | Minih's namespace extension (`retro.system.minih.*` or `entry.system.minih.*`). Run metadata: `run_dir`, `events_count`, `status`. |
| [`fixtures/`](./fixtures/) | Test fixtures — example `.retro.md` files covering full / minimum / multi-kind / lifecycle-rich / schema-safe signal/back-pressure / malformed cases. |

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

Validate every non-malformed fixture by extracting the YAML frontmatter before passing it to the JSON Schema:

```bash
python3 - <<'PY'
import json
from pathlib import Path

import jsonschema
import yaml

schema = json.loads(Path("retro.schema.json").read_text())
for path in sorted(Path("fixtures").glob("*.retro.md")):
    if path.name == "malformed.retro.md":
        continue
    content = path.read_text()
    if not content.startswith("---\n"):
        raise SystemExit(f"{path}: missing YAML frontmatter")
    frontmatter = content.split("---", 2)[1]
    jsonschema.validate(yaml.safe_load(frontmatter), schema)
    print(f"OK {path}")
PY
```

Run this from `skills/compound/schemas/`. It intentionally validates the frontmatter only; the markdown body remains free text.

## Encoding signal, sensor, and back-pressure gaps

The schema deliberately keeps a small `kind` enum. Do **not** add ad-hoc kinds such as `signal-gap`, `sensor-gap`, or `weak-back-pressure` unless a deliberate schema migration has been planned. Encode these as ordinary entries with richer targets and encoding hints:

| Gap | `kind` | Example `target` | Example `suggested_encoding` |
|-----|--------|------------------|------------------------------|
| Agent had to infer runtime behavior | `difficulty` | `project-sensor` or `runtime-inspectability` | `add smoke command or visual evidence capture` |
| Missing deterministic architecture proof | `improvement-suggestion` | `architecture-fitness` | `architecture check recipe` |
| Wished-for proof command or evidence path | `magic-wand` | `tooling`, `skill`, or `runtime-inspectability` | `engineering-harness command map entry` |

See [`fixtures/signal-backpressure.retro.md`](./fixtures/signal-backpressure.retro.md) for a schema-valid example.

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
