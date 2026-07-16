# CLAUDE.md — Flutter Engineering Playbook

This file is my permanent, project-agnostic **Flutter engineering standard**. It documents *how I build
Flutter software* — the architecture, conventions, and practices every project of mine should follow.
It is written to be dropped into **any** Flutter repository unchanged. Read it fully before writing any code.

> **How to use this playbook:** These rules are the target state. Before writing code, **inspect the
> current repository** and adapt names to what it already provides:
> 1. Read `pubspec.yaml` for the **package name** (used in `package:<app_name>/...` imports) and the
>    dependencies already present.
> 2. Scan `lib/` for the existing structure, core primitives (theming, DI, networking, routing), and
>    naming already in use.
> 3. Apply these standards to **new** code. Reuse whatever core primitives already exist; only create the
>    ones that are missing, following the names and shapes described here.
>
> Throughout this document, `<app_name>` means the project's Dart package name from `pubspec.yaml`, and
> `<feature>` / `<Feature>` / `<Entity>` are placeholders you substitute per feature.

> **Golden rule (respect existing code):** When working inside an established codebase, **match the
> conventions of the file you are editing**. Do **not** refactor, rename, move, reformat, or "optimize"
> existing source unless the task explicitly asks for a change to that specific file. Add new code that
> matches the surrounding style; keep every diff scoped to the task.

---

## 1. Architecture Philosophy

Every project follows **feature-first Clean Architecture** with a strict, one-directional dependency rule:

```
Presentation  ──depends on──▶  Domain  ◀──implemented by──  Data
   (logic + ui)                (contracts)                  (network/storage)
```

- **SOLID / OOP / Clean Code** underpin everything: single-responsibility classes, dependency inversion
  (depend on abstractions), small composable units, expressive names, no duplicated infrastructure.
- **Domain is the center** and knows nothing about Flutter, networking, or serialization.
- **Presentation** and **Data** both depend on Domain; they never depend on each other.
- The app is composed of **features**; cross-cutting building blocks live in **`core/`**.

### App entry flow (bootstrapping order)
```
lib/main_<flavor>.dart
  → WidgetsFlutterBinding.ensureInitialized()
  → setupGetIt()                       // dependency injection
  → ScreenUtil.ensureScreenSize()
  → <startup checks>                    // e.g. read auth token from secure storage into a global flag
  → runApp(MyApp(appRouter: AppRouter()))
```
The root widget wraps `MaterialApp` in `ScreenUtilInit(designSize: Size(375, 812))` (set the design canvas
once) and picks the initial route from startup state. Use **flavors** (e.g. `Development` / `Production`)
with one entry point per flavor (`lib/main_development.dart`, `lib/main_production.dart`).

---

## 2. Tech Stack & Key Packages

Keep the stack consistent across projects. Do not introduce alternative state-management, DI, or
networking libraries.

| Concern | Package |
|---|---|
| State management | `flutter_bloc` (**Cubit only**, no Bloc/events) |
| Immutable state / unions | `freezed` + `freezed_annotation` |
| Dependency injection | `get_it` (service locator, global `getIt`) |
| Networking | `dio` + `retrofit` + `retrofit_generator` + `pretty_dio_logger` |
| JSON | `json_serializable` + `json_annotation` |
| Code generation | `build_runner` |
| Responsive sizing | `flutter_screenutil` (`.w`, `.h`, `.sp`, `.r`) |
| Local storage | `shared_preferences` (plain) + `flutter_secure_storage` (tokens/secrets) |
| Images | `cached_network_image`, `flutter_svg`, `shimmer` (loading placeholders) |
| Localization (opt-in) | `easy_localization` + `intl` |
| Lints | `flutter_lints` (default rule set via `analysis_options.yaml`) |

> Localization and Firebase are **opt-in**: wire them only when the project actually uses them
> (see §7 for localization). Don't assume either is active just because a dependency is present.

---

## 3. Recommended Folder Structure

```
lib/
├── main_development.dart          # Dev flavor entry point
├── main_production.dart           # Prod flavor entry point
├── my_app.dart                    # Root MaterialApp + ScreenUtilInit
│
├── core/                          # Cross-feature building blocks (no feature logic)
│   ├── di/
│   │   └── dependency_injection.dart   # getIt + setupGetIt()
│   ├── helpers/
│   │   ├── app_regex.dart               # Email/password/phone validation
│   │   ├── constants.dart               # Global flags + SharedPrefKeys
│   │   ├── extensions.dart              # Navigation + isNullOrEmpty extensions
│   │   ├── shared_pref_helper.dart      # SharedPreferences + FlutterSecureStorage wrapper
│   │   └── spacing.dart                 # verticalSpace() / horizontalSpace()
│   ├── networking/
│   │   ├── api_constants.dart           # Base URL + shared endpoints + error strings
│   │   ├── api_error_handler.dart       # DataSource enum, ResponseCode, ErrorHandler
│   │   ├── api_error_model.dart         # @JsonSerializable ApiErrorModel
│   │   ├── api_result.dart              # @freezed ApiResult<T> = Success | Failure
│   │   ├── api_service.dart             # @RestApi central client (shared/auth calls)
│   │   └── dio_factory.dart             # Dio singleton + headers + interceptors
│   ├── routing/
│   │   ├── app_router.dart              # onGenerateRoute switch + BlocProvider wiring
│   │   └── routes.dart                  # Route name string constants
│   ├── theming/
│   │   ├── colors.dart                  # ColorsManager
│   │   ├── font_weight_helper.dart      # FontWeightHelper
│   │   └── styles.dart                  # TextStyles
│   └── widgets/
│       ├── app_text_button.dart         # Shared button
│       └── app_text_form_field.dart     # Shared input field
│
└── features/
    └── <feature>/
        ├── data/
        │   ├── models/         # @JsonSerializable DTOs (fromJson/toJson)
        │   ├── datasources/    # Retrofit ApiService(s) + any local sources
        │   ├── mappers/        # model → entity conversions
        │   └── repos/          # Repository IMPLEMENTATION (implements domain contract)
        ├── domain/
        │   ├── entities/       # Pure Dart objects the app logic uses (no JSON annotations)
        │   ├── repos/          # Abstract repository INTERFACES (contracts)
        │   └── usecases/       # One class per action; calls repo interface; returns ApiResult<Entity>
        └── presentation/       # (a.k.a. logic + ui)
            ├── logic/          # Cubit + freezed State (depends on usecases only)
            └── ui/             # Screen + widgets/
```

**Simple / presentation-only features** (static screens, onboarding-style flows with no network or
business logic) may use a lighter shape: just `ui/` (+ `widgets/`), adding `logic/` with a Cubit only if
they hold state. Anything that fetches or mutates data uses the full three layers above.

---

## 4. Layer Rules (dependency direction)

```
features/<feature>/
├── data/     # DTOs, datasources (Retrofit/local), mappers, repo IMPLEMENTATIONS — talks to network/storage
├── domain/   # entities, repo INTERFACES, use cases — pure Dart contracts the app logic uses
└── presentation/  # Cubit + freezed State + Screen + widgets — presentation only
```

Data flow:
```
UI (Screen/Widget)
  → context.read<Cubit>().someAction()
    → UseCase.call(...)
      → Repo interface (implemented in data/)
        → DataSource (Retrofit) → Dio → Backend
      ← ApiResult.success(entity) | ApiResult.failure(ErrorHandler)
  ← Cubit emits freezed State
UI rebuilds via BlocBuilder / reacts via BlocListener
```

Rules:
- **Presentation depends only on Domain** (use cases + entities). It never imports `data/`.
- **Data implements Domain contracts.** `data/repos/<x>_repo_impl.dart` implements
  `domain/repos/<x>_repo.dart`.
- **Use cases** are single-responsibility (`Get<Noun>UseCase`, `LoginUseCase`), depend on a repo
  **interface**, and return `ApiResult<T>` where `T` is a **domain entity**, not a network model.
- **Mappers** convert `data/models` → `domain/entities` inside the repo implementation — never in the
  Cubit or UI.
- **Domain is pure Dart:** no `package:flutter/...`, `dio`, `retrofit`, or `json_annotation` imports.
- Reuse the shared `core/` primitives (`ApiResult`, `ErrorHandler`, `DioFactory`, theming, spacing,
  extensions, shared widgets). Never reinvent them.

See `.claude/docs/ARCHITECTURE.md` for a full worked example.

---

## 5. State Management Conventions (Cubit + Freezed)

**Always Cubit, never Bloc** (no events). Each feature has one Cubit and one freezed State.

### Cubit rules
- Class name: `<Feature>Cubit extends Cubit<<Feature>State>`.
- Constructor injects the use case (new features) or repo: `<Feature>Cubit(this._useCase) : super(const <Feature>State.initial());`.
- The Cubit **owns** its form state when relevant: `TextEditingController`s and
  `final formKey = GlobalKey<FormState>();` live in the Cubit; UI reads them via
  `context.read<<Feature>Cubit>().emailController`.
- Public action method named `emit<Feature>States()` (auth-style) or a verb (`get<Noun>()`).
- Call the use case/repo, then branch with `response.when(success: ..., failure: ...)`.
- Emit `loading` before the call, `success(data)` / `error(message)` after.

```dart
void emitLoginStates() async {
  emit(const LoginState.loading());
  final response = await _loginUseCase(
    LoginRequestBody(email: emailController.text, password: passwordController.text),
  );
  response.when(
    success: (data) async {
      await saveUserToken(data.userData?.token ?? '');
      emit(LoginState.success(data));
    },
    failure: (error) => emit(LoginState.error(error: error.apiErrorModel.message ?? '')),
  );
}
```

### State rules (freezed union)
- `@freezed`, `part '<name>.freezed.dart';`.
- **Auth/simple** states use a generic `<T>` for the success payload:

```dart
@freezed
class LoginState<T> with _$LoginState<T> {
  const factory LoginState.initial() = _Initial;
  const factory LoginState.loading() = Loading;
  const factory LoginState.success(T data) = Success<T>;
  const factory LoginState.error({required String error}) = Error;
}
```

- **Multi-concern** states (one Cubit driving several independent UI regions) declare **explicit typed**
  factories per concern and prefix constructor names (e.g. `listLoading`, `detailSuccess`, …) so
  `buildWhen`/`listenWhen` can target them.

### UI ↔ State wiring
- **`BlocBuilder`** builds UI from state; always use `buildWhen` to rebuild only on relevant states, and
  `state.maybeWhen(..., orElse: () => const SizedBox.shrink())`.
- **`BlocListener`** handles side effects (loading dialog, success navigation, error dialog). It lives in
  its own widget file `<feature>_bloc_listener.dart`, uses `listenWhen`, `state.whenOrNull(...)`, and
  renders `const SizedBox.shrink()`.
- Provide Cubits at the route via `BlocProvider` in `app_router.dart` (see §8).

---

## 6. Networking & API Conventions

### Retrofit service (`data/datasources/` or `core/networking/api_service.dart`)
```dart
part '<feature>_api_service.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class <Feature>ApiService {
  factory <Feature>ApiService(Dio dio) = _<Feature>ApiService;

  @GET(<Feature>ApiConstants.<name>EP)
  Future<<Feature>ResponseModel> get<Feature>();
}
```
- Central/shared calls (e.g. `login`, `signup`) live in `core/networking/api_service.dart`.
- **Feature-specific** endpoints get their own service in
  `features/<feature>/data/datasources/<feature>_api_service.dart` plus a `<feature>_api_constants.dart`
  holding endpoint path strings.
- Endpoint **paths** are constants: shared ones in `ApiConstants`, feature ones in `<Feature>ApiConstants`.
  Base URL always comes from `ApiConstants.apiBaseUrl`.
- Use `@Body()` for request bodies, `@Query()`/`@Path()` as needed.

### Dio (`core/networking/dio_factory.dart`)
- `DioFactory` is a private-constructor singleton returning **one shared** `Dio`.
- Headers: `Accept: application/json` + `Authorization: Bearer <token>` (token from secure storage).
- After login, call `DioFactory.setTokenIntoHeaderAfterLogin(token)`.
- Attach `PrettyDioLogger`; set sensible timeouts.
- **Never construct `Dio` anywhere else** — always go through `DioFactory.getDio()` and register the
  ApiService in DI with that `dio`.

### Result & error handling
- Repos never throw to callers. They return `ApiResult<T>` (a `@freezed` union: `Success<T>` / `Failure`).
- On error, `ErrorHandler.handle(error)` maps a `DioException`/anything to an `ApiErrorModel`
  (`code` + `message`), wrapped in `ApiResult.failure(...)`.
- The Cubit reads `error.apiErrorModel.message` for user-facing text.

---

## 7. Models & JSON Conventions

- Annotate with `@JsonSerializable()` and add `part '<file>.g.dart';`.
- **Request bodies** (`<X>RequestBody`): fields, constructor, and `toJson()` only.
- **Responses** (`<X>Response` / `<X>ResponseModel`): fields, constructor, and `factory X.fromJson(...)`.
- Rename mismatched JSON keys with `@JsonKey(name: 'server_key')` (e.g. `password_confirmation`, `data`,
  `created_at`, `username`).
- Response fields are typically **nullable** (`String?`, `int?`, `List<T?>?`). Be defensive.
- One model file may hold several related classes.
- Every data model in a Clean Architecture feature is paired with a **`domain/entities/` entity** (plain
  Dart, no annotations) and a **mapper** (`data/mappers/`).
- After adding/changing any model, **run build_runner** (§9).

### Localization (opt-in)
Adopt localization only when the project needs it:
1. Add `assets/translations/{en.json, ...}` and register `assets/translations/` in `pubspec.yaml`.
2. `await EasyLocalization.ensureInitialized();`, wrap `runApp` with `EasyLocalization(...)`, and add its
   delegates + `supportedLocales` + `locale` to `MaterialApp`.
3. Replace strings with `'key'.tr()`. When retrofitting, scope changes to the target screens rather than
   rewriting the whole app at once.

---

## 8. Routing & Navigation

- Route names are string constants in `core/routing/routes.dart`
  (e.g. `Routes.homeScreen = '/homeScreen'`).
- `AppRouter.generateRoute` is a `switch (settings.name)` returning `MaterialPageRoute`s. Screens that need
  a Cubit are wrapped in a `BlocProvider` here:

```dart
case Routes.<feature>Screen:
  return MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => getIt<<Feature>Cubit>()..get<Feature>(),
      child: const <Feature>Screen(),
    ),
  );
```
- Navigate via the `Navigation` extension on `BuildContext` (in `extensions.dart`):
  `context.pushNamed(Routes.x)`, `context.pushReplacementNamed(...)`,
  `context.pushNamedAndRemoveUntil(..., predicate: ...)`, `context.pop()`.
  **Never** call `Navigator.of(context)` directly in feature code.
- Adding a screen = add a `Routes` constant + a `case` in `AppRouter` + (if it uses a Cubit) a `BlocProvider`.

---

## 9. Code Generation (build_runner)

Anything with `part '*.g.dart'` (json/retrofit) or `part '*.freezed.dart'` (freezed/state) requires codegen.

```bash
# One-off build (after adding/editing models, states, or Retrofit services)
dart run build_runner build --delete-conflicting-outputs

# Watch mode during active development
dart run build_runner watch --delete-conflicting-outputs
```

- Generated files (`*.g.dart`, `*.freezed.dart`) are committed — regenerate and commit them together with
  the source change.
- **Never hand-edit** generated files.
- If a build fails: `flutter clean && flutter pub get`, then rebuild.

---

## 10. Naming & File Conventions

| Thing | Convention | Example |
|---|---|---|
| Files & folders | `snake_case` | `login_bloc_listener.dart` |
| Classes / enums | `PascalCase` | `LoginCubit`, `DataSource` |
| Variables / methods | `lowerCamelCase` | `emailController`, `emitLoginStates()` |
| Constants | `lowerCamelCase` static consts | `Routes.homeScreen`, `ApiConstants.login` |
| Screen widget | `<Feature>Screen` | `LoginScreen` |
| Cubit | `<Feature>Cubit` | `LoginCubit` |
| State | `<Feature>State` (freezed) | `LoginState` |
| Repo interface / impl | `<Feature>Repo` / `<Feature>RepoImpl` | `LoginRepo` / `LoginRepoImpl` |
| Retrofit service | `<Feature>ApiService` | `HomeApiService` |
| Request model | `<Name>RequestBody` | `LoginRequestBody` |
| Response model | `<Name>Response` / `<Name>ResponseModel` | `LoginResponse` |
| Endpoint constants | `<Feature>ApiConstants` | `HomeApiConstants` |
| Use case | `<Verb><Noun>UseCase` | `GetItemsUseCase` |
| Entity | `<Noun>` (no suffix) | `Item` |
| Mapper | `<Name>Mapper` (extension) | `ItemMapper` |

- One screen per file; break screens into small widget files under `ui/widgets/` (further grouped into
  sub-folders when a screen has widget clusters, e.g. `<feature>/ui/widgets/<cluster>/`).
- `const` constructors everywhere possible.

---

## 11. Theming & Styling Conventions

- **Colors:** only from `ColorsManager` (`core/theming/colors.dart`). Define a primary color and reference
  it everywhere. Do **not** hardcode `Color(0x...)` in widgets — add to `ColorsManager` if truly new.
- **Text styles:** only from `TextStyles` (`core/theming/styles.dart`). Naming pattern
  `font<Size><Color><Weight>` (e.g. `font16WhiteSemiBold`). Reuse existing; add a new static field if
  needed rather than inlining a `TextStyle`. Use `.copyWith(...)` for one-off tweaks.
- **Font weights:** via `FontWeightHelper` (`regular`, `medium`, `semiBold`, `bold`, …).
- **Sizing (ScreenUtil):** append `.w` / `.h` / `.sp` / `.r` to numbers. Font sizes use `.sp`, widths `.w`,
  heights `.h`, radii `.r`. Set the design canvas once in `ScreenUtilInit` (e.g. 375×812).
- **Spacing:** use `verticalSpace(n)` / `horizontalSpace(n)` from `core/helpers/spacing.dart` instead of
  raw `SizedBox`.
- **Shared widgets:** reuse `AppTextButton` and `AppTextFormField` for buttons/inputs.
- **Images:** SVGs via `SvgPicture.asset('assets/svgs/...')`; network images via `CachedNetworkImage` with
  a `Shimmer.fromColors` placeholder. Register asset directories in `pubspec.yaml`.

---

## 12. Dependency Injection Conventions

`core/di/dependency_injection.dart` holds `final getIt = GetIt.instance;` and `Future<void> setupGetIt()`.

Registration patterns:
- **Dio + ApiService:** build Dio once via `DioFactory.getDio()`, register `ApiService` as
  `registerLazySingleton` with that `dio`.
- **DataSources / Repos / Use cases:** `getIt.registerLazySingleton<T>(() => T(getIt()));`
  (bind repo implementations to their **interface** type).
- **Cubits:** `getIt.registerFactory<Cubit>(() => Cubit(getIt()));` (fresh instance per screen).
  Constructing a Cubit inline in the router (`<Feature>Cubit(getIt())..init()`) is also acceptable — follow
  the pattern the feature already uses.

When you add a feature, register its DataSource → Repo impl (bound to interface) → Use cases → Cubit in
`setupGetIt()`, and either register the Cubit or construct it in the router.

---

## 13. Development Workflow (quick version)

Full details in `.claude/docs/WORKFLOWS.md`. To add a feature:

1. Create the folder skeleton (§3).
2. **Data:** models (`@JsonSerializable`) → Retrofit service + endpoint constants.
3. **Domain:** entities → repo interface → use cases.
4. **Data:** mappers → repo implementation (returns `ApiResult<Entity>`).
5. **Presentation:** freezed State → Cubit → Screen + widgets → BlocListener/BlocBuilder.
6. Register everything in `setupGetIt()`; add a route + `BlocProvider` in `AppRouter`.
7. `dart run build_runner build --delete-conflicting-outputs`.
8. `flutter analyze` (0 new issues) and run the app.
9. Commit source **and** generated files together.

### Running the app
```bash
flutter pub get
flutter run --flavor Development -t lib/main_development.dart   # dev
flutter run --flavor Production  -t lib/main_production.dart    # prod
```

### Before every commit / PR
- `dart run build_runner build --delete-conflicting-outputs` if any annotated file changed.
- `flutter analyze` → 0 new warnings/errors.
- `dart format` **only** on files you created/edited — never bulk-format the repo.
- Keep PRs scoped to one feature/fix; target the repository's integration branch.

---

## 14. Do's and Don'ts

### ✅ Do
- Match the existing style of the file you are editing; keep diffs minimal and scoped.
- Reuse `core/` primitives: `ApiResult`, `ErrorHandler`, `DioFactory`, theming, spacing, extensions,
  `AppTextButton`, `AppTextFormField`.
- Use Cubit + freezed states with `when`/`maybeWhen`/`whenOrNull` and `buildWhen`/`listenWhen`.
- Put endpoint paths in `*ApiConstants`, colors in `ColorsManager`, text styles in `TextStyles`.
- Navigate through the `context` `Navigation` extension and `Routes` constants.
- Run build_runner after touching any `@freezed` / `@JsonSerializable` / `@RestApi` file, and commit the
  generated output.
- Follow the Clean Architecture split (§3–§4) for every data-driven feature.

### ❌ Don't
- Don't refactor, rename, move, or reformat existing files unprompted.
- Don't hand-edit `*.g.dart` / `*.freezed.dart`.
- Don't create raw `Dio` instances, call `Navigator.of(context)` directly, or hardcode
  colors/text styles/URLs.
- Don't introduce new state-management, DI, or networking libraries — stick to the stack in §2.
- Don't let Presentation import `data/`, or Domain import Flutter/Dio/Retrofit/json.
- Don't hardcode raw pixel numbers without ScreenUtil extensions in new UI.

---

## 15. The Claude Workspace

This playbook ships with a tailored Claude Code workspace under `.claude/`:

- **`.claude/agents/`** — specialized sub-agents (architect, feature-builder, api/repository/cubit/ui/
  theme/localization/model/build-runner/bugfix/code-reviewer/dependency engineers). Delegate focused work
  to the matching agent.
- **`.claude/skills/`** — step-by-step generators that follow these conventions (`create-feature`,
  `create-cubit`, `create-repository`, `create-retrofit-api`, `create-model`, `create-entity`,
  `create-usecase`, `create-mapper`, `create-state`, `create-screen`, `create-datasource`,
  `create-bloc-listener`, `create-dialog`, `register-dependency`, `add-route`, `run-build-runner`,
  `review-feature`).
- **`.claude/commands/`** — slash commands (`/build-runner`, `/new-feature`, `/review-feature`,
  `/analyze-project`, `/gen-clean`).
- **`.claude/docs/`** — deep-dive references: `ARCHITECTURE.md`, `WORKFLOWS.md`, `CONVENTIONS.md`,
  `CHECKLISTS.md`.
- **`.claude/hooks/` + `.claude/settings.json`** — advisory hooks (codegen reminders, pre-commit checks,
  convention validation).

When in doubt, prefer the skill/agent for the task over ad-hoc code, first inspect the repository to learn
its package name and existing primitives, and keep every change consistent with this document.
