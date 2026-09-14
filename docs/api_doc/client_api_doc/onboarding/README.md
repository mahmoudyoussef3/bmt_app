# Client · Onboarding

First-run onboarding slides. **Makes no backend calls.**

## Overview

| Layer | Files (relative to `lib/apps/client/features/onboarding/`) |
|---|---|
| Screen | `presentation/screens/onboarding_screen.dart` |
| Cubit | `presentation/cubit/onboarding_cubit.dart` (`checkStatus()`, `complete()`), states in `onboarding_state.dart` (`OnboardingLoaded(hasSeenOnboarding)`, `OnboardingError`) |
| Use cases | `domain/usecases/check_onboarding_status_usecase.dart`, `complete_onboarding_usecase.dart` |
| Repo | `data/repositories/onboarding_repository_impl.dart` |
| Datasource | `data/datasources/onboarding_local_datasource.dart` → `OnboardingLocalDataSourceImpl(SecureStorage())` |

## Storage

| Key (secure storage) | Value | Meaning |
|---|---|---|
| `has_seen_onboarding` | `'true'` | onboarding completed on this device |

`ClientApp` (`lib/apps/client/client_app.dart`) provides `OnboardingCubit..checkStatus()` at the root and
shows `OnboardingScreen` when `OnboardingLoaded.hasSeenOnboarding == false`, otherwise the shell
(signed in) or Welcome (signed out).

## Notes for the .NET team

Nothing to port. If the product later wants onboarding state to follow the account rather than the
device, it would become a boolean on the client profile (`PATCH /api/v1/me/profile`).
