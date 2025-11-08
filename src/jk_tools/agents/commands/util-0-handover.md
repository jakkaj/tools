---
description: Generate a comprehensive handover document for LLM agent continuity.
---

Please deep think / ultrathink as this is a complex task.

util-0-compact-handover

A conversation+code compaction handover that another LLM can paste in and resume immediately.

CLI
/util-0-compact-handover
  --plan "<path>"                  # optional; used only for pointers/anchors
  --phase "<Phase N: Title>"       # optional; defaults to current/latest
  --format "compact|lean|json"     # default: compact
  --max 1400                       # token cap (default 1400; hard stop 1600)

Hard Rules

Memory only: Do not open files or call tools. Summarize from session memory.

No scaffolding noise: No “Read…”, “Working…”, diffs, mermaid, stack traces, or step logs.

Pointers, not payloads: If a detail isn’t remembered, write ? and add a pointer in Refs (plan §/dossier/log).

Status tokens: [ ] pending, [~] in‑progress, [x] complete, [!] blocked.

Context protection: Obey strict caps; keep strings short (≤12 words) and lists Top‑N only.

Deterministic: Natural sort for IDs; consistent key order.

Two‑Stage Generation (single response)

Internal consolidation (silent): Do a quick chronological mental pass of the conversation/session to recover: user’s explicit requests (quote key lines), your actions, decisions, code touchpoints, and current focus.

Emit summary: Output one artifact in the requested format using the schema below. If near --max, drop lowest‑priority sections in the Trim Order.

Output Formats
A) --format compact (default; tight and skimmable)

HOVR/2 microformat with short keys and capped lists. One fenced block; no extra text.

HOVR/2
m:{ts:"<UTC>", plan:"<path or ?>", phase:"<name>", feat:"<slug or ?>", prog:"<x/y or %>"}

intent:{
  primary:"<one-liner>",
  quotes:["<verbatim short quote>", ...≤2],
  scope:["<in/out of scope>", ...≤3]
}

timeline:{
  just_completed:"<last task/action finished with ID>",
  current:"<what you were doing right before handover>",
  last_actions:["<past action or decision>", ...≤4]
}

concepts:{keys:["<key technical concept>", ...≤6]}

code:{
  files:["<abs path or ?>", ...≤8],
  hot:["<path>@+n/-m or 'hot'>", ...≤6]
}

decisions:{
  adrs:[["ADR-####","<constraint>", "affects <area>"], ...≤4],
  other:[["<id>","<decision>", "<impact>"], ...≤6]
}

tasks:{
  done:[ids…≤8], ip:[ids…≤5], pend:[ids…≤10], blk:[["<id>","<reason>"], ...≤3],
  critdeps:[["T033","T032"], ...≤5]
}

tests:{unit:"pass|fail|mixed|?", integ:"pass|fail|mixed|?", cov:"<%|?>", notes:"<≤80 chars>"}

risks:[["<risk>", "<mitigation>", "<watch>"], ...≤5]

next:{
  task:"<id>",
  tasks_file:"<absolute-path-to-tasks.md>",
  why:"<one-liner>",
  validate:["<success criterion>", ...≤3],
  cmd:"/plan-6-implement-phase --phase \"<phase>\" --plan \"<path>\" --task \"<id>\""
}

refs:{plan:"<path> §<anchor|?>", tasks_file:"<absolute-path-to-tasks.md|?>", log:"<.../execution.log.md|?>", paths:["<key dir/file>", ...≤5]}


Trim Order (when hitting --max): code.hot → risks → concepts.keys → decisions.other → tasks.pend → code.files → tests.notes → refs.paths.
Never trim: m, intent.primary, timeline.just_completed, timeline.current, next (including next.tasks_file).

B) --format lean (readable Markdown, still tight)
# Handover
Plan: <path> • Phase: <name> • Feature: <slug> • Progress: <x/y or %> • Generated: <UTC ISO>

## 1) Primary Intent
- Summary: <one‑liner>
- Quotes: “<short verbatim>”; “<short verbatim>”
- Scope: <in/out of scope bullets, ≤3>

## 2) Timeline (Most Recent First)
- Just completed: <last task/action finished with ID>
- Current focus: <what you were doing right before handover>
- Recent actions: <≤4 bullets; actions/decisions taken>

## 3) Key Technical Concepts (≤6)
- <concept> — <why it matters>

## 4) Code Touchpoints
- Files (≤8): <abs path or ?>
- Hot changes (≤6): <path>@+n/‑m or “hot”

## 5) Decisions & ADRs
- ADR‑#### — <constraint> — Affects: <area> (≤4)
- Other decisions (≤6): <id> — <decision> — Impact: <≤12 words>

## 6) Tasks Snapshot
- Done (≤8): <ids…>
- In‑Progress (≤5): <ids…>
- Pending (≤10): <ids…>
- Blocked (≤3): <id — reason>
- Critical deps (≤5): T033 ← T032; T037 ← T035 + T036

## 7) Tests
- Unit: <pass|fail|mixed|?> • Integration: <pass|fail|mixed|?> • Coverage: <value or ?>
- Notes: <≤80 chars>

## 8) Risks (≤5)
- <risk> — Mitigation: <short> — Watch: <signal>

## 9) Next Steps
- Immediate: <task‑id> — <why>
  - Tasks file: <absolute-path-to-tasks.md>
  - Validation: <≤3 criteria>
  - Resume: `/plan-6-implement-phase --phase "<phase>" --plan "<path>" --task "<id>"`
- Then (≤4): T0xx — <one‑liner> (deps: <ids>)

## 10) References
- Plan: <path> §<anchor|?>
- Tasks file: <absolute-path-to-tasks.md|?>
- Phase log: <.../execution.log.md|?>
- Paths (≤5): <key files/dirs>

C) --format json (expanded keys; mirrors compact/lean)

Keys: meta, intent, timeline, concepts, code, decisions, tasks, tests, risks, next, refs.
Values follow the same caps and semantics as compact.

Size & Priority Policy

Global cap: --max (default 1400; hard stop 1600).

Section caps: Concepts ≤6; Files ≤8; Hot ≤6; Decisions(other) ≤6; ADRs ≤4; Done ≤8; In‑Progress ≤5; Pending ≤10; Blocked ≤3; CritDeps ≤5; Risks ≤5; Then ≤4.

Strings: Prefer ≤12 words. Use IDs and pointers over prose.

Required fields even when trimmed: meta, intent.primary, timeline.current, next (task/why/validate/cmd).

Normalization

IDs: T###, ST###, ADR‑####.

Paths: Absolute when remembered; else ?.

Times: UTC ISO (YYYY‑MM‑DDThh:mm:ssZ).

Booleans as status words: pass|fail|mixed|?.

Quotes: Keep verbatim user quotes short to anchor intent.

Example (--format compact)

(Illustrative; replace with session memory; use ? if unknown.)

HOVR/2
m:{ts:"2025-11-07T23:18:00Z",plan:"/workspaces/.../realtime-chatbot-plan.md",phase:"Phase 5: WebRTC",feat:"realtime-chatbot",prog:"4/9"}

intent:{
  primary:"Enable browser↔Azure WebRTC voice with ephemeral creds",
  quotes:["“get webrtc working end-to-end”","“no key caching”"],
  scope:["POC OK","manual tests acceptable","keep SDK types below repo"]
}

timeline:{
  just_completed:"ST008 pytest infra documented and green",
  current:"implement RealtimeService (T032) before wiring router",
  last_actions:["set ADR‑0001 repo isolation","outlined router endpoints","configured telemetry endpoint"]
}

concepts:{keys:["ephemeral key mint","region-scoped webrtc URL","repo pattern isolation","TDD cycles","telemetry endpoint","no caching"]}

code:{
  files:["src/backend/app/services/realtime_service.py","src/backend/app/routers/realtime.py","src/backend/app/main.py","tests/unit/test_realtime_service.py","tests/integration/test_realtime.py","src/ui/components/webrtc_client.html"],
  hot:["src/backend/app/main.py@?","tests/unit/test_realtime_service.py@?"]
}

decisions:{
  adrs:[["ADR-0001","domain types above repo","services/routers"]],
  other:[["DEC-telemetry","/telemetry collects client stats","observability"],["DEC-ephemeral","mint per Start click","stateless svc call"]]
}

tasks:{
  done:["ST008"], ip:[], pend:["T032","T033","T034","T035","T036"], blk:[],
  critdeps:[["T033","T032"],["T037","T035","T036"]]
}

tests:{unit:"mixed", integ:"pass", cov:"~50%", notes:"RED→GREEN expected after T032"}

risks:[["mic permission denial","UI prompt/handle NotAllowedError","browser console"],["region mismatch","derive from AZURE_OPENAI_REGION","403/connect-failed"]] 

next:{
  task:"T032",
  tasks_file:"/workspaces/.../tasks/phase-5/tasks.md",
  why:"service layer needed before router",
  validate:["unit tests green","returns domain type only","no caching"],
  cmd:"/plan-6-implement-phase --phase \"Phase 5: WebRTC\" --plan \"/workspaces/.../realtime-chatbot-plan.md\" --task \"T032\""
}

refs:{plan:"/workspaces/.../realtime-chatbot-plan.md § Phase 5", tasks_file:"/workspaces/.../tasks/phase-5/tasks.md", log:"/workspaces/.../tasks/phase-5/execution.log.md", paths:["src/backend/app/","tests/","src/ui/components/"]}

Drop‑in System Prompt
You are a **compact handover generator** for agent continuity.

Constraints:
- Summarize from current-session memory only. Do NOT read files or call tools.
- Respect a hard token cap of `--max` (default 1400; hard stop 1600).
- If unsure, output "?" and add a pointer in Refs rather than guessing.
- Output exactly one artifact in the requested format: compact (default), lean, or json.
- No scaffolding/logs/diffs/mermaid; keep strings ≤12 words; Top‑N caps per section.

Method:
1) Internally review the session chronologically to recall: explicit user requests (quote briefly), your actions, decisions, code touchpoints, state, just completed work, and current focus.
2) Emit the summary using the chosen format and schema. Apply Trim Order when near the cap: code.hot → risks → concepts.keys → decisions.other → tasks.pend → code.files → tests.notes → refs.paths.
3) Never trim: meta, primary intent, timeline.just_completed, timeline.current, next (including next.tasks_file).

Content (by format):
- **compact**: Emit HOVR/2 block with sections: m, intent, timeline, concepts, code, decisions, tasks, tests, risks, next, refs.
- **lean**: Emit Markdown with 10 sections mirroring the compact data.
- **json**: Emit JSON with full-word keys mirroring the compact data.

