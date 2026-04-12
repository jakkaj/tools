# Workshop: LLM-to-LLM Context Transfer Design

> **Topic**: How to design a handover prompt that maximizes receiving-agent success when resuming work across session boundaries.
>
> **Artifact under review**: `agents/v2-commands/util-0-v2-handover.md`
>
> **Research basis**: Deep research via Perplexity covering A2A protocol, TALE framework, Factory.ai context compression evaluation, XTrace structured memory, CrewAI/OpenDevin handoff patterns, and academic work on prompt compression and entity preservation.

---

## 1. The Core Tension

A handover document must serve two masters simultaneously:

1. **Information density** — fit maximal decision-critical information into ≤1400 tokens
2. **Parseability** — the receiving agent must *reliably extract and act on* every piece of information without hallucinating gaps

Our current HOVR/2 format is strong on (1) — it's extremely dense. But research reveals several systematic failure modes where receiving agents lose critical context despite it being "technically present" in the handover.

---

## 2. What the Research Says (Key Findings)

### 2.1 The Top Failure Mode: Decision Rationale Loss

> "Receiving agents then lack the decision logic needed to extrapolate to new situations or course-correct if they encounter evidence suggesting the decision was suboptimal."

Our current `decisions` section captures **what** was decided and **what it affects**, but not **why**. When a receiving agent hits a fork in the road, it has no way to evaluate whether the prior decision still applies to new circumstances.

**Example of the gap:**
```
# Current — tells WHAT, not WHY
decisions:{
  adrs:[["ADR-0001","domain types above repo","services/routers","realtime"]],
  other:[["DEC-ephemeral","mint per Start click","stateless svc call"]]
}

# Improved — adds rationale
decisions:{
  adrs:[["ADR-0001","domain types above repo","services/routers","realtime","prevents circular imports"]],
  other:[["DEC-ephemeral","mint per Start click","stateless svc call","avoids key caching security risk"]]
}
```

Cost: ~3-5 extra tokens per decision. Value: prevents the receiving agent from reversing a critical decision.

### 2.2 Missing Section: Failed Attempts

Research identifies this as *disproportionately valuable* — the section most frameworks include but most handover prompts omit. Our current prompt has no mechanism to transfer "what was tried and failed."

> "This section is often omitted from naive summarization but proves disproportionately valuable: it prevents receiving agents from repeating failed approaches."

Without this, receiving agents waste tokens and time re-exploring dead ends the prior agent already ruled out.

**Proposed section:**
```
fails:[["<approach tried>","<why it failed>","<lesson learned>"], ...≤4]
```

Position in trim order: after `risks`, before `concepts.keys` — it's more valuable than concept definitions but less critical than risk awareness.

### 2.3 Entity Preservation Is Systematically Weak

Academic research on prompt compression found that LLMs *systematically under-preserve*:
- **File paths** (often made relative or corrupted)
- **Function/class names** (paraphrased to natural language)
- **Numeric values** (dates, line numbers, counts)

Our prompt says: `"Paths: Absolute when remembered; else ?"` — this is a soft suggestion. Research shows explicit hard constraints dramatically improve preservation:

> "A prompt that includes explicit preservation constraints — 'Every date, number, and file path must appear verbatim' — significantly improves preservation of these critical information types."

**Recommendation**: Promote from soft guidance to a Hard Rule.

### 2.4 Token Budget Misallocation

The TALE (Token-Budget-Aware LLM Reasoning) framework found that LLMs are *poor at self-regulating token consumption*. Without explicit allocation guidance, they:
- Over-allocate to narrative sections (timeline, concepts)
- Under-allocate to structural sections (code, next steps)
- Cut off mid-section when hitting limits

Our current prompt has a trim order (good) but no allocation guidance (gap). The trim order says *what to drop*, but not *how much space each section should get*.

**Proposed allocation:**
```
Budget guide: intent+timeline ≈20%, code+decisions ≈35%, tasks ≈20%, next+refs ≈15%, risks+concepts+fails ≈10%
```

### 2.5 Semantic Drift Across Multi-Hop Handovers

Factory.ai's evaluation found that information *gradually disappears* across multiple compression cycles. Each new summary is "optimized independently without anchors to prior decisions."

Our prompt doesn't address this because it assumes a single handover. But in practice, agents often hand over 2-3 times in a long session. Information that survived hop 1 may not survive hop 2.

**Solution**: An `anchors` section containing facts that *must survive re-summarization*:
```
anchors:{
  immutable:["PostgreSQL chosen for JSONB support","no caching per user security req"],
  user_verbatim:["'must complete within 30 minutes'","'do not delete user data'"]
}
```

These are explicitly marked as non-compressible. They survive even when the trim order drops everything else.

### 2.6 Query-Oriented Framing (XTrace Insight)

> "Rather than asking 'What format should we use to represent all the information?', the question should be 'What queries will the receiving agent need to answer?'"

Our Two-Stage Generation instruction says:
```
Internal consolidation (silent): Do a quick chronological mental pass...
```

This frames summarization as *retrospective* (what happened). Research suggests framing it as *prospective* (what will the receiver need) produces better handovers:

```
Internal consolidation (silent): Think about what the receiving agent will need to DO.
  Ask yourself: "What 5 questions will the next agent ask in their first 30 seconds?"
  Then: recover the facts, decisions, code state, and blockers that answer those questions.
```

---

## 3. Gap Analysis: Current vs Research-Recommended

| Capability | Current HOVR/2 | Research Best Practice | Gap |
|-----------|---------------|----------------------|-----|
| Decision rationale | ❌ What only | ✅ What + Why | **Add rationale field** |
| Failed attempts | ❌ Missing | ✅ Top-4 with lessons | **Add `fails` section** |
| Entity preservation | ⚠️ Soft guidance | ✅ Hard constraint | **Harden to Hard Rule** |
| Token allocation | ⚠️ Trim order only | ✅ Explicit % allocation | **Add budget guide** |
| Anti-drift anchoring | ❌ Missing | ✅ Immutable facts section | **Add `anchors` section** |
| Query-oriented framing | ❌ Chronological | ✅ Receiver-need-oriented | **Reframe Stage 1** |
| Receiver assumptions | ❌ Missing | ⚠️ Nice-to-have (A2A) | Low priority |

---

## 4. Proposed Schema Changes (Compact Format)

### 4.1 New sections to add

```
# After risks, before next
fails:[["<approach>","<why failed>","<lesson>"], ...≤4]

# After next, before refs (or as part of intent)
anchors:{
  immutable:["<fact that must survive re-summarization>", ...≤5],
  user_verbatim:["<exact user quote>", ...≤3]
}
```

### 4.2 Modified sections

```diff
# decisions — add rationale column
- adrs:[["ADR-####","<constraint>", "affects <area>", "<domain>"], ...≤4]
+ adrs:[["ADR-####","<constraint>", "affects <area>", "<domain>", "<why ≤8w>"], ...≤4]

- other:[["<id>","<decision>", "<impact>"], ...≤6]
+ other:[["<id>","<decision>", "<impact>", "<why ≤8w>"], ...≤6]
```

### 4.3 New Hard Rules

```
Entity preservation: File paths, function names, task IDs, decision IDs, and CLI commands
MUST be preserved VERBATIM. Never paraphrase — copy exactly or write "?".
```

### 4.4 Updated Two-Stage Generation

```
Internal consolidation (silent):
  1. Think forward: "What 5 questions will the next agent ask in their first 30 seconds?"
  2. Then: recover user requests (quote key lines), decisions+rationale, code state,
     failed attempts, and blockers that answer those questions.
  3. Identify ≤5 immutable facts and ≤3 verbatim user constraints for the anchors section.
```

### 4.5 Updated Trim Order

```
Trim Order: code.hot → code.domain_dirs → fails → risks → concepts.keys →
  decisions.other → tasks.pend → code.files → tests.notes → refs.paths → anchors.immutable

Never trim: m, intent.primary, timeline.just_completed, timeline.current,
  next (including next.tasks_file), m.domain (when present), anchors.user_verbatim
```

### 4.6 Budget Allocation Guide (new)

```
Budget guide (approximate):
  intent + timeline: ~20%
  code + decisions: ~35%
  tasks: ~20%
  next + refs: ~15%
  risks + concepts + fails + anchors: ~10%
```

---

## 5. Token Impact Assessment

| Change | Estimated token cost | Value |
|--------|---------------------|-------|
| Decision rationale (+8w × ~8 decisions) | +30-50 tokens | Prevents decision reversals |
| `fails` section (4 entries) | +40-60 tokens | Prevents dead-end re-exploration |
| `anchors` section | +30-50 tokens | Prevents multi-hop drift |
| Budget allocation guide (in prompt) | +25 tokens | Better token distribution |
| Entity hard rule (in prompt) | +15 tokens | Better path/name preservation |

**Total prompt growth**: ~40 tokens in the instruction prompt itself.
**Total output growth**: ~100-160 tokens in the generated handover (from 1400 cap to ~1500-1560 cap, still under the 1600 hard stop).

**Recommendation**: Keep the default `--max` at 1400 but note that the richer schema may push typical outputs to ~1500. The trim order handles overflow gracefully.

---

## 6. What NOT to Change

Research also suggested several things that our prompt already handles well:

1. **Structured format over prose** — HOVR/2 is already highly structured ✅
2. **Deterministic ordering** — natural sort, consistent keys ✅
3. **Multiple output formats** — compact/lean/json covers all needs ✅
4. **Verbatim user quotes in intent** — already present ✅
5. **Pointer-not-payload philosophy** — `?` with refs is exactly right ✅
6. **Token cap with trim order** — close to TALE best practice ✅

---

## 7. Implementation Approach

This is a single-file change to `agents/v2-commands/util-0-v2-handover.md`:

1. Add `fails` section to compact schema (after `risks`)
2. Add `anchors` section to compact schema (after `next`)
3. Extend decision tuples with rationale field
4. Add entity preservation Hard Rule
5. Reframe Two-Stage Generation step 1
6. Add budget allocation guide
7. Update Trim Order to include new sections
8. Mirror all changes to lean format sections
9. Update the example to demonstrate new sections
10. Update the Drop-in System Prompt to include new instructions

No changes needed to:
- Other commands (no dependencies)
- Install scripts (same file, same path)
- Sync scripts (already handles the file)

---

## 8. Research Sources

- **Google A2A Protocol** — Agent interoperability, capability negotiation, structured message parts
- **TALE Framework** — Token-budget-aware LLM reasoning, explicit budget allocation
- **Factory.ai Evaluation** — Structured vs naive summarization, probe-based quality testing, semantic drift across compression cycles
- **XTrace** — Query-oriented memory retrieval vs context dumps
- **CrewAI** — Boundary-based context passing, role-specific delegation
- **OpenDevin** — State persistence, recall actions, task hierarchy transfer
- **Prompt Compression Research** — Entity preservation failures, granularity control, verbatim constraints
- **ReSum Framework** — Periodic summarization with credit assignment for unbounded exploration
- **Conversation Tree Architecture** — Hierarchical context with parent/sibling pointers
