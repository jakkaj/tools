---
description: Generate a runnable worked example that demonstrates a phase's implementation through a clear, narrative, step-by-step script you can run and debug.
---

# plan-6b-worked-example

Generate a **runnable worked toy example** that proves what a phase built, step by step, in a self-contained script you can execute, read, and step through with a debugger.

````md
User input:

$ARGUMENTS
# Expected formats:
# /plan-6b-worked-example --plan <path> --phase "<Phase N: Title>"
# /plan-6b-worked-example                    # Auto-detect from recent context
#
# Optional:
# --focus "<specific aspect>"                # Narrow to one concept
# --lang <ts|py|go|sh|...>                   # Override language detection
````

## Purpose

After implementing a phase, you want a **simple, isolated, runnable script** that:

- Imports and exercises the **real implementation** (not mocks, not pseudocode)
- Walks through behavior step by step with **narrative commentary**
- Prints clear output showing what happened at each stage
- Is small enough to **attach a debugger and step through**
- Proves the implementation works as expected

This is a **clarity tool** — it builds understanding of what was built, drives exploration, and serves as living documentation.

## Output

Every worked example produces **two files** — a runnable script and a companion walkthrough:

```
${PHASE_DIR}/examples/
├── worked-example.{ext}                    # The runnable script
└── worked-example.walkthrough.md           # Companion visual walkthrough
```

If multiple distinct concepts were built, create one pair per concept:
```
${PHASE_DIR}/examples/
├── worked-example-routing.ts
├── worked-example-routing.walkthrough.md
├── worked-example-middleware.ts
├── worked-example-middleware.walkthrough.md
└── README.md              # How to run them
```

## Execution Flow

### 1) Resolve Context

```
PLAN       = --plan flag, or auto-detect from recent context
PHASE      = --phase flag, or prompt user to select
PLAN_DIR   = dirname(PLAN)
PHASE_DIR  = PLAN_DIR/tasks/${PHASE_SLUG}
```

**If no plan context is detected**: Prompt the user for the output directory.

### 2) Detect Language

Determine the best language for the example by inspecting:

1. `--lang` flag (explicit override)
2. Files changed in the phase (from tasks.md or execution.log.md)
3. Project root indicators (package.json → TS/JS, pyproject.toml → Python, go.mod → Go, Cargo.toml → Rust)

Pick the language that matches the implementation. If the phase touched multiple languages, prefer the primary one or create separate examples.

### 3) Read Phase Artifacts

Load and understand what was built:

- `${PHASE_DIR}/tasks.md` — what tasks were done
- `${PHASE_DIR}/execution.log.md` — how they were done, discoveries
- The actual source files changed (from tasks table)
- The spec and plan for broader context

Identify:
- **Key modules/classes/functions** introduced or modified
- **Core behaviors** the phase delivers
- **Interesting edge cases** discovered during implementation
- **Data flow** — what goes in, what comes out, what mutates

### 4) Write the Worked Example

The script follows a strict **section-based structure**. Each section is a self-contained narrative beat: a block comment explaining what's about to happen, code that does it, and print statements showing the result.

**Script anatomy:**

```
┌─────────────────────────────────────────────────┐
│  Docstring header:                              │
│  - Title: what this demonstrates                │
│  - 2-3 sentences on what you'll see when run    │
│  - Run command (copy-pasteable)                 │
├─────────────────────────────────────────────────┤
│  Imports from real implementation               │
│  (relative paths back to src/)                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  # ──── separator with section title ────       │
│  # Narrative: 2-4 sentences, tour-guide voice.  │
│  # What's about to happen and why it matters.   │
│  # ────────────────────────────────────────      │
│  code that does the thing                       │
│  print("→ ...")  # labeled output               │
│                                                 │
│  ... repeat for 5-8 sections ...                │
│                                                 │
│  # ──── Done ────                               │
│  print("✓ summary of what we proved")           │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Section separator format** — use a horizontal rule with the section number and title:

```python
# ──────────────────────────────────────────────────────────────────────
# 3. Clean Environment Construction
#
# When SetupManager shells out to an installer, it strips environment
# variables that could interfere with bash. Let's see exactly which
# vars get filtered from our current environment.
# ──────────────────────────────────────────────────────────────────────
```

**Print output format** — use `→` for observations, `✓`/`✗` for pass/fail:

```python
print("━━━ Section 3: Environment Sanitization ━━━")
print(f"→ Vars stripped: {list(problematic_vars)}")
print(f"→ Currently set in YOUR env: none — clean!")
```

### 5) Script Principles

**DO:**
- Import and call the **real implementation** — `from setup_manager import SetupManager`
- Use **narrative blocks** between code sections (block comments, 2-4 sentences, telling the story of what's about to happen and why it matters)
- Print **labeled output** at each step so the terminal output alone tells the story
- Use **`━━━ Section N: Title ━━━`** headers in print output to visually separate sections
- Keep it **short** — 80-150 lines is the sweet spot, 5-8 sections
- Make it **self-contained** — one file, minimal setup, runnable with a single command
- Use **realistic but simple data** — real-shaped inputs, not `foo/bar/baz`
- Include a **run command** in the file header docstring
- Wire up imports relative to the repo so the script works from its location
- Construct **real instances** from the implementation — show real objects, real data structures, real return values

**DON'T:**
- Mock or stub — use real code paths
- Test every edge case — that's what tests are for
- Comment obvious lines — let the code speak
- Include error handling boilerplate unless that's what the phase built
- Make it dependent on external services or databases (seed inline if needed)
- Actually trigger side effects (installs, writes to disk) — exercise the logic without the blast radius

### 6) Narrative Style Guide

The narrative blocks between code sections should read like a **tour guide** — conversational, direct, pointing out what to watch for:

```python
# ──────────────────────────────────────────────────────────────────────
# 2. Installer Discovery & Dependency Order
#
# get_installers() returns scripts from install/ in a carefully specified
# order — Rust before code2prompt (which needs cargo), fs2 before agents
# (which configures MCP servers that reference fs2). Any installers not
# in the explicit list get appended at the end.
# ──────────────────────────────────────────────────────────────────────

installers = manager.get_installers()

print("━━━ Section 2: Installer Discovery ━━━")
print(f"→ Found {len(installers)} installers in dependency order:\n")
for i, inst in enumerate(installers, 1):
    print(f"   {i:2d}. {inst.name}")
```

**Tone**: Conversational, direct, second-person ("let's see", "notice how", "watch what happens"). Not academic. Not javadoc.

**Length**: 2-4 sentences per narrative block. Enough to set context, not so much that you skip reading it.

### 7) Write the Companion Walkthrough

For every worked example script, generate a **companion `.walkthrough.md`** that provides visual context using mermaid diagrams. This is the "read before or alongside" document — it maps the terrain so the script makes sense on first contact.

**File naming**: Same stem as the script with `.walkthrough.md` suffix:
- `worked-example.py` → `worked-example.walkthrough.md`
- `worked-example-routing.ts` → `worked-example-routing.walkthrough.md`

**Walkthrough structure:**

```markdown
# Worked Example Walkthrough: [Title]

> **Script**: [`worked-example.py`](./worked-example.py)
> **Run**: `uv run python examples/worked-example.py`
> **Phase**: Phase N: [Title]

## What This Demonstrates

[2-3 sentences — same scope as the script header but pitched at a reader
who hasn't run it yet]

---

## High-Level Flow

[Mermaid flowchart showing the overall process the example walks through]

---

## Section-by-Section

### 1. [Section Title]

[1-2 paragraph explanation with more depth than the script's inline comments]

[Mermaid diagram — pick the type that best fits this section]

**What to watch in output**: [What to look for when running the script]

---

### 2. [Section Title]
...

---

## Key Takeaways

| Concept | Why It Matters |
|---------|---------------|
| ... | ... |
```

**Diagram selection guide** — pick the mermaid type that best explains each section:

| Use When | Diagram Type | Example |
|----------|-------------|---------|
| Showing a process or decision path | `flowchart` | Init logic, mode branching |
| Showing interactions between components | `sequenceDiagram` | API calls, env construction, request/response |
| Showing object lifecycles or modes | `stateDiagram-v2` | State machines, mode transitions |
| Showing data structures | `classDiagram` | Dataclasses, interfaces, schemas |
| Showing dependencies or relationships | `graph LR/TD` | Install order, module dependencies |
| Showing timeline of events | `sequenceDiagram` | Build pipeline, request lifecycle |

**Diagram principles:**
- **One diagram per section** (not every section needs one — skip if it adds nothing)
- **Keep diagrams small** — 5-10 nodes max, readable without zooming
- **Label edges** — show what flows between nodes, not just connections
- **Use styling sparingly** — `fill` colors to highlight the interesting node, not to decorate

**Walkthrough tone**: Slightly more expansive than the script comments. The script is terse by design (you're reading code); the walkthrough has room to explain *why* things work this way, what the alternatives were, and what to look for when debugging.

### 8) Create README

If multiple example files are created, generate a brief `README.md`:

```markdown
# Worked Examples — Phase N: [Title]

Run these to see what this phase built, step by step.

## Files

| Example | Demonstrates | Run |
|---------|-------------|-----|
| `worked-example-routing.ts` | Route matching and param extraction | `npx tsx examples/worked-example-routing.ts` |
| `worked-example-middleware.ts` | Middleware chain execution | `npx tsx examples/worked-example-middleware.ts` |

## Prerequisites

[Any setup needed — npm install, build step, etc.]
```

For a single file, embed the run command in the script's header docstring instead.

### 9) Verify It Runs

**Run the example script** and confirm:
- It executes without errors
- Output matches the narrative (expected print statements appear)
- The story is coherent when reading the terminal output alone

If it fails, fix the example (not the implementation). The example must work against the real code as-is.

### 10) Output Summary

```
✅ Worked example created:
   ${PHASE_DIR}/examples/worked-example.py
   ${PHASE_DIR}/examples/worked-example.walkthrough.md

   Run: uv run docs/plans/003-feature/tasks/phase-1-core/examples/worked-example.py

   Demonstrates:
   • SetupManager initialization and OS detection
   • Installer discovery in dependency order
   • Environment sanitization for subprocess isolation
   • InstallResult data structure and version tracking

   Script: 130 lines  |  7 sections  |  22 print statements
   Walkthrough: 5 diagrams (2 flowchart, 1 sequence, 1 class, 1 state)
```

## Reference Example

Here is a complete worked example from this repository that demonstrates the style, structure, and tone. Use this as the gold standard when generating new examples:

```python
#!/usr/bin/env python3
"""
Worked Example: SetupManager — How the Tools Repository Bootstraps Itself
==========================================================================

Run:  uv run python examples/worked-example-setup-manager.py

This walks through the SetupManager lifecycle step by step, showing how it
detects your OS, resolves installers in dependency order, builds clean
subprocess environments, and tracks results — all without actually running
any installers. You'll see the real objects, real logic, real data structures.
"""

import sys
from pathlib import Path

# Wire up imports from the repo root so we use the real implementation.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from setup_manager import SetupManager, InstallResult

# ──────────────────────────────────────────────────────────────────────
# 1. Creating a SetupManager in "dev mode"
#
# When you pass resource_root, the manager treats that path as the tools
# repo — useful for development and for this demo. Without it, it would
# resolve paths relative to the installed package location.
# ──────────────────────────────────────────────────────────────────────

repo_root = Path(__file__).resolve().parent.parent
manager = SetupManager(resource_root=repo_root)

print("━━━ Section 1: Initialization ━━━")
print(f"→ script_dir:    {manager.script_dir}")
print(f"→ scripts_path:  {manager.scripts_path}")
print(f"→ install_path:  {manager.install_path}")
print(f"→ os_type:       {manager.os_type}")
print(f"→ shell_config:  {manager.shell_config}")
print()

# ──────────────────────────────────────────────────────────────────────
# 2. Installer Discovery & Dependency Order
#
# get_installers() returns scripts from install/ in a carefully specified
# order — Rust before code2prompt (which needs cargo), fs2 before agents
# (which configures MCP servers that reference fs2), etc. Any installers
# not in the explicit list get appended at the end.
# ──────────────────────────────────────────────────────────────────────

installers = manager.get_installers()

print("━━━ Section 2: Installer Discovery ━━━")
print(f"→ Found {len(installers)} installers in dependency order:\n")
for i, inst in enumerate(installers, 1):
    print(f"   {i:2d}. {inst.name}")
print()

# ──────────────────────────────────────────────────────────────────────
# 3. Prerequisites Check
#
# A simple gate: does the scripts/ directory exist? This catches cases
# where the repo is incomplete or the path is misconfigured.
# ──────────────────────────────────────────────────────────────────────

prereqs_ok = manager.check_prerequisites()

print("━━━ Section 3: Prerequisites ━━━")
print(f"→ scripts/ exists: {manager.scripts_path.exists()}")
print(f"→ prerequisites met: {prereqs_ok}")
print()

# ──────────────────────────────────────────────────────────────────────
# 4. Clean Environment Construction
#
# When SetupManager shells out to an installer, it strips environment
# variables that could interfere with bash (BASH_ENV, ENV, etc.) and
# wraps scripts in `bash --noprofile --norc -p` for isolation. Let's
# see exactly which vars get filtered out from our current environment.
# ──────────────────────────────────────────────────────────────────────

import os

problematic_vars = {"BASH_ENV", "ENV", "PROMPT_COMMAND", "CDPATH", "ZDOTDIR"}
found_problematic = {k: v for k, v in os.environ.items()
                     if k in problematic_vars or k.startswith("BASH_FUNC_")}

print("━━━ Section 4: Environment Sanitization ━━━")
print(f"→ Vars that would be stripped: {list(problematic_vars)}")
if found_problematic:
    print(f"→ Currently set in YOUR env (would be removed):")
    for k, v in found_problematic.items():
        print(f"     {k} = {v[:60]}{'...' if len(v) > 60 else ''}")
else:
    print(f"→ None of these are set in your current environment — clean!")
print()

# ──────────────────────────────────────────────────────────────────────
# 5. InstallResult — The Data Structure
#
# Each installer produces an InstallResult dataclass capturing success,
# timing, output, and optional version tracking. Here's what one looks
# like with realistic data.
# ──────────────────────────────────────────────────────────────────────

example_result = InstallResult(
    name="claude-code",
    success=True,
    message="Successfully installed claude-code",
    output="Claude Code is already installed.\nVersion: 2.0.8",
    error="",
    duration=1.34,
    version_before="2.0.7",
    version_after="2.0.8",
)

print("━━━ Section 5: InstallResult Structure ━━━")
print(f"→ name:           {example_result.name}")
print(f"→ success:        {example_result.success}")
print(f"→ duration:       {example_result.duration:.2f}s")
print(f"→ version_before: {example_result.version_before}")
print(f"→ version_after:  {example_result.version_after}")
print(f"→ upgraded:       {example_result.version_before != example_result.version_after}")
print()

# ──────────────────────────────────────────────────────────────────────
# 6. Flags & Modes
#
# The manager supports several runtime modes controlled by flags. These
# change which installers run and what arguments they receive. Let's see
# how local-commands-only mode narrows the installer list.
# ──────────────────────────────────────────────────────────────────────

local_manager = SetupManager(resource_root=repo_root)
local_manager.commands_local = "claude,ghcp"
local_manager.local_dir = "/tmp/demo-project"

is_local = bool(local_manager.commands_local)
agents_path = local_manager.install_path / "agents.sh"

print("━━━ Section 6: Local Commands Mode ━━━")
print(f"→ commands_local: {local_manager.commands_local}")
print(f"→ local_dir:      {local_manager.local_dir}")
print(f"→ is local mode:  {is_local}")
print(f"→ would only run: {agents_path.name} (skips {len(installers) - 1} other installers)")
print()

# ──────────────────────────────────────────────────────────────────────
# 7. Summary Table (simulated)
#
# After all installers run, show_summary() renders a rich table with
# results. Let's simulate a few results and show what the data looks
# like before it hits the rich renderer.
# ──────────────────────────────────────────────────────────────────────

simulated_results = [
    InstallResult("rust", True, "Already installed", "", "", 0.5),
    InstallResult("code2prompt", True, "Installed via cargo", "", "", 12.3),
    InstallResult("agents", True, "Commands synced", "", "", 2.1),
    InstallResult("fs2", False, "pip install failed", "", "Permission denied", 3.7),
]

print("━━━ Section 7: Results Summary ━━━")
print(f"→ {sum(1 for r in simulated_results if r.success)} succeeded, "
      f"{sum(1 for r in simulated_results if not r.success)} failed, "
      f"total {sum(r.duration for r in simulated_results):.1f}s\n")
for r in simulated_results:
    status = "✓" if r.success else "✗"
    print(f"   {status} {r.name:<16} {r.duration:>6.1f}s  {r.message}")
print()

# ──────────────────────────────────────────────────────────────────────

print("━━━ Done ━━━")
print("✓ Walked through SetupManager lifecycle without running any installers")
print("✓ All objects above are real instances from the actual implementation")
```

## Fallback: No Plan Context

If invoked outside a plan context (no `--plan`, no detectable plan):

1. **Prompt** the user: "No plan context detected. Where should I create the example?"
2. Accept a directory path
3. **Prompt** what to demonstrate: "What implementation should this example exercise?"
4. Proceed with steps 4-8 using the provided context

This makes the command usable for ad-hoc "show me how this works" requests too.

## Anti-Patterns

- ❌ Generating a test suite — this is an **explanatory script**, not tests
- ❌ Mocking dependencies — use the **real code**
- ❌ Writing a wall of comments — narrative blocks are **2-4 sentences**
- ❌ Covering every feature — pick the **interesting** parts, not all parts
- ❌ Abstract examples — use **realistic data** that looks like what users would see
- ❌ Creating the example without running it — **verify it executes**
- ❌ Actually triggering side effects — exercise logic without blast radius (don't install, don't write to disk, don't hit APIs)
- ❌ Skipping the walkthrough — the `.walkthrough.md` is **not optional**
- ❌ Diagrams without purpose — only add a diagram when it clarifies something the prose alone can't

## Integration

- Runs after `plan-6-implement-phase` (or `plan-6a-update-progress`)
- Complements `plan-7-code-review` — review checks correctness, this builds understanding
- Can reference `plan-2c-workshop` documents for context on what was designed
- Works standalone for any "show me how this works" request

## Success Criteria

✅ Script runs without errors
✅ Output tells a coherent story when read top-to-bottom
✅ Uses real implementation imports (no mocks)
✅ Narrative blocks are concise (2-4 sentences each)
✅ Script is short enough to step through in a debugger (80-150 lines, 5-8 sections)
✅ A developer unfamiliar with the phase can read it and understand what was built
✅ No side effects — exercises logic without triggering installs, writes, or API calls
✅ Companion `.walkthrough.md` exists alongside every script
✅ Walkthrough uses mermaid diagrams tactically (flowchart, sequence, state, class — whichever fits)
✅ Walkthrough has a "What to watch in output" note per section connecting it to the script's print output
