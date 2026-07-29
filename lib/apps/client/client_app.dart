import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/routes/client_cubit_scopes.dart';
import 'package:bmt_app/apps/client/core/routes/client_router.dart';
import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_theme_store.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/client_splash_gate.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/client_push_destination.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/core/notifications/fcm_service.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Root of the Client App: owns bootstrapping (DI, theme restore, FCM/auth
/// wiring) and hands routing to [ClientRouter].
class ClientApp extends StatefulWidget {
  const ClientApp({super.key});

  @override
  State<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _themeStore = ClientThemeStore();
  final _appLinks = AppLinks();
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    registerClientDependencies();
    _restoreThemeMode();
    _listenAuth();
    _listenDeepLinks();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  void _setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    setState(() => _themeMode = mode);
    _themeStore.write(mode);
  }

  Future<void> _restoreThemeMode() async {
    final stored = await _themeStore.read();
    if (!mounted || stored == _themeMode) return;
    setState(() => _themeMode = stored);
  }

  void _listenAuth() {
    final supabase = Supabase.instance.client;

    // Initialise FCM for a session that already exists at startup.
    final current = supabase.auth.currentSession;
    if (current != null) {
      _initFcm(supabase, current.user.id);
    }

    // Track future sign-in / sign-out events.
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final session = state.session;
      if (session != null) {
        _initFcm(supabase, session.user.id);
      } else {
        FcmService.instance.deactivateToken(supabase);
      }
    });
  }

  void _initFcm(SupabaseClient supabase, String userId) {
    FcmService.instance.initialize(
      userId: userId,
      appType: 'client',
      supabase: supabase,
      navigatorKey: _navigatorKey,
      resolveDestination: clientPushDestination,
    );
  }

  /// Watches for the `easyway://reset-password/...` link a password-recovery
  /// email opens the app with.
  ///
  /// `supabase_flutter` already listens for this same link internally (via
  /// its own `AppLinks` instance) to exchange its code for a session — see
  /// `ResetPasswordCubit`'s doc comment. `AppLinks()` is a singleton over a
  /// broadcast stream, so subscribing here too is safe and does not steal
  /// events from that internal listener; this subscription exists purely to
  /// navigate to the reset-password screen, reusing the same `navigatorKey`
  /// pattern `FcmService` uses to push routes from outside a widget context.
  void _listenDeepLinks() {
    _appLinks.getInitialLink().then(_handleDeepLink);
    _deepLinkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != 'easyway' || uri.host != 'reset-password') return;
    _navigatorKey.currentState?.pushNamed(AuthRoutes.resetPassword);
  }

  @override
  Widget build(BuildContext context) {
    return ClientAppTheme(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return BlocProvider<OnboardingCubit>(
            create: (_) => clientGetIt<OnboardingCubit>()..checkStatus(),
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              title: AppFlavorConfig.current.appName,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              localeResolutionCallback: (_, supported) =>
                  _resolveLocale(locale, supported),
              theme: ClientTheme.light(),
              darkTheme: ClientTheme.dark(),
              themeMode: _themeMode,
              home: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, onboardingState) {
                  return ClientSplashGate(
                    isReady:
                        onboardingState is OnboardingLoaded ||
                        onboardingState is OnboardingError,
                    builder: (_) => _LandingScreen(state: onboardingState),
                  );
                },
              ),
              routes: ClientRouter.routes,
              // Notification taps (in-app and FCM) push `action_url` straight
              // from the database, so an unrecognised value must land somewhere
              // harmless instead of throwing on a route that does not exist.
              onUnknownRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ClientRouter.buildShell(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Resolves against the app's selected [locale] rather than the device's:
  /// the in-app language picker is the source of truth here.
  Locale _resolveLocale(Locale locale, Iterable<Locale> supported) {
    for (final supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return supported.first;
  }
}

/// Screen shown once the splash is dismissed: onboarding for first-time users,
/// the shell for an authenticated session, welcome otherwise.
class _LandingScreen extends StatelessWidget {
  const _LandingScreen({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final onboardingState = state;
    if (onboardingState is OnboardingLoaded &&
        !onboardingState.hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // currentSession covers the case where the stream has not emitted yet.
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return ClientRouter.buildShell();
        }
        return ClientCubitScopes.auth(const WelcomeScreen());
      },
    );
  }
}
