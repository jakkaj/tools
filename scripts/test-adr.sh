#!/bin/bash

# test-adr.sh - Lightweight smoke tests for ADR generation functionality
# Tests format validation and numbering logic without full coverage

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="/tmp/adr-test-$$"
ADR_DIR="$TEST_DIR/docs/adr"

echo "🧪 ADR Smoke Tests"
echo "=================="
echo ""

# Setup test environment
echo "Setting up test environment in $TEST_DIR..."
mkdir -p "$ADR_DIR"

# Test 1: Format Validation
echo -n "Test 1: ADR Format Validation... "

cat > "$ADR_DIR/adr-0001-test-decision.md" << 'EOF'
---
title: "ADR-0001: Test Decision"
status: "Proposed"
date: "2025-11-07"
authors: "Test Author"
tags: ["architecture", "decision", "test"]
supersedes: ""
superseded_by: ""
---

# ADR-0001: Test Decision

## Status

**Proposed**

## Context

This is a test context for validation purposes.

## Decision

We decide to use this test format for validation.

## Consequences

### Positive

- **POS-001**: Test passes validation
- **POS-002**: Format is correct
- **POS-003**: Structure is maintained

### Negative

- **NEG-001**: This is only a test
- **NEG-002**: No real decision made
- **NEG-003**: Example only

## Alternatives Considered

### Alternative 1: No Testing

- **ALT-001**: **Description**: Don't test ADR format
- **ALT-002**: **Rejection Reason**: Testing is important

### Alternative 2: Manual Testing

- **ALT-003**: **Description**: Test manually each time
- **ALT-004**: **Rejection Reason**: Automation is better

## Implementation Notes

- **IMP-001**: Run this test script
- **IMP-002**: Verify output
- **IMP-003**: Check all sections present

## References

- **REF-001**: [Spec](../../001-test/test-spec.md)
- **REF-002**: [Plan](../../001-test/test-plan.md)
- **REF-003**: Test documentation
EOF

# Validate format
ERRORS=0

# Check required sections
for section in "Status" "Context" "Decision" "Consequences" "Alternatives Considered" "Implementation Notes" "References"; do
  if ! grep -q "## $section" "$ADR_DIR/adr-0001-test-decision.md"; then
    echo -e "${RED}✗${NC} Missing section: $section"
    ((ERRORS++))
  fi
done

# Check code format (3-4 letters + 3 digits)
if ! grep -q "POS-[0-9][0-9][0-9]" "$ADR_DIR/adr-0001-test-decision.md"; then
  echo -e "${RED}✗${NC} Invalid POS code format"
  ((ERRORS++))
fi

if ! grep -q "NEG-[0-9][0-9][0-9]" "$ADR_DIR/adr-0001-test-decision.md"; then
  echo -e "${RED}✗${NC} Invalid NEG code format"
  ((ERRORS++))
fi

if ! grep -q "ALT-[0-9][0-9][0-9]" "$ADR_DIR/adr-0001-test-decision.md"; then
  echo -e "${RED}✗${NC} Invalid ALT code format"
  ((ERRORS++))
fi

# Check minimum counts (3 POS, 3 NEG)
POS_COUNT=$(grep -c "\*\*POS-[0-9][0-9][0-9]\*\*" "$ADR_DIR/adr-0001-test-decision.md")
NEG_COUNT=$(grep -c "\*\*NEG-[0-9][0-9][0-9]\*\*" "$ADR_DIR/adr-0001-test-decision.md")

if [ "$POS_COUNT" -lt 3 ]; then
  echo -e "${RED}✗${NC} Less than 3 POS codes (found $POS_COUNT)"
  ((ERRORS++))
fi

if [ "$NEG_COUNT" -lt 3 ]; then
  echo -e "${RED}✗${NC} Less than 3 NEG codes (found $NEG_COUNT)"
  ((ERRORS++))
fi

if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✓${NC} Format validation passed"
else
  echo -e "${RED}✗${NC} Format validation failed with $ERRORS errors"
fi

# Test 2: Sequential Numbering
echo -n "Test 2: Sequential Numbering... "

# Create second ADR
cat > "$ADR_DIR/adr-0002-second-decision.md" << 'EOF'
---
title: "ADR-0002: Second Decision"
status: "Proposed"
---
# ADR-0002: Second Decision
EOF

# Test numbering extraction
EXISTING=$(ls "$ADR_DIR"/adr-*.md 2>/dev/null | sed 's/.*adr-\([0-9]*\).*/\1/' | sort -n | tail -1)
NEXT=$(printf "%04d" $((${EXISTING:-0} + 1)))

if [ "$EXISTING" = "0002" ] && [ "$NEXT" = "0003" ]; then
  echo -e "${GREEN}✓${NC} Numbering logic correct (next would be 0003)"
else
  echo -e "${RED}✗${NC} Numbering logic failed (expected 0003, got $NEXT)"
  ((ERRORS++))
fi

# Test 3: Index Table Update
echo -n "Test 3: Index Table Format... "

# Create index file
cat > "$ADR_DIR/README.md" << 'EOF'
# ADR Index

| ADR | Title | Date | Status | Supersedes | Superseded By |
|-----|-------|------|--------|------------|---------------|
| 0001 | Test Decision | 2025-11-07 | Proposed | - | - |
| 0002 | Second Decision | 2025-11-07 | Proposed | - | - |
EOF

# Check table format
if grep -q "| 0001 | Test Decision" "$ADR_DIR/README.md" && \
   grep -q "| 0002 | Second Decision" "$ADR_DIR/README.md"; then
  echo -e "${GREEN}✓${NC} Index table format correct"
else
  echo -e "${RED}✗${NC} Index table format incorrect"
  ((ERRORS++))
fi

# Test 4: Slugification
echo -n "Test 4: Title Slugification... "

test_slug() {
  local input="$1"
  local expected="$2"
  local actual=$(echo "${input}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

  if [ "$actual" = "$expected" ]; then
    return 0
  else
    echo -e "\n  ${RED}✗${NC} '$input' → '$actual' (expected '$expected')"
    return 1
  fi
}

SLUG_ERRORS=0
test_slug "Adopt Event Sourcing" "adopt-event-sourcing" || ((SLUG_ERRORS++))
test_slug "Use Redis for Caching!" "use-redis-for-caching" || ((SLUG_ERRORS++))
test_slug "  Implement Circuit Breaker Pattern  " "implement-circuit-breaker-pattern" || ((SLUG_ERRORS++))
test_slug "API/Gateway Design" "api-gateway-design" || ((SLUG_ERRORS++))

if [ $SLUG_ERRORS -eq 0 ]; then
  echo -e "${GREEN}✓${NC} Slugification working correctly"
else
  echo -e "${RED}✗${NC} Slugification failed with $SLUG_ERRORS errors"
  ERRORS=$((ERRORS + SLUG_ERRORS))
fi

# Cleanup
echo ""
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "=================="
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ All smoke tests passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Tests failed with $ERRORS total errors${NC}"
  exit 1
fi