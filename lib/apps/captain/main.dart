import 'dart:async';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/screens/captain_login_screen.dart';
import 'package:bmt_app/core/flavors/app_bootstrap.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/core/notifications/fcm_service.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
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
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: AppFlavorConfig.current.appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: CaptainTheme.light(),
          darkTheme: CaptainTheme.dark(),
          themeMode: ThemeMode.system,
          home: const _CaptainAuthGate(),
          routes: {
            '/captain/home': (_) => const CaptainAppShell(),
          },
        );
      },
    );
  }
}

/// Shows CaptainLoginScreen when no session, CaptainAppShell when signed in.
class _CaptainAuthGate extends StatelessWidget {
  const _CaptainAuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null) return const CaptainAppShell();

        return BlocProvider(
          create: (_) => captainGetIt<CaptainAuthCubit>(),
          child: const CaptainLoginScreen(),
        );
      },
    );
  }
}
