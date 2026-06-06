# App entrypoints and product boundaries

This folder groups the three app entrypoints used during development and the
future product-based architecture.

- Client (mobile): `lib/apps/client/main.dart`
- Captain (mobile): `lib/apps/captain/main.dart`
- Dashboard (web): `lib/apps/dashboard/main.dart`

Phase 0 keeps the existing UI prototype implementations in place while adding
future product boundaries:

```text
apps/
  client/
    core/
      di/
      routes/
    features/
  captain/
    core/
      di/
      routes/
    features/
  dashboard/
    core/
      di/
      routes/
    features/
```

Do not move feature implementations into these folders until the product UI
flows are finalized and the migration phase is approved.

Run a specific app with:

```bash
# Client
flutter run -t lib/apps/client/main.dart

# Captain
flutter run -t lib/apps/captain/main.dart

# Dashboard (web)
flutter run -d web-server -t lib/apps/dashboard/main.dart
```
