import 'package:flutter/material.dart';
import 'package:bmt_app/features/component/presentation/component_demo_app.dart';
import 'package:bmt_app/features/ops_dashboard/ops_dashboard_module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMT App',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/': (_) => const ComponentDemoApp(),
        '/ops': (_) => const OpsDashboardModule(),
      },
      initialRoute: '/ops',
    );
  }
}
