import 'dart:async';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/core/flavors/app_bootstrap.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/core/notifications/fcm_service.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
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

    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final session = state.session;
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
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          home: const CaptainAppShell(),
          routes: {
            '/captain/home': (_) => const CaptainAppShell(),
            '/captain/trips': (_) => const CaptainAppShell(),
          },
        );
      },
    );
  }
}
