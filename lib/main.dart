import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:bmt_app/features/component/presentation/component_demo_app.dart';
import 'package:bmt_app/features/component/presentation/screens/admin_dashboard_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/driver_dashboard_screen.dart';
import 'package:bmt_app/features/ops_dashboard/ops_dashboard_module.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

void main() {
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
        // navigate to the appropriate entry screen when mode changes (dev-only)
        if (!kDebugMode) return;
        _navKey.currentState?.pushNamedAndRemoveUntil(
          state.mode.routePath,
          (_) => false,
        );
      },
      child: MaterialApp(
        navigatorKey: _navKey,
        title: 'BMT App',
        theme: ThemeData(primarySwatch: Colors.blue),
        routes: {
          '/': (_) => const ComponentDemoApp(),
          '/driver': (_) => const CaptainDashboardScreen(),
          '/admin': (_) => const DashboardWebScreen(),
          '/ops': (_) => const OpsDashboardModule(),
          '/ops-dashboard': (_) => const OpsDashboardModule(),
        },
        initialRoute: '/',
      ),
    );
  }
}
