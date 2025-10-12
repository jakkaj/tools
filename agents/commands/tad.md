---
description: Test-Assisted Development (TAD) workflow guide for LLM coding agents practicing "tests as documentation"
---

# /tad - Test-Assisted Development Guide

You are practicing **Test-Assisted Development (TAD)** with "tests as documentation."

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

## Scratch → Promote Workflow

### 1) Write Probes in `tests/scratch/`
- Fast iteration, no documentation needed
- Explore behavior, validate assumptions
- Don't worry about coverage or quality yet
- **Exclude from CI** (via .gitignore or test runner config)

### 2) Implement iteratively
- Code and scratch tests evolve together
- Use probes to validate each step
- Refine understanding as you go

### 3) Promote valuable tests
- When behavior stabilizes, identify tests worth keeping
- Apply **CORE heuristic**: Critical path, Opaque behavior, Regression-prone, Edge case
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
2. **Implementation** informed by iterative probe refinement
3. **Promotion plan:** Which probes to promote/delete using CORE heuristic
4. **Promoted tests** with complete Test Doc comment blocks
5. **Learning notes:** Brief summary of exploration insights (in execution log)

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

- **Tests are executable documentation** – optimize for the next developer's understanding
- **Keep only what enforces a contract or teaches something important** – delete the rest
- **Quality over coverage** – every promoted test must "pay rent" via comprehension value
- **Be smart about TDD** – test-first when it adds value, not dogmatically
- **Scratch is temporary** – it's a thinking space, not the final product
- **Promotion is selective** – use the CORE heuristic ruthlessly

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
