# Transportation Management System Skill

## Purpose

This skill is the default operating mode for all work inside this repository.

The project is a Transportation Management System composed of:

* Dashboard App
* Driver App
* Client App
* Supabase Backend

The system manages:

* Drivers
* Vehicles
* Routes
* Trips
* Seat Management
* Assignments
* Bookings
* Packages
* Operations

This is NOT a generic CRUD application.

This is an operational transportation platform.

---

# Mandatory First Step

Before modifying any feature:

Read:

* PROJECT_INDEX.md
* DASHBOARD_SYSTEM_BLUEPRINT.md
* SYSTEM_FLOW.md
* DATABASE_SCHEMA.md
* API_CONTRACTS.md
* AGENTS.md

If any file is missing:

Generate it before implementing features.

Never work blindly.

---

# Core Principle

The Dashboard is the Source of Truth.

All operational data originates from Dashboard.

Dashboard creates and manages:

* Drivers
* Vehicles
* Routes
* Trips
* Assignments
* Pricing
* Packages

Driver App and Client App consume this data.

Never duplicate business logic across apps.

---

# Application Responsibilities

## Dashboard

Operational Management System.

Responsible for:

* Fleet Management
* Driver Management
* Route Management
* Trip Management
* Assignments
* Seat Configuration
* Pricing
* Packages
* Analytics

Dashboard controls the entire system.

---

## Driver App

Operational Execution App.

Responsible for:

* Viewing assignments
* Viewing routes
* Viewing trips
* Starting trips
* Updating trip status
* Passenger information
* Operational reporting

Driver App does not manage core business entities.

---

## Client App

Booking Experience.

Responsible for:

* Discovering routes
* Viewing trips
* Viewing vehicles
* Seat selection
* Booking
* Payments
* Subscription packages

Client App never creates operational data.

---

# Development Process

Before implementing a feature:

## Step 1

Understand business workflow.

Answer:

* Why does this feature exist?
* Which app owns it?
* Which apps consume it?
* What data does it require?

---

## Step 2

Document feature architecture.

Create:

FEATURE_NAME_ARCHITECTURE.md

Include:

* Purpose
* Entities
* Workflows
* States
* Business Rules
* Validations
* Dependencies

---

## Step 3

Audit existing implementation.

Identify:

* UX problems
* Missing business logic
* Mock data
* Technical debt
* Accessibility issues

---

## Step 4

Design before coding.

Produce:

* UX review
* Workflow review
* Validation review

Only then implement.

---

# Architecture Rules

Follow:

Presentation → Domain → Data

---

## Presentation

Contains:

* Screens
* Widgets
* Cubits
* States

Responsibilities:

* Render UI
* Manage presentation state

Must NOT contain:

* Business logic
* Database logic
* Supabase queries

---

## Domain

Contains:

* Entities
* Repositories
* Use Cases

Responsibilities:

* Business rules
* Validation logic
* Workflow logic

Must remain framework independent.

---

## Data

Contains:

* Datasources
* Models
* Repository Implementations

Responsibilities:

* Supabase
* API communication
* Serialization
* Persistence

---

# Feature Structure

Use:

feature_name/

data/
├── datasources/
├── models/
├── repositories/

domain/
├── entities/
├── repositories/
├── usecases/

presentation/
├── cubit/
├── screens/
├── widgets/

feature_di.dart

---

# Supabase Rules

Supabase is the only backend.

Do not:

* Create runtime mocks
* Create fake repositories
* Use temporary JSON data

Allowed:

* Test doubles inside tests only

Every feature must use real Supabase-backed data.

---

# No Mock Data Policy

Forbidden:

* MockDatasource
* FakeRepository
* Hardcoded Lists
* Demo Data
* Temporary Data Sources

Runtime data must always come from:

Supabase → Datasource → Repository → UseCase → Cubit → UI

---

# Workflow First Development

Never build CRUD screens first.

Design workflows first.

Example:

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
→ Track Performance

The UI should support workflows.

Not CRUD.

---

# UX Requirements

Every feature must include:

## States

* Loading
* Empty
* Error
* Success

---

## Accessibility

* Keyboard navigation
* Focus management
* Semantic labels
* Responsive layouts

---

## Responsive Design

Support:

* Mobile
* Tablet
* Desktop

Do not simply resize widgets.

Adapt layouts intelligently.

---

# Transportation Business Rules

## Vehicles

Vehicles own:

* Capacity
* Seat Layout

No VIP seats.

All seats are standard seats.

---

## Drivers

Drivers may have:

* Assignments
* Routes
* Trips

Driver status affects scheduling.

---

## Routes

Routes contain:

* Stops
* Distance
* Duration

Trips are created from routes.

---

## Trips

Trips require:

* Route
* Driver
* Vehicle

Trips control:

* Seat Availability
* Booking Availability

---

## Seats

Seats are generated from vehicle capacity.

Seat states:

* Available
* Reserved
* Booked
* Blocked

No VIP logic.

---

## Bookings

Bookings affect:

* Seat availability
* Occupancy
* Driver manifests

---

# Feature Creation Rules

When creating a feature:

1. Understand workflow
2. Design architecture
3. Design UX
4. Define entities
5. Define states
6. Define validations
7. Define Supabase integration
8. Implement feature
9. Test feature
10. Update documentation

---

# Output Expectations

When asked to create or modify a feature:

Always provide:

1. Business Analysis
2. Architecture Plan
3. UX Review
4. Entity Design
5. State Design
6. Validation Rules
7. Supabase Integration Plan
8. Implementation Plan
9. Code Changes
10. Documentation Updates

Do not jump directly to code.

Think like a System Architect first, then a Product Designer, then a Flutter Engineer.
