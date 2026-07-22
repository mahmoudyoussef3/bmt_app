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

### Native splash

`flutter_native_splash` writes into `android/app/src/main/res` and the single
`LaunchScreen.storyboard`, both of which every flavor builds against — there is
no per-flavor output. The three splash configs are therefore **deliberately
identical**, so regenerating one flavor can't silently overwrite another's
branding. App-specific identity begins at the Flutter splash the OS frame hands
off to.

The splash artwork is generated, not hand-drawn:

```sh
python3 tool/generate_splash_assets.py    # requires Pillow
dart run flutter_native_splash:create --path=config/splash/flutter_native_splash_client.yaml
```

The script derives everything in `assets/branding/` from
`assets/images/app_icon.png`, so the launcher icon, the OS launch frame and the
in-app brand tile stay the same mark. Two constraints it exists to enforce:

- **Size.** `flutter_native_splash` reads the source as 4x artwork, so a 1024px
  image lands at 256dp — two thirds of a phone's width. The tile is baked at
  96dp, matching `kSplashBrandMarkSize` (client) and `_brandMarkSize` (captain)
  so the mark doesn't move or resize when Flutter takes over. Change one, change
  the other.
- **Android 12+ safe area.** The platform clips the splash icon to a 768px
  circle on a 1152px canvas, so that variant is composed separately and drops
  the shadow, which the mask would otherwise slice into a visible arc.

Never point a splash config straight at `assets/images/app_icon.png`.
