# Implementation Plan: Prompt 3 – BMT Brand Identity & Premium UX

**Branch**: `[001-bmt-brand-identity-premium-ux]` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-bmt-brand-identity-premium-ux/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Define a unified premium BMT transport brand system across dashboard, client, and driver apps. The plan centers on semantic design tokens, a branded map experience, reusable operational components, consistent motion and feedback rules, and responsive light/dark theme behavior that preserves clarity in both Arabic and Latin layouts.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart 3 / Flutter stable

**Primary Dependencies**: Flutter UI framework, flutter_bloc, get_it, existing shared map/tracking layers, Supabase-backed product data surfaces

**Storage**: N/A for the specification artifacts; runtime product state remains Supabase-backed in the wider platform

**Testing**: Design review checklist, manual UX validation, responsive layout review, accessibility checks, and future widget/presentation tests for implementation

**Target Platform**: Flutter mobile, tablet, desktop, and web surfaces used by the BMT platform

**Project Type**: Cross-app UI/UX system specification for a mobile-first transportation SaaS platform

**Performance Goals**: Premium interactions should remain visually stable and responsive at 60 fps on core screens

**Constraints**: Must preserve RTL support, accessibility contrast, reduced-motion behavior, and strict cross-app consistency while avoiding copycat design language

**Scale/Scope**: Applies to all major surfaces in dashboard, client, and driver apps, including map views, cards, sheets, dialogs, and feedback states

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Pass.

- Clean architecture remains intact because the feature defines shared experience rules rather than bypassing layered app boundaries.
- No mock data is introduced; the specification assumes real operational data and existing runtime sources.
- Shared UI language is centralized so reusable patterns can live in core/shared layers instead of being duplicated.
- RTL, accessibility, responsiveness, and premium UX constraints are explicitly covered.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── apps/
│   ├── dashboard/
│   │   ├── core/
│   │   └── features/
│   ├── client/
│   │   ├── core/
│   │   └── features/
│   └── driver/
│       ├── core/
│       └── features/
├── core/
│   ├── di/
│   ├── design/
│   ├── widgets/
│   └── tracking/
└── shared/

assets/
├── images/
├── icons/
└── maps/

docs/
├── architecture/
└── dashboard/
```

**Structure Decision**: This feature is implemented as a shared cross-app experience system layered through `lib/core/` and each app’s `core/` and `features/` folders. The source structure above reflects the existing Flutter monorepo organization used by dashboard, client, and driver apps.

## Complexity Tracking

No constitution violations require justification for this feature.
