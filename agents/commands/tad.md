---
description: Test-Assisted Development (TAD) workflow guide for LLM coding agents practicing "tests as documentation"
---

# /tad - Test-Assisted Development Guide

You are practicing **Test-Assisted Development (TAD)** with "tests as documentation."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## ⚠️ CRITICAL ACTION: **RUN** Tests Repeatedly
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**TAD requires executing tests throughout development**:

```bash
# Python example
pytest tests/scratch/test_your_feature.py -v

# TypeScript/JavaScript example
npm test tests/scratch/test-your-feature.test.ts

# Run continuously during implementation
npm test -- --watch
```

**You MUST**:
1. **RUN** scratch tests after writing them (expect RED)
2. **RUN** tests again after implementation changes (expect GREEN)
3. **RUN** tests after refactoring (verify still GREEN)
4. **REPEAT** this RED→GREEN cycle 10-20+ times per feature

**If you are not running tests, you are not doing TAD.**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Goal

- Use tests as a fast execution harness to explore/iterate
- Keep only tests that add durable value AND read like high-fidelity docs
- Optimize for the next developer's understanding

## Quality Principles

- Tests must explain **why they exist**, **what contract they lock in**, and **how to use the code**
- Prefer clarity over cleverness; realistic inputs over synthetic ones
- Each promoted test must "pay rent" by improving comprehension for future readers

## Promotion Heuristic (CORE)

**Keep if:** Critical path, Opaque behavior, Regression-prone, Edge case

**Delete:** Everything else (but preserve learning notes in execution log/PR)

## Comment Contract (every promoted test MUST include)

```typescript
/*
Test Doc:
- Why: <business/bug/regression reason in 1–2 lines>
- Contract: <plain-English invariant(s) this test asserts>
- Usage Notes: <how a developer should call/configure the API; gotchas>
- Quality Contribution: <what failure this will catch; link to issue/PR/spec>
- Worked Example: <inputs/outputs summarized for scanning>
*/
```

```python
"""
Test Doc:
- Why: <business/bug/regression reason in 1–2 lines>
- Contract: <plain-English invariant(s) this test asserts>
- Usage Notes: <how a developer should call/configure the API; gotchas>
- Quality Contribution: <what failure this will catch; link to issue/PR/spec>
- Worked Example: <inputs/outputs summarized for scanning>
"""
```

## Authoring Conventions

- **Name tests:** "Given … When … Then …" (e.g., `test_given_iso_date_when_parsing_then_returns_normalized_cents`)
- **One behavior per test:** No parameterized omnibus unless it reads well
- **Arrange-Act-Assert:** With blank lines between phases
- **Explicit data builders:** Prefer over magic factories; show the shape
- **No logs/prints:** Encode expectations in assertions and comments
- **Cross-link:** Reference spec/ADR/issue IDs where relevant

## Two Kinds of Tests

### Scratch Tests (Development Tools - Temporary)
- **Purpose**: Fast feedback during coding - RUN them repeatedly to validate isolated code
- **Lifespan**: Temporary - most will be DELETED after implementation
- **Documentation**: None required - they're throwaway exploration tools
- **Expected count**: 10-20 per feature during development
- **Value**: High-fidelity loop that validates code WITHOUT running entire project

### Promoted Tests (Documentation - Permanent)
- **Purpose**: Teach future developers how code works
- **Lifespan**: Permanent - will stay in codebase and run in CI
- **Documentation**: Full Test Doc comment blocks required (all 5 fields)
- **Expected count**: 1-2 per feature (typically 5-10% of scratch tests)
- **Value**: "Pay rent" via comprehension - must be critical/opaque/regression-prone/edge cases

## Scratch → Promote Workflow

### 1) Write Probes in `tests/scratch/`
- Fast iteration, no documentation needed
- Explore behavior, validate assumptions
- Don't worry about coverage or quality yet
- **Exclude from CI** (via .gitignore or test runner config)

### 2) **RUN-Implement-Fix Loop** (THE CORE VALUE OF TAD)

**THIS IS THE MOST IMPORTANT STEP - YOU MUST EXECUTE TESTS**:

1. **Write** a scratch test for small isolated behavior
2. **🔴 RUN the test** → expect failure (RED)
   ```bash
   pytest tests/scratch/test_feature.py -v  # Python
   npm test tests/scratch/test-feature.test.ts  # JS/TS
   ```
3. **Write** minimal code to make it pass
4. **🟢 RUN test again** → expect success (GREEN)
5. **Refactor** if needed, **re-run test** to verify
6. **REPEAT** for next behavior (expect 10-20 cycles)

**Evidence Required**: Show test execution output proving RED→GREEN cycles

This tight loop validates isolated code WITHOUT running entire project.
Most scratch tests will be DELETED later - they're dev tools, not documentation.

### 3) Promote valuable tests (VERY SELECTIVE)
- When behavior stabilizes, identify tests worth keeping (typically 1-2 per feature)
- **Most scratch tests are DELETED** - they're temporary development tools
- Apply **CORE heuristic ruthlessly**: Critical path, Opaque behavior, Regression-prone, Edge case
- Expected promotion rate: 5-10% (if you wrote 15 scratch tests, promote ~1-2)
- Move to `tests/unit/` or `tests/integration/`

### 4) Add Test Doc blocks
- Fill all 5 required fields (Why, Contract, Usage Notes, Quality Contribution, Worked Example)
- Ensure test reads like high-fidelity documentation
- Use Given-When-Then naming

### 5) Delete scratch probes
- Remove tests that don't add durable value
- Keep brief "learning notes" in execution log or PR description
- Only promoted tests remain in CI

## CI & Docs

- **Exclude** `tests/scratch/` from CI
- **Promoted tests** must pass without network/sleep/flakes (<300ms)
- **Treat promoted tests as canonical examples** – copy-pasteable into new code

## What to Produce (when implementing a feature)

1. **Scratch probes** in `tests/scratch/` that isolate the behavior
2. **Execution evidence**: Show test runs, RED→GREEN cycles, iteration counts
3. **Implementation** informed by iterative probe refinement
4. **Promotion plan:** Which probes to promote/delete using CORE heuristic (expect ~5-10% promotion rate)
5. **Promoted tests** (typically 1-2) with complete Test Doc comment blocks
6. **Learning notes:** Brief summary of exploration insights (in execution log)

## Example Workflow

```bash
# 1. Create scratch directory (if needed)
mkdir -p tests/scratch
# Ensure it's in .gitignore or excluded from test runner

# 2. Write probe tests (fast, no docs)
# tests/scratch/test_invoice_parsing_probe.py
def test_basic_parsing():
    # Quick validation, explore behavior
    assert parse_invoice({"total": "100"}) is not None

# 3. Implement iteratively
# Refine both code and probes together

# 4. Promote valuable test
# Move to tests/unit/test_invoice_parsing.py
def test_given_iso_date_and_aud_totals_when_parsing_then_returns_normalized_cents():
    """
    Test Doc:
    - Why: Regression guard for rounding bug (#482)
    - Contract: Returns total_cents:int and timezone-aware datetime with exact cents
    - Usage Notes: Pass currency='AUD'; strict=True raises on unknown fields
    - Quality Contribution: Prevents silent money loss; showcases canonical call pattern
    - Worked Example: "1,234.56 AUD" -> 123_456; "2025-10-11+10:00" -> aware datetime
    """
    # Arrange
    payload = {"total": "1,234.56", "currency": "AUD", "date": "2025-10-11T09:30:00+10:00"}
    # Act
    result = parse_invoice(payload, strict=True)
    # Assert
    assert result.total_cents == 123_456
    assert result.date.utcoffset().total_seconds() == 10 * 3600

# 5. Delete scratch probes
# rm tests/scratch/test_invoice_parsing_probe.py
# Keep learning notes in execution log
```

## TypeScript Template

```typescript
import { expect, test } from 'vitest';
import { parseInvoice } from '../invoice';

test('given_iso_date_and_aud_totals_when_parsing_then_returns_normalized_cents', () => {
  /*
  Test Doc:
  - Why: Prevent regression from #482 where AUD rounding truncated cents
  - Contract: parseInvoice returns {totalCents:number, date:ZonedDate} with exact cent accuracy
  - Usage Notes: Supply currency code; parser defaults to strict mode (throws on unknown fields)
  - Quality Contribution: Catches rounding/locale drift and date-TZ bugs; documents required fields
  - Worked Example: "1,234.56 AUD" → totalCents=123456; "2025-10-11+10:00" → ZonedDate(Australia/Brisbane)
  */

  // Arrange
  const input = {
    total: '1,234.56',
    currency: 'AUD',
    date: '2025-10-11T09:30:00+10:00'
  };

  // Act
  const result = parseInvoice(input);

  // Assert
  expect(result.totalCents).toBe(123456);
  expect(result.date.toString()).toContain('2025-10-11T09:30:00+10:00');
});
```

## Python Template

```python
import pytest
from invoices import parse_invoice

def test_given_iso_date_and_aud_totals_when_parsing_then_returns_normalized_cents():
    """
    Test Doc:
    - Why: Regression guard for rounding bug (#482)
    - Contract: Returns total_cents:int and timezone-aware datetime with exact cents
    - Usage Notes: Pass currency='AUD'; strict=True raises on unknown fields
    - Quality Contribution: Prevents silent money loss; showcases canonical call pattern
    - Worked Example: "1,234.56 AUD" -> 123_456; "2025-10-11+10:00" -> aware datetime
    """

    # Arrange
    payload = {
        "total": "1,234.56",
        "currency": "AUD",
        "date": "2025-10-11T09:30:00+10:00"
    }

    # Act
    result = parse_invoice(payload, strict=True)

    # Assert
    assert result.total_cents == 123_456
    assert result.date.utcoffset().total_seconds() == 10 * 3600
```

## Remember

- **RUN scratch tests repeatedly during development** – this is the core value of TAD
- **DELETE most scratch tests** – they're development tools, not documentation (90-95% deletion rate)
- **Promote only 1-2 tests per feature** – use CORE heuristic ruthlessly (5-10% promotion rate)
- **Tests are executable documentation** – optimize for the next developer's understanding
- **Quality over coverage** – every promoted test must "pay rent" via comprehension value
- **Scratch is temporary** – it's a thinking space, not the final product
- **The fast feedback loop is everything** – RUN tests to validate isolated code without running entire project

## When to Use TAD

TAD works best for:
- **Complex domains** where understanding is more valuable than coverage metrics
- **APIs and libraries** where tests serve as usage examples
- **Critical business logic** that needs clear behavioral documentation
- **Features with unclear requirements** that benefit from exploration

Consider Full TDD instead when:
- Requirements are crystal clear from the start
- Algorithm correctness is paramount (financial calculations, crypto, etc.)
- You need comprehensive edge case coverage upfront

Consider Lightweight testing when:
- Features are simple and straightforward
- Quick validation is sufficient
- Time constraints are tight

---

**TAD is about making tests valuable, not just making tests.** Every promoted test should make future developers say "Oh, that's how this works!"
