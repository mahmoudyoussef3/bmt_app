# Flutter Flavors

This project ships three independent app flavors from the same repository:

- `client` - passenger app
- `captain` - driver/captain app
- `dashboard` - operations dashboard

## Run

```sh
flutter run --flavor client
flutter run --flavor captain
flutter run --flavor dashboard
```

For explicit CI or IDE runs, include the define file:

```sh
flutter run --flavor client --dart-define-from-file=config/flavors/client.json
flutter run --flavor captain --dart-define-from-file=config/flavors/captain.json
flutter run --flavor dashboard --dart-define-from-file=config/flavors/dashboard.json
```

## Build Outputs

```sh
flutter build apk --flavor client --release --dart-define-from-file=config/flavors/client.json
flutter build apk --flavor captain --release --dart-define-from-file=config/flavors/captain.json
flutter build apk --flavor dashboard --release --dart-define-from-file=config/flavors/dashboard.json

flutter build ios --flavor client --release --dart-define-from-file=config/flavors/client.json
flutter build ios --flavor captain --release --dart-define-from-file=config/flavors/captain.json
flutter build ios --flavor dashboard --release --dart-define-from-file=config/flavors/dashboard.json
```

Android output variants are generated under `build/app/outputs/flutter-apk/`
and app bundles under `build/app/outputs/bundle/`.

## Configuration

Runtime configuration is centralized in `lib/core/flavors/`.

Each flavor can override:

- app name
- bundle/application ID
- Supabase URL
- Supabase publishable key
- Firebase options file path when Firebase is added

Use `config/flavors/*.json` in CI and keep sensitive production values in the CI
secret store. Supabase publishable keys are client-side keys, but service-role
keys must never be placed in these files.

## Branding Assets

Flavor-specific launcher icon and splash configs live in:

- `config/icons/flutter_launcher_icons_client.yaml`
- `config/icons/flutter_launcher_icons_captain.yaml`
- `config/icons/flutter_launcher_icons_dashboard.yaml`
- `config/splash/flutter_native_splash_client.yaml`
- `config/splash/flutter_native_splash_captain.yaml`
- `config/splash/flutter_native_splash_dashboard.yaml`

Generate assets per flavor after replacing the image paths:

```sh
dart run flutter_launcher_icons -f config/icons/flutter_launcher_icons_client.yaml
dart run flutter_native_splash:create --path=config/splash/flutter_native_splash_client.yaml
```

Repeat for `captain` and `dashboard` whenever branding changes.
