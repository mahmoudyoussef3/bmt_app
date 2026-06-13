# AGENTS.md — Flutter Clean Architecture & Production Transportation Platform

## Read First

Before making any change:

1. Read AGENTS.md completely.
2. Read all related files before editing.
3. Understand the current architecture and business flow.
4. Reuse existing implementations whenever possible.
5. Fix root causes instead of symptoms.
6. Preserve existing functionality unless explicitly requested.
7. Prefer production-ready implementations over temporary solutions.

---

# PROJECT GOAL

This project is a real transportation platform.

It contains:

* Client Application
* Operations Dashboard
* Customer Service Dashboard
* Fleet Management
* Routes Management
* Trips Management
* Bookings Management
* Payments
* Complaints
* Packages & Subscriptions
* Notifications
* Authentication
* Reporting

Build everything as production software.

Never build demo software.

Never build prototype software.

---

# DATA SOURCE POLICY

Production data is preferred.

Priority order:

1. Supabase
2. Existing backend APIs
3. Local persistence
4. Mock data (only when explicitly requested)

Mock data is NOT the default.

When implementing new features:

* Prefer real Supabase integration.
* Prefer real CRUD operations.
* Prefer real persistence.
* Avoid temporary mock implementations.

---

# PRODUCTION-FIRST IMPLEMENTATION

Every feature should support:

* Create
* Read
* Update
* Delete

When applicable.

All operations must persist data.

Changes must survive refreshes.

Do not implement temporary memory-only storage unless explicitly requested.

---

# NO PLACEHOLDERS

Do NOT leave:

* TODO
* Coming Soon
* Placeholder Widgets
* Empty Screens
* Temporary Buttons
* Stub Services
* Fake APIs

Every feature should be fully functional.

---

# UX REQUIREMENTS

This is operations software.

Optimize for:

* Fast workflows
* Minimal clicks
* Clear information hierarchy
* Real-world transportation operations

Users should always know:

* Current status
* Required actions
* Next steps

Avoid:

* Dead ends
* Empty flows
* Unclear actions

---

# RESPONSIVE DESIGN

Must support:

* Mobile
* Tablet
* Desktop
* Web

Verify:

* RTL
* Arabic text
* Large tables
* Dialog sizing
* Scroll behavior
* Adaptive layouts

No overflow errors.

No clipping.

No broken layouts.

---

# UI QUALITY

UI must feel production-ready.

Requirements:

* Consistent spacing
* Consistent typography
* Consistent color usage
* Consistent card hierarchy
* Consistent table layouts
* Professional forms
* Professional dialogs

Avoid:

* Crowded layouts
* Excessive nesting
* Dense screens
* Tiny click targets

---

# CLEAN ARCHITECTURE (STRICT)

Follow:

Presentation
↓
Domain
↓
Data

Rules:

Presentation:

* Screens
* Widgets
* Cubits
* State classes

Domain:

* Entities
* Repository contracts
* Use cases
* Failures

Data:

* Models
* Datasources
* Repositories
* APIs
* Supabase
* Local Storage

Never bypass layers.

---

# FEATURE STRUCTURE

features/
feature_name/
data/
datasources/
models/
repositories/

```
domain/
  entities/
  repositories/
  usecases/

presentation/
  cubit/
  screens/
  widgets/
```

Large features must be divided into modules.

Example:

trips/
trip_management/
trip_creation/
trip_pricing/
trip_passengers/
trip_seats/
shared/

fleet/
drivers/
vehicles/
assignments/
documents/
shared/

routes/
route_management/
stations/
route_templates/
shared/

---

# STATE MANAGEMENT

Use Cubit/Bloc.

Rules:

Cubit
→ UseCase
→ Repository
→ DataSource

Never:

Cubit
→ Repository

Never:

Cubit
→ Supabase

Never:

Widget
→ Repository

---

# DEPENDENCY INJECTION

Use GetIt.

All registrations must live in:

core/di

No manual dependency creation inside UI.

---

# NETWORKING

Preferred stack:

* Dio
* Interceptors
* Pretty Logger
* Centralized API Service

If project already uses another solution:

* Improve existing implementation first.
* Do not replace working architecture unnecessarily.

Requirements:

* Request logging
* Response logging
* Error logging
* Timeout handling
* Failure mapping

No sensitive logging.

Mask tokens.

---

# ERROR HANDLING

Exception
↓
Failure
↓
Result
↓
Cubit State

Never expose raw exceptions to UI.

Always return user-friendly messages.

---

# SHARED CODE

If code is reused twice or more:

Move it to:

core/

Avoid duplication.

---

# SECURITY

Never commit:

* Secrets
* API Keys
* Tokens
* Passwords

Use environment configuration.

Validate all external input.

---

# TESTING

Required:

* Domain tests
* Data layer tests

Bug fixes should include:

* Reproduction
* Verification

---

# CHANGE DISCIPLINE

Before modifying code:

1. Read related files.
2. Understand business flow.
3. Check existing implementation.
4. Fix root cause.
5. Minimize unrelated changes.

---

# FINAL VALIDATION

Before finishing:

* Architecture respected.
* No layer violations.
* No duplicated logic.
* No dead buttons.
* No placeholder content.
* Responsive layout verified.
* RTL verified.
* CRUD verified.
* DI verified.
* Error handling verified.
* Production-ready UX verified.

The final result should feel like software already used daily by a transportation company.
