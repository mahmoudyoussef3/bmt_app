# Generated Files & Architecture Validation Hook

## Purpose

This hook runs before commit and verifies that generated files and architecture-sensitive files remain consistent.

The goal is to prevent:

* Missing generated files
* Outdated build_runner outputs
* Broken Supabase models
* Repository/DataSource inconsistencies
* Invalid commits

---

# When To Trigger

Run on:

* pre-commit
* pre-push

---

# Generated File Detection

Check changed files:

* *_response.dart
* *_request.dart
* *.g.dart
* JsonSerializable models
* Freezed models
* DataSource files
* Repository implementation files

Examples:

```bash
*_response.dart
*_request.dart
*.g.dart
```

---

# Validation Rules

## Rule 1 - Generated Files

If any of the following change:

```bash
datasources/
data_sources/
models/
responses/
requests/
```

or:

```bash
@JsonSerializable
@freezed
```

is detected

Require:

```bash
dart run build_runner build --delete-conflicting-outputs
```

before commit.

---

## Rule 2 - Supabase Schema Safety

If modified files contain:

```bash
supabase
rpc
table
from(
insert(
update(
delete(
```

Display:

```text
⚠️ Supabase-related files changed.

Verify:
- Queries still match schema
- Relationships remain valid
- RLS policies are respected
- Client App impact reviewed
- Driver App impact reviewed
- Dashboard impact reviewed
```

---

## Rule 3 - Clean Architecture Validation

If a modified file is inside:

```bash
presentation/
```

Scan for:

```bash
Supabase.instance
Dio(
http.
```

Fail commit if detected.

Reason:

Presentation layer must not perform direct data access.

---

## Rule 4 - No Mock Data Policy

Scan changed files for:

```bash
MockDatasource
MockDataSource
FakeRepository
HardcodedData
DemoData
```

Fail commit if found.

Runtime mocks are forbidden.

Only test doubles inside tests are allowed.

---

## Rule 5 - Repository Boundary Validation

If:

```bash
repository_impl.dart
repository.dart
```

changed

Display:

```text
⚠️ Repository layer modified.

Verify:
- Errors handled properly
- Entity mapping remains correct
- No UI logic introduced
- No Supabase objects leaked to Domain
```

---

## Rule 6 - Documentation Reminder

If feature files changed:

```bash
features/
```

Display:

```text
📄 Verify documentation updates:

- PROJECT_INDEX.md
- SYSTEM_FLOW.md
- Feature Architecture Docs
```

---

# Success Output

```text
✅ Architecture validation passed
✅ Generated files verified
✅ No forbidden patterns detected
✅ Ready to commit
```

---

# Failure Output

```text
❌ Validation failed

Required actions:

1. Run build_runner
2. Fix architecture violations
3. Remove runtime mocks
4. Re-run validation
```

---

# Project-Specific Rules

Transportation Management System Rules:

* Dashboard is source of truth
* No runtime mock data
* Supabase is the only backend
* Clean Architecture required
* Presentation → Domain → Data only
* Driver App and Client App must not duplicate Dashboard logic

Any violation should block the commit.
