# App entrypoints

This folder groups the three app entrypoints used during development.

- Client (mobile): `lib/apps/client/main.dart`
- Captain (mobile): `lib/apps/captain/main.dart`
- Dashboard (web): `lib/apps/dashboard/main.dart`

Run a specific app with:

```bash
# Client
flutter run -t lib/apps/client/main.dart

# Captain
flutter run -t lib/apps/captain/main.dart

# Dashboard (web)
flutter run -d web-server -t lib/apps/dashboard/main.dart
```
