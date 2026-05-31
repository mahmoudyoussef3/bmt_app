import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:bmt_app/features/component/presentation/component_demo_app.dart';
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
        final route = _routeForMode(state.mode);
        if (route != null) {
          _navKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
        }
      },
      child: MaterialApp(
        navigatorKey: _navKey,
        title: 'BMT App',
        theme: ThemeData(primarySwatch: Colors.blue),
        routes: {
          '/': (_) => const ComponentDemoApp(),
          '/ops': (_) => const OpsDashboardModule(),
          // other routes like /driver and /admin are left to existing app routing
        },
        initialRoute: '/',
      ),
    );
  }

  String? _routeForMode(AppMode mode) {
    switch (mode) {
      case AppMode.client:
        return '/';
      case AppMode.driver:
        return '/driver';
      case AppMode.admin:
        return '/admin';
      case AppMode.ops:
        return '/ops';
    }
  }
}
