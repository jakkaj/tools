# Workshop: Template Discovery & Distribution

**Type**: Integration Pattern
**Plan**: 015-plan-domain-system
**Created**: 2026-02-22
**Status**: Draft

**Related Documents**:
- [domain-system-design.md](./domain-system-design.md) — domain.md format definition
- [v2-command-structure.md](./v2-command-structure.md) — where v2 commands live
- [lean-plan-task-design.md](./lean-plan-task-design.md) — plan-3-v2 and plan-5-v2 design

---

## Purpose

Decide how agents discover and use domain templates (domain.md, registry.md) when creating new domains. The challenge: commands are installed as flat `.md` files to various locations (`~/.claude/commands/`, `~/.config/opencode/command/`, project-local dirs) — there's no mechanism to ship companion template files alongside them.

## Key Questions Addressed

- How do existing commands handle templates? Is there precedent?
- Should templates be external files or embedded inline in commands?
- How does the install pipeline affect the options?

---

## 1. What the Research Found

### Existing Pattern: Everything is Inline

The codebase has a **clear, consistent pattern**: command files embed all templates inline. They never reference external template files.

| Command | What It Templates | How |
|---------|------------------|-----|
| `plan-1b-specify` | Spec file (Summary, Goals, Non-Goals, Complexity, ACs, etc.) | All sections defined inline in the command's step 3 |
| `plan-0-constitution` | 4 doctrine files (constitution.md, rules.md, idioms.md, architecture.md) | Full templates embedded inline |
| `planpak.md` | Feature folder structure, classification tags, decision tree | All defined inline |

**Line 120 of plan-1b-specify.md** explicitly codifies this philosophy:
> "If `templates/spec-template.md` exists, you **may reference it** for wording, but **this command must succeed without it**."

External templates are **optional bonus context**, never a dependency.

### Install Pipeline Constraints

```
install/agents.sh installs to:
  ~/.claude/commands/           → flat .md files only
  ~/.config/opencode/command/   → flat .md files only
  ~/.codex/prompts/             → flat .md files only
  ~/.config/github-copilot/prompts/ → flat .md files (.prompt.md)
  ~/.config/github-copilot-cli/agents/ → flat .md files (.agent.md)
```

- **No directory structure** preserved — just bare command files
- **No non-command files** shipped (README and GETTING-STARTED are skipped)
- Commands work as **standalone, self-contained documents**

### What This Means

External template files (like `_template-domain.md`) would:
- ❌ Not be installed by the current pipeline
- ❌ Require pipeline changes to handle non-command files
- ❌ Break the "commands work independently" pattern
- ❌ Need a discovery mechanism that varies by install location

---

## 2. Resolution: Embed Templates Inline

**Follow the established pattern.** Domain templates go **inside the v2 commands** that create them, just like plan-1b-specify embeds the spec template and plan-0-constitution embeds the doctrine templates.

### Which Commands Create Domain Files?

| Command | Creates | Template Needed |
|---------|---------|----------------|
| `extract-domain.md` | `docs/domains/<slug>/domain.md` | domain.md template |
| `extract-domain.md` | `docs/domains/registry.md` (if first domain) | registry.md template |
| `plan-3-v2-architect.md` | `docs/domains/<slug>/domain.md` (for NEW domains) | domain.md template |
| `plan-3-v2-architect.md` | `docs/domains/registry.md` (if first domain) | registry.md template |

Both `/extract-domain` and `/plan-3-v2-architect` need to create domains. Both embed the same template inline.

### Inline Template Approach

**In `extract-domain.md`** (primary domain creator):

```markdown
## Step 4: Write Domain Files

### domain.md Template

Create `docs/domains/<slug>/domain.md` with this structure:

​```markdown
# Domain: [Name]

**Slug**: [kebab-case]
**Type**: business | infrastructure
**Created**: [ISO-8601]
**Created By**: [Plan ordinal-slug or "extracted from existing codebase"]
**Status**: active

## Purpose

[1-3 sentences: What business concept does this domain own?]

## Boundary

### Owns
- [Concept this domain is responsible for]

### Does NOT Own
- [Concept explicitly excluded — note which domain owns it]

## Contracts (Public Interface)

| Contract | Type | Consumers | Description |
|----------|------|-----------|-------------|

## Composition (Internal)

| Component | Role | Depends On |
|-----------|------|------------|

## Source Location

Primary: `[path — where files currently live]`

## History

| Plan | What Changed | Date |
|------|-------------|------|
​```

### registry.md Template

If `docs/domains/registry.md` does not exist, create it:

​```markdown
# Domain Registry

| Domain | Slug | Type | Parent | Created By | Status |
|--------|------|------|--------|------------|--------|

## Domain Types
- **business**: User-facing business capability
- **infrastructure**: Cross-cutting technical capability

## Domain Statuses
- **active**: In use, accepting changes
- **deprecated**: Being phased out
- **archived**: No longer modified
​```
```

**In `plan-3-v2-architect.md`** (creates domains for NEW entries in spec):

```markdown
### Domain Setup Task

For each NEW domain in the spec's Target Domains section:

1. Create `docs/domains/<slug>/domain.md` using the canonical format:
   [Same template as extract-domain — but brief reference, not full copy]
   
   Required sections: Purpose, Boundary (Owns/Does NOT Own),
   Contracts, Composition, Source Location, History.
   
2. Create source directory: `src/<slug>/`
3. Update `docs/domains/registry.md` (create if missing)
```

### Handling Duplication

Two commands need the same template. Options:

| Approach | Pros | Cons |
|----------|------|------|
| **Full template in extract-domain, brief reference in plan-3-v2** | extract-domain is the primary domain creator; plan-3-v2 stays lean | Slight risk of drift |
| **Full template in both** | No cross-referencing needed | Duplication, harder to maintain |
| **Full template in extract-domain, plan-3-v2 says "use /extract-domain format"** | Single source, plan-3-v2 stays lean | Cross-command dependency |

**Recommended**: Full template in `extract-domain.md` (it's the dedicated domain creation command). `plan-3-v2-architect.md` lists the required sections by name and says "follow the domain.md format" — the agent reads extract-domain if it needs the full template, or more likely it already knows the format from having seen it before.

---

## 3. Impact on Plan

### What Changes

The plan currently has:
- T002: Write `_template-domain.md` (standalone template file)
- T003: Write `_template-registry.md` (standalone template file)

**These tasks should be removed.** The templates are embedded in:
- T004: `extract-domain.md` (full domain.md + registry.md templates inline)
- T007: `plan-3-v2-architect.md` (brief reference to domain.md required sections)

### What Stays the Same

Everything else — the templates just move from standalone files into the commands that use them.

### Updated File Count

`agents/v2-commands/` goes from 10 files to **8 files**:
- ~~_template-domain.md~~ → embedded in extract-domain.md
- ~~_template-registry.md~~ → embedded in extract-domain.md
- README.md ✅
- extract-domain.md ✅
- plan-1b-v2-specify.md ✅
- plan-2-v2-clarify.md ✅
- plan-3-v2-architect.md ✅
- plan-5-v2-phase-tasks-and-brief.md ✅
- plan-6-v2-implement-phase.md ✅
- plan-6a-v2-update-progress.md ✅
- plan-7-v2-code-review.md ✅

**Wait — that's 9 files** (README + extract-domain + 7 v2 commands). The templates are gone as separate files.

---

## 4. Quick Reference

```
Q: How do agents find domain templates?
A: They're inline in the commands, same as spec templates in plan-1b.

Q: Which command is the canonical source?
A: extract-domain.md has the full template. plan-3-v2 references the format.

Q: What about the install pipeline?
A: No changes needed for templates — they're embedded in commands that 
   already get installed.

Q: What if someone wants a standalone template?
A: They can copy it from the extract-domain command. Or a project can 
   create templates/domain-template.md locally — same as plan-1b's 
   optional templates/spec-template.md pattern.
```
