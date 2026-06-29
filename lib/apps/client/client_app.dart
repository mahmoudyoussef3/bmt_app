import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/core/notifications/fcm_service.dart';
import 'package:bmt_app/apps/client/core/routes/app_router.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/screens/client_shell_screen.dart';
import 'package:bmt_app/apps/client/modules/trips/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/modules/trips/trips/presentation/screens/my_trips_screen.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/modules/notifications/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/modules/notifications/notifications/presentation/screens/notifications_screen.dart';
import 'package:bmt_app/apps/client/modules/account/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/modules/account/profile/presentation/screens/profile_screen.dart';
import 'package:bmt_app/apps/client/modules/services/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/modules/services/routes/presentation/screens/routes_hub_screen.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/screens/client_splash_screen.dart';
import 'package:bmt_app/apps/client/modules/account/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bmt_app/apps/client/modules/account/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:bmt_app/apps/client/modules/account/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';

class ClientApp extends StatefulWidget {
  const ClientApp({super.key});

  @override
  State<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;

  void _setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  void initState() {
    super.initState();
    registerClientDependencies();
    _listenAuth();
  }

  void _listenAuth() {
    final supabase = Supabase.instance.client;

    // Initialise FCM for a session that already exists at startup.
    final current = supabase.auth.currentSession;
    if (current != null) {
      FcmService.instance.initialize(
        userId: current.user.id,
        appType: 'client',
        supabase: supabase,
        navigatorKey: _navigatorKey,
      );
    }

    // Track future sign-in / sign-out events.
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final session = state.session;
      if (session != null) {
        FcmService.instance.initialize(
          userId: session.user.id,
          appType: 'client',
          supabase: supabase,
          navigatorKey: _navigatorKey,
        );
      } else {
        FcmService.instance.deactivateToken(supabase);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
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
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              theme: ClientTheme.light(),
              darkTheme: ClientTheme.dark(),
              themeMode: _themeMode,

              home: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, onboardingState) {
                  if (onboardingState is OnboardingLoading ||
                      onboardingState is OnboardingInitial) {
                    return const ClientSplashScreen();
                  }

                  if (onboardingState is OnboardingLoaded &&
                      !onboardingState.hasSeenOnboarding) {
                    return const OnboardingScreen();
                  }

                  return StreamBuilder<AuthState>(
                    stream: Supabase.instance.client.auth.onAuthStateChange,
                    builder: (context, snapshot) {
                      // Also check currentSession as initial state might not emit immediately
                      final session =
                          snapshot.data?.session ??
                          Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return _buildClientShell();
                      }
                      return _buildAuthScope(const WelcomeScreen());
                    },
                  );
                },
              ),

              onGenerateRoute: AppRouter.generateRoute,
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientShell() {
    return ClientShellScreen(
      routesBuilder: (context) => _buildRoutesHubScope(
        RoutesHubScreen(
          onOpenRoute: (route, [arguments]) {
            Navigator.of(context).pushNamed(route, arguments: arguments);
          },
        ),
      ),
      tripsBuilder: (context) => _buildTripsScope(
        MyTripsScreen(
          onOpenRoute: (route, [arguments]) {
            Navigator.of(context).pushNamed(route, arguments: arguments);
          },
        ),
      ),
      profileBuilder: (context) => _buildProfileScope(
        ProfileScreen(
          onOpenRoute: (route, [arguments]) {
            Navigator.of(context).pushNamed(route, arguments: arguments);
          },
        ),
      ),
      notificationsBuilder: (context) =>
          _buildNotificationsScope(const NotificationsScreen()),
    );
  }

  Widget _buildAuthScope(Widget child) {
    return BlocProvider<ClientAuthCubit>(
      create: (_) => clientGetIt<ClientAuthCubit>(),
      child: child,
    );
  }

  Widget _buildTripsScope(Widget child) {
    return BlocProvider<TripsCubit>(
      create: (_) => clientGetIt<TripsCubit>(),
      child: child,
    );
  }

  Widget _buildNotificationsScope(Widget child) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => clientGetIt<NotificationsCubit>(),
      child: child,
    );
  }

  Widget _buildProfileScope(Widget child) {
    return BlocProvider<ProfileCubit>(
      create: (_) => clientGetIt<ProfileCubit>(),
      child: child,
    );
  }

  Widget _buildRoutesHubScope(Widget child) {
    return BlocProvider<RoutesHubCubit>(
      create: (_) => clientGetIt<RoutesHubCubit>(),
      child: child,
    );
  }

}
