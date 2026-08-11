import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';
import 'core/di/dashboard_di.dart';
import 'core/routes/dashboard_shell.dart';
import 'features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'features/auth/presentation/screens/dashboard_login_screen.dart';
import 'features/auth/presentation/screens/dashboard_sign_up_screen.dart';
import 'core/theme/dashboard_app_theme.dart';
import 'core/theme/dashboard_theme_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';

/// The dashboard is an Arabic-only operational workspace: there is no language
/// switcher, so the locale is pinned rather than read from storage or system.
const String _dashboardLocale = 'ar';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppFlavorConfig.activate(AppFlavor.dashboard);
  final config = AppFlavorConfig.current;
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    httpClient: DioHttpClientAdapter(DioFactory.getDio()),
  );

  registerDashboardDependencies();

  runApp(const DashboardWebApp());
}

/// Decides between the login screen and the workspace.
///
/// The dashboard previously mounted [DashboardShell] unconditionally and talked to
/// Postgres as the anon role. With multiple offices that is no longer merely missing
/// a login — it would be every office sharing one unauthenticated workspace, so the
/// gate is mandatory rather than cosmetic.
class _DashboardAuthGate extends StatefulWidget {
  const _DashboardAuthGate();

  @override
  State<_DashboardAuthGate> createState() => _DashboardAuthGateState();
}

class _DashboardAuthGateState extends State<_DashboardAuthGate> {
  late final DashboardAuthCubit _cubit;

  /// Which of the two signed-out screens to show. Held here rather than pushed as a
  /// route because the dashboard has no navigator above the gate — `main` mounts it as
  /// `home:` — and because a successful sign-up must land on the shell, not on a screen
  /// with the sign-up form still underneath it.
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _cubit = dashboardDi<DashboardAuthCubit>()..restore();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardAuthCubit>.value(
      value: _cubit,
      child: BlocBuilder<DashboardAuthCubit, DashboardAuthState>(
        builder: (context, state) => switch (state) {
          DashboardAuthChecking() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          DashboardAuthSignedIn(:final context) => DashboardShell(
            key: ValueKey(context.officeId),
            office: context,
          ),
          _ when _registering => DashboardSignUpScreen(
            onBackToLogin: () => setState(() => _registering = false),
          ),
          _ => DashboardLoginScreen(
            onCreateOffice: () => setState(() => _registering = true),
          ),
        },
      ),
    );
  }
}

class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardThemeCubit>(
      create: (_) => dashboardDi<DashboardThemeCubit>()..load(),
      child: BlocBuilder<DashboardThemeCubit, DashboardThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppFlavorConfig.current.appName,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            
            locale: const Locale(_dashboardLocale),
            theme: DashboardAppTheme.light(),
            darkTheme: DashboardAppTheme.dark(),
            themeMode: themeState.themeMode,
            
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const _DashboardAuthGate(),
          );
        },
      ),
    );
  }
}
