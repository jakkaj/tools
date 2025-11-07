---
description: Generate a comprehensive handover document for LLM agent continuity.
---

Please deep think / ultrathink as this is a complex task.

# util-0-handover (v2 • “Quick Handover”)

Goal: Emit a minimal, high‑signal handover so another coding agent can resume instantly.
Hard rules:

Do not open/read files or spawn subagents; summarize only from current session memory.

Output within ≤ 800 tokens (target 400–600).

No “working…” logs, no “Read …” lines, no mermaid, no diffs.

If a detail isn’t in memory, leave a stub and point to the plan path/section instead of re-reading.

CLI
/util-0-handover
  --plan "<path>"              # optional; path to current plan doc (for references only)
  --phase "<Phase N: Title>"   # optional; if omitted, treat as current/latest
  --format "mini|md|json"      # default: mini (compact microformat)
  --max 800                    # hard token cap; default 800


mini is the default compact microformat (see schema). md = short markdown; json = readable JSON (same fields).

Output: HOVR/1 microformat (mini)

A single block with short keys. Keep lines short; lists are top‑N (≤5). Values should be terse phrases, IDs, or paths.

HOVR/1
m:{ts:"<UTC>", plan:"<abs path>", phase:"<name>", prog:"<% or x/y>", feat:"<slug>"}
last:{done:"<task-id>: <one-liner>", log:"<ts>: <one-liner>"}
next:{task:"<task-id>", why:"<one-liner>", validate:"<bullet-ish>", cmd:"<resume cmd>"}
st:{
  dec:[["<id>","<decision>","<impact>"], ...≤5]
  blk:[["<id>","<reason>","<mitigation>"], ...≤3]
  tsk:{d:[ids≤8], ip:[ids≤5], p:[ids≤8], b:[ids≤5]}
  chg:["<path>@+n/-m", ...≤8]
  files:["<abs path>", ...≤8]        # if chg counts unknown, list hot files instead
}
tst:{unit:"p/f", integ:"p/f", cov:"<% or unknown>", notes:"<≤80 chars>"}
risk:["<short item>", ...≤5]
ref:{plan:"<§/anchors to check>", tasks:"<phase dossier path>", log:"<log path if any>"}


Notes

Prefer IDs over prose (e.g., T032, ADR-0001, ST004).

If a field is unknown, supply "?" or an empty list []—do not fetch.

Use absolute paths only when already known in memory.

cmd should be a single ready-to-run resume command (no fenced code block in mini).

Output: Markdown (md)

When --format md, emit a five-section, single-screen doc. Headings only; no nested tables.

# Handover (Quick)
- Plan: <path> • Phase: <name> • Progress: <x/y or %> • Feature: <slug>
- Last: <task-id one-liner> • Log: <ts summary>
- Next: <task-id> — Why: <one-liner> — Validate: <criteria> — Cmd: <one-liner>

## Decisions (≤5)
- <id>: <decision> — Impact: <impact>

## Status
- Done: <ids…>
- In-Progress: <ids…>
- Pending: <ids…>
- Blocked: <id: reason → mitigation> (≤3)

## Changes / Hot Files (≤8)
- <path> (@+n/-m or “hot”)

## Tests / Risks / Refs
- Tests: unit <p/f>, integ <p/f>, cov <value>, notes <≤80 chars>
- Risks (≤5): <one-liners>
- Refs: plan § to re-open, dossier path, log path

Output: JSON (json)

Readable JSON mirror of the mini fields (expand keys to full words). Keep values short; same caps and limits.

Generation Algorithm (single pass)

Assemble from memory

Pull: current plan path (if provided), current phase name, last task touched, immediate next task, the top decisions/risk/blockers you remember, hot files/paths previously modified or referenced, quick test/coverage status if recalled, and any resume command used last time.

Trim & cap

Enforce list caps; shorten strings to phrases; drop examples/code; no diffs.

If any critical value is missing, write "?" and add a ref.plan pointer like § Progress/Phase N or the phase dossier path.

Emit exactly one artifact in the requested format. No auxiliary chatter, no step logs.

Quality & Size Guards

Token budget: Stop adding items once you hit ≈90% of --max. Prefer dropping lowest-priority sections: chg → files → risk → tst (in that order).

Priority order: m, next, last, st.dec, st.tsk, st.blk, ref, then the rest.

Deterministic order: Sort IDs naturally (T001…T999).

No tables in mini; no code fences except the HOVR/1 header line.

No network, no disk, no tool calls.

Example (mini)

(Illustrative only—fill from memory; use ? where unknown; keep it short.)

HOVR/1
m:{ts:"2025-11-07T22:40Z",plan:"/workspaces/.../realtime-chatbot-plan.md",phase:"Phase 5: WebRTC",prog:"4/9",feat:"realtime-chatbot"}
last:{done:"ST008: pytest infra docs",log:"2025-11-07: subtask complete"}
next:{task:"T032",why:"implement RealtimeService",validate:"tests ST004 go GREEN",cmd:`/plan-6-implement-phase --phase "Phase 5: WebRTC" --plan "/workspaces/.../realtime-chatbot-plan.md"`}
st:{dec:[["ADR-0001","repo pattern SDK isolation","affects svc/router"],["CF-01","ephemeral key per session","no caching"]],
    blk:[],tsk:{d:["ST001","ST002","ST003","ST004","ST005","ST006","ST007","ST008"],ip:[],p:["T033","T034","T035","T036","T037","T038"],b:[]},
    chg:["src/backend/app/main.py@?","src/backend/app/repos/azure_realtime_repo.py@?"],
    files:["tests/unit/test_realtime_service.py","src/backend/app/repos/types.py"]}
tst:{unit:"mixed",integ:"pass",cov:"~50%",notes:"RED→GREEN expected after T032"}
risk:["mic permission denial","region mismatch URL"]
ref:{plan:"§ Phase 5 tasks",tasks:".../tasks/phase-5/tasks.md",log:".../phase-5/001-subtask-pytest-infrastructure.execution.log.md"}

Why this fixes the problems

No I/O: Eliminates the minute‑long “read everything” phase and the verbose step logs seen in the prior handover. 

handover-2025-11-07

Hard caps + short keys: Keeps output compact and pasteable as session seed context.

Pointers over payloads: When detail is missing, the next agent opens the plan/dossier/log themselves.

Triage‑friendly: next is always prominent; decisions and task IDs are skimmable.

Drop‑in prompt (paste into your system/command definition)
You are producing a **Quick Handover** for immediate agent resumption.

Constraints:
- Summarize **only** from what you remember in this session; **do not** read files or call tools.
- Output ≤ `--max` tokens (default 800). Prefer brevity over completeness.
- Use the requested format: mini (default), md, or json.
- If a detail isn’t in memory, write "?" and add a helpful `ref.plan` pointer (section/anchor) instead of fetching.

Content (priority order):
1) meta (m): ts, plan (if provided), phase, progress, feature
2) next: task id, why, validation, single resume cmd
3) last: last completed task + one‑line log
4) state (st):
   - dec (≤5): [id, decision, impact]
   - tsk: {d (done ≤8), ip (in‑progress ≤5), p (pending ≤8), b (blocked ≤5)}
   - blk (≤3): [id, reason, mitigation]
   - chg (≤8): "<path>@+n/-m" if remembered; else drop
   - files (≤8): hot/likely paths if remembered
5) tst: unit pass/fail, integ pass/fail, coverage (short), note (≤80 chars)
6) risk (≤5): terse items
7) ref: plan section(s), dossier path, log path (pointers only)

Never print read/scan steps, stack traces, mermaid, or diffs. Output exactly one artifact 