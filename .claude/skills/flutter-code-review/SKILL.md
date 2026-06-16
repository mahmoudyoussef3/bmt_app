# Transportation System Review Skill

## Purpose

This skill is used before considering any task complete.

It is the final verification layer for:

* Dashboard App
* Driver App
* Client App
* Shared Domain Logic
* Supabase Integration

The goal is to ensure that implementations are:

* Correct
* Safe
* Production-ready
* Consistent with business rules
* Consistent with system architecture

---

# When To Use

Run this review when:

* User says "done"
* User says "finished"
* User says "task complete"
* Before opening a PR
* Before merging
* Before deployment
* After any feature implementation
* After any major refactor

---

# Review Mode

This is a REVIEW process.

First understand:

* What was requested
* What was implemented
* Which modules were modified
* Which applications are affected

Do not assume success.

Verify success.

---

# Phase 1 — Requirement Validation

Review original requirements.

Verify:

* All requested functionality exists
* No requirements were skipped
* No requirements were partially implemented
* No unrelated functionality was added

Answer:

Did the implementation fully solve the requested problem?

---

# Phase 2 — Business Logic Validation

Review transportation business rules.

Verify:

## Drivers

* Driver assignments are valid
* License rules are respected
* Driver states remain consistent

---

## Vehicles

* Vehicle status is respected
* Vehicle assignment rules are enforced
* Capacity calculations are correct

---

## Routes

* Route integrity remains valid
* Stops ordering remains correct

---

## Trips

* Trip lifecycle remains valid
* Driver assignment rules are respected
* Vehicle assignment rules are respected

---

## Seats

Verify:

* No double booking
* Availability calculations are correct
* Capacity limits respected

No VIP seat logic.

All seats are standard seats.

---

## Bookings

Verify:

* Booking lifecycle remains valid
* Seat state synchronization works
* Trip occupancy updates correctly

---

# Phase 3 — Cross-App Impact Analysis

This is mandatory.

For every change determine impact on:

## Dashboard

Verify:

* Existing workflows still function

---

## Driver App

Verify:

* Assignments still work
* Trip visibility still works
* Driver operations still work

---

## Client App

Verify:

* Route visibility still works
* Booking flow still works
* Seat selection still works

---

# Phase 4 — Architecture Compliance

Verify:

Presentation → Domain → Data

---

## Presentation

Must contain:

* UI
* Cubits
* States

Must NOT contain:

* Business logic
* Supabase queries

---

## Domain

Must contain:

* Entities
* UseCases
* Repository contracts

Must remain framework independent.

---

## Data

Must contain:

* Datasources
* Models
* Repository implementations

Must handle external integrations.

---

# Phase 5 — Supabase Validation

Verify:

* Queries are correct
* Filters are correct
* Joins are correct
* Relationships are respected
* Error handling exists

---

## Forbidden

* Runtime mocks
* Temporary JSON
* Fake repositories
* Hardcoded operational data

---

# Phase 6 — Workflow Validation

Review workflow impact.

Examples:

Driver
→ Vehicle
→ Assignment
→ Route
→ Trip
→ Booking

Verify no workflow breaks.

Verify all state transitions remain valid.

---

# Phase 7 — UI / UX Validation

Review:

* Loading states
* Empty states
* Error states
* Success states

---

Verify:

* Responsive layouts
* Accessibility
* Proper spacing
* No overflow
* No clipping
* No broken dialogs

---

## Dashboard-Specific Validation

Verify:

* Tables remain usable
* Filters work
* Search works
* Bulk actions work

---

## Client App Validation

Verify:

* Home flow
* Route discovery
* Route details
* Trip selection
* Seat selection
* Payment flow

remain consistent.

---

# Phase 8 — Performance Validation

Review:

* Widget rebuilds
* Large lists
* Large tables
* Seat maps
* Nested scroll views

Identify:

* Expensive rebuilds
* Unnecessary queries
* Duplicate requests

---

# Phase 9 — Accessibility Validation

Verify:

* Keyboard navigation
* Focus traversal
* Screen reader compatibility
* Semantic labels

---

# Phase 10 — Documentation Validation

Verify updates to:

* PROJECT_INDEX.md
* SYSTEM_FLOW.md
* Feature documentation

if architecture or workflow changed.

---

# Phase 11 — Testing Validation

Verify:

* Existing tests still pass
* New functionality is covered
* No failing tests

Review:

* Unit tests
* Repository tests
* Cubit tests

---

# Phase 12 — Code Quality Validation

Verify:

* No dead code
* No duplicated logic
* Clear naming
* Small focused classes
* Single responsibility

---

# Phase 13 — Security Validation

Verify:

* No hardcoded secrets
* No exposed keys
* No sensitive logging
* Proper permission handling

---

# Final Output Format

## Review Summary

PASS
or
NEEDS_CHANGES

---

## Requirement Coverage

What was requested:

* ...

What was implemented:

* ...

Missing items:

* ...

---

## Business Logic Review

PASS / FAIL

Details:

* ...

---

## Cross-App Impact Review

Dashboard:
PASS / FAIL

Driver App:
PASS / FAIL

Client App:
PASS / FAIL

---

## Architecture Review

PASS / FAIL

Details:

* ...

---

## Supabase Review

PASS / FAIL

Details:

* ...

---

## Workflow Review

PASS / FAIL

Details:

* ...

---

## UX Review

PASS / FAIL

Details:

* ...

---

## Performance Review

PASS / FAIL

Details:

* ...

---

## Security Review

PASS / FAIL

Details:

* ...

---

## Testing Review

PASS / FAIL

Details:

* ...

---

## Documentation Review

PASS / FAIL

Details:

* ...

---

## Final Risk Assessment

Low Risk
Medium Risk
High Risk

Explain why.

---

## Required Action Items

1. ...
2. ...
3. ...

Do not mark PASS unless every critical review category passes.
## Safety

- [ ] No existing functionality, APIs, flows, or UX broken.
- [ ] No performance regressions (unnecessary rebuilds, heavy build methods, missing const).
- [ ] No security risks (hardcoded secrets, unvalidated input, sensitive data in logs).
- [ ] No unused imports, dead code, or debug artifacts left behind.
- [ ] Controllers and focus nodes properly disposed.

## Code Quality

- [ ] Code is clean, readable, and follows project conventions.
- [ ] Files and functions are small and focused.
- [ ] No unnecessary duplication.
- [ ] Dart naming conventions followed.
- [ ] Import ordering correct.

## Output

After completing the checklist, provide a brief summary:

1. **What** was changed
2. **Why** it was changed
3. **Why** the solution is safe and correct