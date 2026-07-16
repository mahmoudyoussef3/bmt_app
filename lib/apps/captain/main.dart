import 'dart:async';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_router.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/screens/captain_login_screen.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/cubit/captain_onboarding_cubit.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/screens/captain_onboarding_flow.dart';
import 'package:bmt_app/apps/captain/features/onboarding/presentation/screens/captain_welcome_home.dart';
import 'package:bmt_app/core/flavors/app_bootstrap.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';

import 'package:bmt_app/core/notifications/fcm_service.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await bootstrapFlavorApp(AppFlavor.captain);
}

class CaptainApp extends StatefulWidget {
  const CaptainApp({super.key});

  @override
  State<CaptainApp> createState() => _CaptainAppState();
}

class _CaptainAppState extends State<CaptainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _listenAuth();
  }

  void _listenAuth() {
    final supabase = Supabase.instance.client;

    final current = supabase.auth.currentSession;
    if (current != null) {
      FcmService.instance.initialize(
        userId: current.user.id,
        appType: 'captain',
        supabase: supabase,
        navigatorKey: _navigatorKey,
      );
    }

    _authSub = supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null) {
        FcmService.instance.initialize(
          userId: session.user.id,
          appType: 'captain',
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
    return BlocProvider<CaptainThemeCubit>(
      create: (_) => captainGetIt<CaptainThemeCubit>()..load(),
      child: BlocBuilder<CaptainThemeCubit, CaptainThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: AppFlavorConfig.current.appName,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            theme: CaptainTheme.light(),
            darkTheme: CaptainTheme.dark(),
            themeMode: themeState.themeMode,
            home: const _CaptainAuthGate(),
            onGenerateRoute: CaptainAppRouter.generateRoute,
          );
        },
      ),
    );
  }
}

/// Routes the captain to the right root:
/// 1. Supabase auth session  → operational shell (existing captains)
/// 2. Local approved session → welcome home, which keeps trying to establish an
///    operational session and lands on the shell as soon as it can (1)
/// 3. A submitted request     → onboarding flow resumed at pending
/// 4. Otherwise               → sign in (with a request-access entry)
class _CaptainAuthGate extends StatefulWidget {
  const _CaptainAuthGate();

  @override
  State<_CaptainAuthGate> createState() => _CaptainAuthGateState();
}

class _CaptainAuthGateState extends State<_CaptainAuthGate> {
  final _store = captainGetIt<CaptainSessionStore>();

  bool _loading = true;
  CaptainLocalSession? _session;
  String? _pendingPhone;
  bool _requesting = false;
  StreamSubscription<AuthState>? _signOutSub;

  @override
  void initState() {
    super.initState();
    _reloadLocal();
    // The welcome home upgrades a local session into an operational one on
    // sight, so a local session that outlives a sign-out would immediately
    // sign the captain back in. Drop it with the operational session.
    _signOutSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      if (event.event == AuthChangeEvent.signedOut) _forgetLocalSession();
    });
  }

  @override
  void dispose() {
    _signOutSub?.cancel();
    super.dispose();
  }

  Future<void> _reloadLocal() async {
    final session = await _store.readSession();
    final pending = await _store.readPendingPhone();
    if (!mounted) return;
    setState(() {
      _session = session;
      _pendingPhone = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session != null) return const CaptainAppShell();

        if (_loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_session != null) return _welcomeHome(_session!);
        if (_pendingPhone != null || _requesting) return _onboarding();

        return BlocProvider(
          create: (_) => captainGetIt<CaptainAuthCubit>(),
          child: CaptainLoginScreen(
            onRequestAccess: () => setState(() => _requesting = true),
          ),
        );
      },
    );
  }

  Widget _welcomeHome(CaptainLocalSession session) {
    return CaptainWelcomeHome(session: session, onSignOut: _forgetLocalSession);
  }

  Future<void> _forgetLocalSession() async {
    await _store.clearSession();
    if (!mounted) return;
    setState(() {
      _session = null;
      _pendingPhone = null;
      _requesting = false;
    });
  }

  Widget _onboarding() {
    return BlocProvider(
      create: (_) =>
          captainGetIt<CaptainOnboardingCubit>()..init(_pendingPhone),
      child: CaptainOnboardingFlow(
        onEnterHome: (session) => setState(() {
          _session = session;
          _pendingPhone = null;
          _requesting = false;
        }),
        onBackToLogin: () => setState(() {
          _pendingPhone = null;
          _requesting = false;
        }),
      ),
    );
  }
}
