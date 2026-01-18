# Simple Workflow Schema

## Folder Structure

```
runs/
└── run-2024-01-18-001/
    ├── wf-run.json
    │
    └── stages/
        ├── 01-explore/
        │   ├── inputs/
        │   │   └── user-description.md    (from user, required)
        │   └── run/
        │       ├── runtime-inputs/
        │       │   └── manifest.json
        │       ├── output-files/
        │       │   └── research-dossier.md
        │       └── output-data/
        │           ├── wf-result.json
        │           └── findings.json
        │
        ├── 02-specify/
        │   ├── inputs/
        │   │   ├── user-description.md    (from user, optional)
        │   │   └── research-dossier.md    (from: 01-explore)
        │   └── run/
        │       ├── runtime-inputs/
        │       │   └── manifest.json
        │       ├── output-files/
        │       │   └── spec.md
        │       └── output-data/
        │           └── wf-result.json
        │
        ├── 03-clarify/
        │   ├── inputs/
        │   │   └── spec.md                (from: 02-specify)
        │   └── run/
        │       ├── runtime-inputs/
        │       │   └── manifest.json
        │       ├── output-files/
        │       │   └── spec.md            (enriched version)
        │       └── output-data/
        │           ├── wf-result.json
        │           └── answers.json
        │
        ├── 04-architect/
        │   ├── inputs/
        │   │   ├── spec.md                (from: 03-clarify)
        │   │   ├── answers.json           (from: 03-clarify)
        │   │   └── idioms.md              (from: codebase, optional)
        │   └── run/
        │       ├── runtime-inputs/
        │       │   └── manifest.json
        │       ├── output-files/
        │       │   └── plan.md
        │       └── output-data/
        │           ├── wf-result.json
        │           └── phases.json
        │
        │   # ════════════════════════════════════════════════════════
        │   # DYNAMIC SUB-WORKFLOW: Phase Execution Loop
        │   # Expanded at runtime from 04-architect/phases.json
        │   # See: "Folder Structure: Dynamic Sub-Workflow (Expanded)"
        │   # ════════════════════════════════════════════════════════
        │
        └── phase-execution-loop/
            ├── subwf-config.json          # Generated at expansion time
            └── iterations/                # Contains expanded stages
                └── ...                    # See dynamic section below
```

---

## Input Categories

| Category | When | Where | Purpose |
|----------|------|-------|---------|
| `params.json` | Before execution | Stage root | Explicit values that drive behavior |
| `inputs/` | Before execution | Assembled by WF engine | Files the stage is expected to need |
| `runtime-inputs/` | During/after execution | Written by stage | Log of files actually read |

---

## inputs/ vs runtime-inputs/

**inputs/** - The "package" assembled by WF engine before stage runs:
- WF engine knows these from stage definition
- Copied/linked into place before execution
- Stage may or may not use all of them

**runtime-inputs/** - Audit log of discovered/codebase reads:
- Written during execution
- Only tracks files NOT in `inputs/` (those are already known from WF config)
- `manifest.json` lists codebase files that were discovered and read
- Optional `.snapshot` files for full reproducibility

This split enables:
1. **Reproducibility audit**: Compare inputs/ (expected) vs runtime-inputs/ (actual)
2. **Codebase tracking**: Know which repo files were read without copying them upfront
3. **Drift detection**: Did the stage read something unexpected?

---

## Folder Structure: Dynamic Sub-Workflow (Expanded)

After expansion with 3 phases from `04-architect/phases.json`:

```
runs/
└── run-2024-01-18-001/
    └── stages/
        ├── 01-explore/
        ├── 02-specify/
        ├── 03-clarify/
        ├── 04-architect/
        │   └── run/
        │       └── output-data/
        │           └── phases.json        # Seed: [{phase:1}, {phase:2}, {phase:3}]
        │
        └── phase-execution-loop/
            │
            ├── subwf-config.json          # Generated at expansion time
            │   {
            │     "seed_source": "04-architect/run/output-data/phases.json",
            │     "expanded_at": "2024-01-18T10:30:00Z",
            │     "iteration_count": 3,
            │     "validation": { "valid": true }
            │   }
            │
            └── iterations/
                │
                │   # ══════════ ITERATION 1 ══════════
                │
                ├── 01/
                │   ├── iteration-params.json
                │   │   { "phase": 1 }
                │   │
                │   ├── enrich/
                │   │   ├── stage-config.json
                │   │   │   {
                │   │   │     "iteration": 1,
                │   │   │     "params": { "phase": 1 },
                │   │   │     "inputs": {
                │   │   │       "plan.md": "04-architect/run/output-files/plan.md"
                │   │   │     },
                │   │   │     "outputs": {
                │   │   │       "files": ["tasks.md"],
                │   │   │       "data": ["wf-result.json", "tasks.json"]
                │   │   │     }
                │   │   │   }
                │   │   ├── inputs/
                │   │   │   └── plan.md
                │   │   └── run/
                │   │       ├── runtime-inputs/
                │   │       │   └── manifest.json
                │   │       ├── output-files/
                │   │       │   └── tasks.md
                │   │       └── output-data/
                │   │           ├── wf-result.json
                │   │           └── tasks.json
                │   │
                │   ├── implement/
                │   │   ├── stage-config.json
                │   │   │   {
                │   │   │     "iteration": 1,
                │   │   │     "inputs": {
                │   │   │       "tasks.md": "{subwf}/iterations/01/enrich/run/output-files/tasks.md"
                │   │   │     },
                │   │   │     "outputs": {
                │   │   │       "files": ["execution.log.md"],
                │   │   │       "data": ["wf-result.json"]
                │   │   │     }
                │   │   │   }
                │   │   ├── inputs/
                │   │   │   └── tasks.md
                │   │   └── run/
                │   │       ├── output-files/
                │   │       │   └── execution.log.md
                │   │       └── output-data/
                │   │           └── wf-result.json
                │   │
                │   └── review/
                │       ├── stage-config.json
                │       │   {
                │       │     "iteration": 1,
                │       │     "inputs": {
                │       │       "tasks.md": "{subwf}/iterations/01/enrich/run/output-files/tasks.md",
                │       │       "execution.log.md": "{subwf}/iterations/01/implement/run/output-files/execution.log.md"
                │       │     },
                │       │     "outputs": {
                │       │       "data": ["wf-result.json", "verdict.json"]
                │       │     }
                │       │   }
                │       ├── inputs/
                │       │   ├── tasks.md
                │       │   └── execution.log.md
                │       └── run/
                │           └── output-data/
                │               ├── wf-result.json
                │               └── verdict.json
                │
                │   # ══════════ ITERATION 2 ══════════
                │
                ├── 02/
                │   ├── iteration-params.json
                │   │   { "phase": 2 }
                │   │
                │   ├── enrich/
                │   │   ├── stage-config.json
                │   │   │   {
                │   │   │     "iteration": 2,
                │   │   │     "params": { "phase": 2 },
                │   │   │     "inputs": {
                │   │   │       "plan.md": "04-architect/run/output-files/plan.md",
                │   │   │       "history/phase-1-tasks.md": "{subwf}/iterations/01/enrich/run/output-files/tasks.md",
                │   │   │       "history/phase-1-execution.log": "{subwf}/iterations/01/implement/run/output-files/execution.log.md"
                │   │   │     },
                │   │   │     "outputs": {
                │   │   │       "files": ["tasks.md"],
                │   │   │       "data": ["wf-result.json", "tasks.json"]
                │   │   │     }
                │   │   │   }
                │   │   ├── inputs/
                │   │   │   ├── plan.md
                │   │   │   └── history/
                │   │   │       ├── phase-1-tasks.md
                │   │   │       └── phase-1-execution.log
                │   │   └── run/
                │   │       ├── output-files/
                │   │       │   └── tasks.md
                │   │       └── output-data/
                │   │           ├── wf-result.json
                │   │           └── tasks.json
                │   │
                │   ├── implement/
                │   │   ├── inputs/
                │   │   │   └── tasks.md
                │   │   └── run/
                │   │       └── ...
                │   │
                │   └── review/
                │       ├── inputs/
                │       │   ├── tasks.md
                │       │   └── execution.log.md
                │       └── run/
                │           └── ...
                │
                │   # ══════════ ITERATION 3 ══════════
                │
                └── 03/
                    ├── iteration-params.json
                    │   { "phase": 3 }
                    │
                    ├── enrich/
                    │   ├── stage-config.json
                    │   │   {
                    │   │     "iteration": 3,
                    │   │     "params": { "phase": 3 },
                    │   │     "inputs": {
                    │   │       "plan.md": "04-architect/run/output-files/plan.md",
                    │   │       "history/phase-1-tasks.md": "{subwf}/iterations/01/enrich/run/output-files/tasks.md",
                    │   │       "history/phase-1-execution.log": "{subwf}/iterations/01/implement/run/output-files/execution.log.md",
                    │   │       "history/phase-2-tasks.md": "{subwf}/iterations/02/enrich/run/output-files/tasks.md",
                    │   │       "history/phase-2-execution.log": "{subwf}/iterations/02/implement/run/output-files/execution.log.md"
                    │   │     },
                    │   │     "outputs": {
                    │   │       "files": ["tasks.md"],
                    │   │       "data": ["wf-result.json", "tasks.json"]
                    │   │     }
                    │   │   }
                    │   ├── inputs/
                    │   │   ├── plan.md
                    │   │   └── history/
                    │   │       ├── phase-1-tasks.md
                    │   │       ├── phase-1-execution.log
                    │   │       ├── phase-2-tasks.md
                    │   │       └── phase-2-execution.log
                    │   └── run/
                    │       ├── runtime-inputs/
                    │       │   └── manifest.json
                    │       ├── output-files/
                    │       │   └── tasks.md
                    │       └── output-data/
                    │           ├── wf-result.json
                    │           └── tasks.json
                    │
                    ├── implement/
                    │   ├── stage-config.json
                    │   │   {
                    │   │     "iteration": 3,
                    │   │     "inputs": {
                    │   │       "tasks.md": "{subwf}/iterations/03/enrich/run/output-files/tasks.md"
                    │   │     },
                    │   │     "outputs": {
                    │   │       "files": ["execution.log.md"],
                    │   │       "data": ["wf-result.json"]
                    │   │     }
                    │   │   }
                    │   ├── inputs/
                    │   │   └── tasks.md
                    │   └── run/
                    │       ├── output-files/
                    │       │   └── execution.log.md
                    │       └── output-data/
                    │           └── wf-result.json
                    │
                    └── review/
                        ├── stage-config.json
                        │   {
                        │     "iteration": 3,
                        │     "inputs": {
                        │       "tasks.md": "{subwf}/iterations/03/enrich/run/output-files/tasks.md",
                        │       "execution.log.md": "{subwf}/iterations/03/implement/run/output-files/execution.log.md"
                        │     },
                        │     "outputs": {
                        │       "data": ["wf-result.json", "verdict.json"]
                        │     }
                        │   }
                        ├── inputs/
                        │   ├── tasks.md
                        │   └── execution.log.md
                        └── run/
                            └── output-data/
                                ├── wf-result.json
                                └── verdict.json
```

---

## Dynamic Sub-Workflow: Expansion Rules

### Path Scope Convention

| Prefix | Scope | Example |
|--------|-------|---------|
| (none) | Outside sub-workflow | `04-architect/run/output-files/plan.md` |
| `{subwf}/` | Inside sub-workflow | `{subwf}/iterations/01/enrich/run/output-files/tasks.md` |

This makes cross-boundary dependencies explicit and validates that internal stages only reference within their scope (plus declared external inputs).

### Timing

| Aspect | Defined In | Known At |
|--------|------------|----------|
| Iteration count | `phases.json` (seed) | Expansion time |
| Stage sequence | Sub-workflow template | Definition time |
| All input paths | Expansion logic | Expansion time |
| All output paths | Stage declarations | Expansion time |
| History accumulation | Template rules | Expansion time |
| Folder structure | - | Expansion time (created) |
| File content | - | Execution time |

### History Accumulation Pattern

```
iteration N enrich inputs:
  - plan.md                     (constant, from 04-architect)
  - history/phase-1-tasks.md    (from iteration 1)
  - history/phase-1-execution.log
  - history/phase-2-tasks.md    (from iteration 2)
  - history/phase-2-execution.log
  - ...
  - history/phase-(N-1)-tasks.md
  - history/phase-(N-1)-execution.log
```

---

## Dynamic Sub-Workflow: Expansion Pseudo-Code

### 1. Sub-Workflow Template Definition

```yaml
# Defined in workflow definition file (not generated)
# This is the TEMPLATE that gets expanded

id: "phase-execution-loop"
type: "dynamic-subwf"

seed:
  from: "04-architect/run/output-data/phases.json"
  iterate_over: "phases"                    # Array field to loop over

external_inputs:                            # Inputs from outside the sub-workflow
  plan.md:
    from: "04-architect/run/output-files/plan.md"

stages:
  - id: "enrich"
    params:
      phase: "{{iteration.phase}}"          # Interpolated from seed item
    inputs:
      - file: "plan.md"
        external: true                      # From external_inputs
      - folder: "history"                   # Built up from prior iterations
        accumulated: true
        pattern: "^phase-\\d+-(?:tasks\\.md|execution\\.log)$"
    outputs:
      files: ["tasks.md"]
      data: ["wf-result.json", "tasks.json"]

  - id: "implement"
    inputs:
      - file: "tasks.md"
        from: "enrich"                      # From same iteration's enrich
    outputs:
      files: ["execution.log.md"]
      data: ["wf-result.json"]

  - id: "review"
    inputs:
      - file: "tasks.md"
        from: "enrich"
      - file: "execution.log.md"
        from: "implement"
    outputs:
      data: ["wf-result.json", "verdict.json"]

accumulate:                                 # Rules for history accumulation
  - from: "enrich"
    file: "tasks.md"
    as: "phase-{n}-tasks.md"
  - from: "implement"
    file: "execution.log.md"
    as: "phase-{n}-execution.log"
```

### 2. Seed Data (Input)

```json
// 04-architect/run/output-data/phases.json
{
  "phases": [
    { "phase": 1, "name": "Core Setup" },
    { "phase": 2, "name": "Auth Layer" },
    { "phase": 3, "name": "API Integration" }
  ]
}
```

### 3. Expansion Logic (Pure Code, No LLM)

```python
def expand_dynamic_subwf(
    template: SubWfTemplate,
    seed_path: str,
    run_path: str
) -> ExpandedSubWf:
    """
    Called after seed stage (04-architect) completes.
    Creates all folders and config files.
    Returns fully expanded, statically-validatable workflow.
    """

    # ─────────────────────────────────────────────────────────
    # STEP 1: Read seed data
    # ─────────────────────────────────────────────────────────
    seed_data = read_json(seed_path)
    iterations = seed_data[template.seed.iterate_over]  # e.g., phases array
    iteration_count = len(iterations)

    # ─────────────────────────────────────────────────────────
    # STEP 2: Create sub-workflow root
    # ─────────────────────────────────────────────────────────
    subwf_path = f"{run_path}/stages/{template.id}"
    mkdir(subwf_path)
    mkdir(f"{subwf_path}/iterations")

    # ─────────────────────────────────────────────────────────
    # STEP 3: Expand each iteration
    # ─────────────────────────────────────────────────────────
    expanded_stages = []
    history_accumulator = []  # Grows with each iteration

    for iter_idx, iter_data in enumerate(iterations):
        iter_num = iter_idx + 1  # 1-indexed
        iter_path = f"{subwf_path}/iterations/{iter_num:02d}"
        mkdir(iter_path)

        # Write iteration params
        write_json(f"{iter_path}/iteration-params.json", {
            "phase": iter_data["phase"],
            "name": iter_data.get("name", f"Phase {iter_data['phase']}")
        })

        # ─────────────────────────────────────────────────────
        # STEP 3a: Expand each stage in the iteration
        # ─────────────────────────────────────────────────────
        for stage_template in template.stages:
            stage_path = f"{iter_path}/{stage_template.id}"
            mkdir(stage_path)
            mkdir(f"{stage_path}/inputs")
            mkdir(f"{stage_path}/run/output-files")
            mkdir(f"{stage_path}/run/output-data")
            mkdir(f"{stage_path}/run/runtime-inputs")

            # Build resolved inputs
            resolved_inputs = {}

            for input_spec in stage_template.inputs:
                if input_spec.get("external"):
                    # Reference outside sub-workflow
                    file_name = input_spec["file"]
                    ext_input = template.external_inputs[file_name]
                    resolved_inputs[file_name] = ext_input["from"]

                elif input_spec.get("accumulated"):
                    # Add all accumulated history items
                    # input_spec.folder is the destination folder (e.g., "history")
                    # input_spec.pattern validates accumulated file names
                    folder_name = input_spec["folder"]
                    pattern = re.compile(input_spec.get("pattern", ".*"))
                    for hist_item in history_accumulator:
                        if pattern.match(hist_item["as"]):
                            hist_key = f"{folder_name}/{hist_item['as']}"
                            resolved_inputs[hist_key] = hist_item["path"]
                        else:
                            raise ValidationError(
                                f"Accumulated file '{hist_item['as']}' "
                                f"does not match pattern '{input_spec['pattern']}'"
                            )

                elif input_spec.get("from"):
                    # Reference from same iteration
                    file_name = input_spec["file"]
                    source_stage = input_spec["from"]
                    resolved_inputs[file_name] = (
                        f"{{subwf}}/iterations/{iter_num:02d}/"
                        f"{source_stage}/run/output-files/{file_name}"
                    )

            # Build resolved outputs (just declare paths)
            resolved_outputs = {
                "files": [
                    f"{{subwf}}/iterations/{iter_num:02d}/"
                    f"{stage_template.id}/run/output-files/{f}"
                    for f in stage_template.outputs.get("files", [])
                ],
                "data": [
                    f"{{subwf}}/iterations/{iter_num:02d}/"
                    f"{stage_template.id}/run/output-data/{d}"
                    for d in stage_template.outputs.get("data", [])
                ]
            }

            # Build params (interpolate from iteration data)
            resolved_params = {}
            for param_name, param_spec in stage_template.params.items():
                if isinstance(param_spec, str) and param_spec.startswith("{{"):
                    # Interpolate: "{{iteration.phase}}" -> iter_data["phase"]
                    field = param_spec.replace("{{iteration.", "").replace("}}", "")
                    resolved_params[param_name] = iter_data[field]
                else:
                    resolved_params[param_name] = param_spec

            # Write stage-config.json
            stage_config = {
                "iteration": iter_num,
                "params": resolved_params,
                "inputs": resolved_inputs,
                "outputs": {
                    "files": stage_template.outputs.get("files", []),
                    "data": stage_template.outputs.get("data", [])
                }
            }
            write_json(f"{stage_path}/stage-config.json", stage_config)

            expanded_stages.append({
                "path": stage_path,
                "config": stage_config
            })

        # ─────────────────────────────────────────────────────
        # STEP 3b: Update history accumulator for next iteration
        # ─────────────────────────────────────────────────────
        for accum_rule in template.accumulate:
            history_accumulator.append({
                "as": accum_rule["as"].replace("{n}", str(iter_data["phase"])),
                "path": (
                    f"{{subwf}}/iterations/{iter_num:02d}/"
                    f"{accum_rule['from']}/run/output-files/{accum_rule['file']}"
                )
            })

    # ─────────────────────────────────────────────────────────
    # STEP 4: Write sub-workflow config
    # ─────────────────────────────────────────────────────────
    subwf_config = {
        "id": template.id,
        "seed_source": seed_path,
        "expanded_at": utc_now_iso(),
        "iteration_count": iteration_count,
        "stages_per_iteration": len(template.stages),
        "total_stages": iteration_count * len(template.stages),
        "external_inputs": template.external_inputs
    }
    write_json(f"{subwf_path}/subwf-config.json", subwf_config)

    # ─────────────────────────────────────────────────────────
    # STEP 5: Validate the expanded workflow
    # ─────────────────────────────────────────────────────────
    validation = validate_subwf(expanded_stages, template.external_inputs)
    subwf_config["validation"] = validation
    write_json(f"{subwf_path}/subwf-config.json", subwf_config)  # Update with validation

    return ExpandedSubWf(
        path=subwf_path,
        config=subwf_config,
        stages=expanded_stages
    )


def validate_subwf(stages: list, external_inputs: dict) -> dict:
    """
    Static validation - no execution needed.
    Verifies all input paths resolve to declared outputs.
    """
    errors = []

    # Build registry of all outputs
    output_registry = set()
    for ext_name, ext_spec in external_inputs.items():
        output_registry.add(ext_spec["from"])

    for stage in stages:
        for output_file in stage["config"]["outputs"]["files"]:
            output_registry.add(
                f"{{subwf}}/iterations/{stage['config']['iteration']:02d}/"
                f"{stage['path'].split('/')[-1]}/run/output-files/{output_file}"
            )
        for output_data in stage["config"]["outputs"]["data"]:
            output_registry.add(
                f"{{subwf}}/iterations/{stage['config']['iteration']:02d}/"
                f"{stage['path'].split('/')[-1]}/run/output-data/{output_data}"
            )

    # Validate all inputs exist in registry
    for stage in stages:
        for input_name, input_path in stage["config"]["inputs"].items():
            # Normalize path for comparison
            if not input_path.startswith("{subwf}"):
                # External input - should be in external_inputs
                if input_path not in [e["from"] for e in external_inputs.values()]:
                    errors.append(f"{stage['path']}: input '{input_name}' references "
                                f"unknown external path '{input_path}'")
            else:
                # Internal - check ordering (can only reference prior stages)
                # ... ordering validation logic ...
                pass

    return {
        "valid": len(errors) == 0,
        "errors": errors
    }
```

### 4. Result: Generated Folder Structure

After `expand_dynamic_subwf()` completes, the filesystem contains:

```
phase-execution-loop/
├── subwf-config.json           ✓ Written
└── iterations/
    ├── 01/
    │   ├── iteration-params.json   ✓ Written
    │   ├── enrich/
    │   │   ├── stage-config.json   ✓ Written
    │   │   ├── inputs/             ✓ Created (empty, populated before execution)
    │   │   └── run/                ✓ Created (empty, populated during execution)
    │   ├── implement/
    │   │   └── ...                 ✓ Same structure
    │   └── review/
    │       └── ...                 ✓ Same structure
    ├── 02/
    │   └── ...                     ✓ Same structure
    └── 03/
        └── ...                     ✓ Same structure
```

### 5. Pre-Execution: Assemble Inputs

```python
def assemble_stage_inputs(stage_path: str, stage_config: dict, run_path: str):
    """
    Called just before a stage executes.
    Copies/links files into inputs/ based on stage-config.json.
    """
    inputs_dir = f"{stage_path}/inputs"

    for input_name, source_path in stage_config["inputs"].items():
        # Resolve {subwf} placeholder
        resolved_source = source_path.replace(
            "{subwf}",
            f"{run_path}/stages/phase-execution-loop"
        )

        # Handle nested paths (e.g., "history/phase-1-tasks.md")
        dest_path = f"{inputs_dir}/{input_name}"
        mkdir(dirname(dest_path))

        # Copy or symlink
        copy_file(resolved_source, dest_path)
```
