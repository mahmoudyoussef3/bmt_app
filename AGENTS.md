# Codex Instructions — Flutter Clean Architecture

## Architecture (Strict)

Follow:

Presentation → Domain → Data

Rules:

- Presentation = UI, Cubit/Bloc, state observation only
- Domain = pure business logic and use cases
- Data = APIs, local storage, external sources
- Never bypass layers
- Never mix responsibilities

---

## Feature Structure

```text
features/
  feature_name/
    data/
    domain/
    presentation/
```

Shared reusable code belongs in:

```text
core/
```

Before creating utilities, extensions, helpers, services, or widgets, check whether an existing implementation already exists.

---

## State Management

Use Bloc/Cubit only.

Rules:

- Cubits depend only on UseCases
- Cubits must not access repositories directly
- setState is allowed only for local UI state

Example:

Cubit → UseCase → Repository → DataSource

---

## Domain Rules

Domain must remain pure Dart.

Never import:

- flutter/*
- material.dart
- cupertino.dart

Allowed:

- entities
- repositories contracts
- use cases
- failures
- ApiResult

---

## Error Handling

Catch exceptions only in Data layer boundaries.

Flow:

Exception
→ Failure
→ ApiResult<T>
→ Cubit State

Handle explicitly:

- loading
- success
- error
- null
- empty states

Never swallow exceptions.

---

## Dependency Injection

Use get_it.

Rules:

- All registrations live in core/di
- No manual repository creation in UI
- No manual use case creation in UI

---

## Build Method Rules

- Use const whenever possible
- Do not create controllers inside build()
- Dispose controllers properly
- Keep build() lightweight
- Minimize BlocBuilder rebuild scope

---

## Shared Code

If logic is reused in 2 or more places:

Move it to core/

Avoid duplication.

---

## Dependencies

Do not add packages unless necessary.

New dependencies must be:

- maintained
- stable
- production-ready

Explain why the package is needed before adding it.

---

## Security

- No hardcoded secrets
- No hardcoded tokens
- No sensitive logging
- Validate external input
- Flag security risks immediately

---

## Change Discipline

When modifying code:

- Read related files first
- Make the smallest required change
- Fix root cause
- Avoid unrelated refactoring
- Preserve existing behavior unless instructed otherwise

---

## Testing

Write tests for:

- domain layer
- data layer

Bug fixes must include:

- reproduction test
- fix verification test

Rules:

- deterministic tests
- one behavior per test

---

## Code Generation

Do not introduce:

- Freezed
- build_runner

Prefer Dart 3 features:

- sealed classes
- pattern matching
- switch expressions

---

## Review Checklist

Before finishing any task:

1. Verify clean architecture boundaries.
2. Verify Cubits use UseCases only.
3. Verify no duplicated logic exists.
4. Verify errors are mapped to Failures.
5. Verify DI registrations are correct.
6. Verify tests are updated when behavior changes.
7. Verify no unnecessary dependencies were added.

---

## Agent Recommendations

When applicable, suggest:

- @debugger → crashes and runtime issues
- @test-writer → missing tests
- @code-reviewer → final review
- @git-expert → commits, branches, PR workflow