import 'package:bmt_app/apps/dashboard/main.dart';
import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/apps/client/client_app.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://nbwzourpbnmewwklewyr.supabase.co',
      anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
    );
  } catch (_) {
    // Avoid crashing in environments where Supabase is already initialized or connection is mock
  }

  registerCaptainDependencies();
  registerDashboardDependencies();

  runApp(
    BlocProvider(create: (_) => AppModeCubit()..load(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppModeCubit, AppModeState>(
      listener: (context, state) {
        _navKey.currentState?.pushNamedAndRemoveUntil(
          state.mode.routePath,
          (_) => false,
        );
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: _navKey,
        title: 'BMT App',
        theme: ThemeData(primarySwatch: Colors.blue),
        routes: {
          '/': (_) => const ClientApp(),
          '/driver': (_) => const CaptainAppShell(),
          '/admin': (_) => const DashboardWebApp(),
          '/ops-dashboard': (_) => const DashboardWebApp(),
        },
        initialRoute: '/',
      ),
    );
  }
}
