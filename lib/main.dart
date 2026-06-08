import 'package:bmt_app/apps/dashboard/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/features/component/presentation/component_demo_app.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

void main() {
  registerCaptainDependencies();
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
        if (!kDebugMode) return;
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
          '/': (_) => const ComponentDemoApp(),
          '/driver': (_) => const CaptainAppShell(),
          '/ops-dashboard': (_) => const DashboardWebApp(),
        },
        initialRoute: '/',
      ),
    );
  }
}
