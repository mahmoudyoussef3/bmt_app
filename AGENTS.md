# Codex Instructions — Flutter Clean Architecture & Operations Dashboard

## Read First

Before making any change:

1. Read AGENTS.md completely.
2. Read related files before editing.
3. Understand existing architecture.
4. Reuse existing implementations whenever possible.
5. Make the smallest correct change.

---

# IMPORTANT IMPLEMENTATION RULES

This is NOT a UI prototype.

This is NOT a wireframe.

This is NOT a demo.

Build features as if they are already being used by a real transportation operations team.

Every screen should feel production-ready even when powered by mock data.

---

## NO PLACEHOLDERS

Do NOT leave:

* TODO
* Coming Soon
* Placeholder widgets
* Empty screens
* Future implementation notes
* Temporary buttons
* Fake actions

Everything must be fully implemented.

---

## NO SNACKBAR IMPLEMENTATIONS

The following pattern is forbidden:

Button
→ Snackbar
→ Finished

Examples:

❌ Add Driver → Snackbar

❌ Create Trip → Snackbar

❌ Assign Vehicle → Snackbar

❌ Approve Payment → Snackbar

❌ Create Package → Snackbar

Instead:

✅ Open Create Screen

✅ Open Edit Screen

✅ Open Details Screen

✅ Open Confirmation Dialog

✅ Update Mock Repository

✅ Refresh State

✅ Reflect Changes In UI

---

## EVERY BUTTON MUST WORK

Every clickable element must perform a complete workflow.

Examples:

* Create
* Edit
* Delete
* Archive
* Activate
* Deactivate
* Assign
* Reassign
* Approve
* Reject
* Renew
* Suspend
* Publish
* Review

All actions must execute a complete flow.

No dead buttons.

No fake interactions.

---

## REAL CRUD

Use mock repositories only.

When user creates data:

* Persist inside mock datasource
* Update repository
* Refresh Cubit state
* Reflect in UI

When user edits data:

* Update details page
* Update lists
* Update related entities

When user deletes data:

* Remove it everywhere

When user assigns relationships:

* Update all related records

Mock data must behave like a real backend.

---

## DETAILS PAGES REQUIRED

Every major entity must have:

List Screen
↓
Details Screen

Examples:

* Driver
* Vehicle
* Route
* Trip
* Booking
* Package
* Payment
* Complaint
* User

Do NOT replace large workflows with dialogs.

Complex workflows require dedicated screens.

---

## NO DEAD ENDS

User should never reach a screen where they cannot continue working.

Every workflow should naturally continue.

Correct Example:

Create Trip
↓
Trip Created
↓
Open Trip Details

Wrong Example:

Create Trip
↓
Snackbar
↓
Stay On Same Page

---

## OPERATIONS-FIRST UX

Do NOT build database-management screens.

Do NOT build generic admin CRUD screens.

Build transportation operations software.

The system should optimize:

* Daily customer service work
* Trip planning
* Fleet management
* Payment review
* Passenger operations

The user should always know:

* What needs attention
* What action comes next
* What information matters

---

## RESPONSIVE LAYOUT

Verify:

* Desktop layouts
* Large screens
* Small screens
* Responsive tables
* Long Arabic text
* RTL support
* Scroll behavior
* Dialog sizing

Avoid:

* Overflow errors
* Clipped widgets
* Broken RTL layouts
* Misaligned cards
* Excessive whitespace
* Crowded screens

---

## SPACING & VISUAL QUALITY

UI quality is mandatory.

Verify:

* Consistent spacing
* Consistent padding
* Consistent margins
* Consistent section hierarchy
* Proper visual grouping
* Proper empty states

Avoid:

* Crowded layouts
* Dense tables
* Tiny click targets
* Excessive scrolling
* Unnecessary cards

The dashboard should feel calm, readable, and operational.

---

## BUG PREVENTION

Verify:

* No overflow
* No render exceptions
* No duplicate keys
* No broken navigation
* No invalid state transitions
* No missing loading states
* No missing error states
* No inaccessible actions

Every workflow must be testable from start to finish.

---

## MOCK DATA QUALITY

Do NOT generate generic fake data.

Use realistic Egyptian transportation company data.

Examples:

Drivers

Vehicles

Routes

Trips

Bookings

Packages

Payments

Complaints

Users

Subscriptions

All data should appear believable and internally consistent.

Relationships between entities must make sense.

---

## ARCHITECTURE (STRICT)

Follow:

Presentation → Domain → Data

Rules:

* Presentation = UI, Cubit/Bloc, state observation only
* Domain = pure business logic and use cases
* Data = APIs, local storage, external sources
* Never bypass layers
* Never mix responsibilities

---

## FEATURE STRUCTURE

features/
feature_name/
data/
domain/
presentation/

Shared reusable code belongs in:

core/

Before creating:

* utilities
* extensions
* helpers
* widgets
* services

Check existing implementations first.

---

## STATE MANAGEMENT

Use Bloc/Cubit only.

Rules:

* Cubits depend only on UseCases
* Cubits never access repositories directly
* setState allowed only for local UI state

Flow:

Cubit
→ UseCase
→ Repository
→ DataSource

No shortcuts.

No direct UI mutations.

---

## DOMAIN RULES

Domain must remain pure Dart.

Never import:

* flutter/*
* material.dart
* cupertino.dart

Allowed:

* entities
* repository contracts
* use cases
* failures
* ApiResult

---

## ERROR HANDLING

Catch exceptions only in Data layer.

Flow:

Exception
→ Failure
→ ApiResult<T>
→ Cubit State

Handle:

* loading
* success
* error
* null
* empty

Never swallow exceptions.

---

## DEPENDENCY INJECTION

Use get_it.

Rules:

* Registrations live in core/di
* No repository creation inside UI
* No use case creation inside UI

---

## BUILD METHOD RULES

* Use const whenever possible
* Keep build lightweight
* Dispose controllers properly
* Do not create controllers inside build()
* Minimize BlocBuilder rebuild scope

---

## SHARED CODE

If logic is reused in two or more places:

Move it to:

core/

Avoid duplication.

---

## DEPENDENCIES

Do not add packages unless necessary.

New packages must be:

* maintained
* stable
* production-ready

Explain why a dependency is required before adding it.

---

## SECURITY

* No hardcoded secrets
* No hardcoded tokens
* No sensitive logging
* Validate external input
* Flag security risks immediately

---

## CHANGE DISCIPLINE

When modifying code:

* Read related files first
* Fix root cause
* Avoid unrelated refactors
* Preserve existing behavior unless instructed

---

## TESTING

Write tests for:

* Domain layer
* Data layer

Bug fixes must include:

* Reproduction test
* Verification test

Rules:

* Deterministic tests
* One behavior per test

---

## CODE GENERATION

Do NOT introduce:

* Freezed
* build_runner

Prefer:

* Dart 3 sealed classes
* Pattern matching
* Switch expressions

---

## FINAL VALIDATION CHECKLIST

Before finishing:

1. Verify clean architecture boundaries.
2. Verify Cubits depend only on UseCases.
3. Verify no duplicated logic exists.
4. Verify Failures are mapped correctly.
5. Verify DI registrations.
6. Verify tests are updated.
7. Verify no unnecessary dependencies.
8. Verify every button works.
9. Verify every workflow is complete.
10. Verify every navigation path works.
11. Verify responsive layout.
12. Verify Arabic RTL layouts.
13. Verify no snackbar-only implementations.
14. Verify no placeholders remain.
15. Verify the feature feels production-ready.

---

## Agent Recommendations

When applicable:

* @debugger → runtime issues
* @test-writer → missing tests
* @code-reviewer → final review
* @git-expert → commits, branches, PR workflow
