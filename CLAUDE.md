# CLAUDE.md

---

# Transportation Management System

This repository contains a complete transportation platform:

* Dashboard App
* Driver App
* Client App
* Supabase Backend

The platform manages:

* Drivers
* Vehicles
* Routes
* Trips
* Assignments
* Seats
* Bookings
* Packages
* Operations

Dashboard is the Source of Truth.

Driver App and Client App consume Dashboard-managed data.

---

# 1. Mandatory Reading Order

Before modifying any feature:

Read:

1. PROJECT_INDEX.md
2. SYSTEM_FLOW.md
3. DATABASE_SCHEMA.md
4. API_CONTRACTS.md
5. AGENTS.md

If working on a feature:

Read feature documentation first.

Never implement blindly.

---

# 2. Development Philosophy

Think in this order:

Business Workflow
→ Product Experience
→ System Design
→ Architecture
→ Code

Do not jump directly to implementation.

Understand why the feature exists.

Understand who uses it.

Understand which apps depend on it.

---

# 3. Workflow First Development

Never build CRUD screens first.

Design workflows first.

Bad:

Driver List
Add Driver
Edit Driver

Good:

Driver Lifecycle

Create Driver
→ Validate Documents
→ Assign Vehicle
→ Assign Route
→ Assign Trip
→ Monitor Performance

The system should support operational workflows.

Not CRUD.

---

# 4. Dashboard Ownership

Dashboard owns:

* Drivers
* Vehicles
* Routes
* Trips
* Assignments
* Pricing
* Packages

Driver App and Client App never own operational entities.

Dashboard remains the source of truth.

---

# 5. Architecture Rules

Mandatory:

Presentation
→ Domain
→ Data

Dependencies must flow downward only.

---

## Presentation

Contains:

* Screens
* Widgets
* Cubits
* States

Responsibilities:

* UI
* User interaction
* State observation

Forbidden:

* Business rules
* Supabase queries
* Repository implementations

---

## Domain

Contains:

* Entities
* Repository Contracts
* UseCases
* Business Rules

Must remain framework independent.

No Flutter imports.

---

## Data

Contains:

* Datasources
* Models
* Repository Implementations

Responsible for:

* Supabase
* APIs
* Serialization
* Persistence

---

# 6. Shared Code
No file has more than 120 lines of code

If logic is used in 2+ places:

Move to:

core/

Never duplicate logic.

Always check core before creating utilities.

---

# 7. Supabase Rules

Supabase is the only backend.

All runtime data must originate from Supabase.

---

## Forbidden

* Runtime mocks
* Fake repositories
* Hardcoded operational data
* Demo data

Allowed:

* Test doubles inside tests only

---

# 8. Business Rules

---

## Vehicles

Vehicles own:

* Capacity
* Seat Layout

Project Rule:

No VIP seats.

All seats are standard seats.

---

## Drivers

Drivers may have:

* Assignments
* Routes
* Trips

Driver availability impacts scheduling.

---

## Routes

Routes contain:

* Stops
* Distance
* Duration

Trips are generated from Routes.

---

## Trips

Trips require:

* Route
* Driver
* Vehicle

Trip lifecycle must remain valid.

---

## Seats

Seat states:

* Available
* Reserved
* Booked
* Blocked

No VIP logic.

---

## Bookings

Bookings affect:

* Seat Availability
* Occupancy
* Driver Manifest

All synchronization must remain consistent.

---

# 9. UI / UX Requirements

Every feature must support:

---

## Loading State

Never show blank screens.

Provide meaningful loading experiences.

---

## Empty State

Explain what happened.

Provide clear next actions.

---

## Error State

Show actionable errors.

Never fail silently.

---

## Success State

Confirm completion clearly.

---

# 10. Dashboard UX Rules

Dashboard is an operational workspace.

Design for:

* Speed
* Visibility
* Bulk operations
* Searchability
* Discoverability

Avoid CRUD-style experiences.

Support real workflows.

---

# 11. Client App UX Rules

Client journey:

Home
→ Route Discovery
→ Route Details
→ Trip Selection
→ Vehicle Selection
→ Seat Selection
→ Payment
→ Booking Confirmation

Maintain flow consistency.

Never create dead ends.

---

# 12. Driver App UX Rules

Driver journey:

Assignment
→ Route Review
→ Trip Start
→ Passenger Visibility
→ Trip Completion

Keep interfaces simple and operational.

---

# 13. Error Handling

Data Layer:

* Catch exceptions
* Map to typed failures

Domain Layer:

* Return ApiResult<T>

Presentation Layer:

* Convert failures to user-friendly states

No silent failures.

---

# 14. State Management

Use:

Cubit / Bloc

Rules:

* Cubits depend on UseCases only
* No repository access from UI
* No datasource access from UI

setState only for local widget state.

---

# 15. Dependency Injection

Use:

get_it

All registrations belong to:

core/di/

Avoid manual object creation.

---

# 16. Code Generation

Code generation is allowed when justified.

Examples:

* json_serializable
* freezed (if project already uses it)
* retrofit

Do not introduce unnecessary generators.

---

# 17. Build Method Rules

Never:

* Create controllers inside build()
* Create focus nodes inside build()
* Create expensive objects inside build()

Dispose resources properly.

Prefer small widgets.

Use BlocSelector and BlocBuilder at the smallest scope possible.

---

# 18. Documentation Requirements

If architecture changes:

Update:

* PROJECT_INDEX.md
* SYSTEM_FLOW.md
* Feature Documentation

If workflow changes:

Update workflow documentation.

Documentation is part of the feature.

---

# 19. Testing Requirements

Required:

* Domain tests
* Repository tests
* Cubit tests

For bug fixes:

Add a reproducing test.

Tests must be deterministic.

---

# 20. Completion Checklist

Before marking work complete:

1. Verify business workflow
2. Verify cross-app impact
3. Verify Supabase integration
4. Verify architecture compliance
5. Verify loading/empty/error states
6. Verify responsive behavior
7. Verify tests
8. Update documentation

Only then consider the task complete.

---

# 21. Agent Usage

Use proactively.

transportation-debugger

* Bugs
* Crashes
* Synchronization issues

transportation-test-engineer

* Missing tests
* New workflows

transportation-system-reviewer

* Before merge
* Before PR

transportation-git-expert

* Branches
* Commits
* PRs
* Releases

Always recommend the appropriate agent when relevant.
