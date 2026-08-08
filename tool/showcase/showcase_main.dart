// Entry point for the EWT product-screenshot harness.
//
// One web build serves every screen: the screen is chosen per page load from
// `?screen=<id>`, so the capture script navigates instead of rebuilding.
//
//   flutter run -d web-server --web-port 8750 -t tool/showcase/showcase_main.dart
//   http://localhost:8750/?screen=dashboard-executive-overview
//
// Nothing here initializes Supabase, Firebase or the real DI graph. Every
// screen is the product's own widget, fed a fake cubit holding invented data.

import 'package:flutter/material.dart';

import 'captain_showcase.dart';
import 'client_showcase.dart';
import 'dashboard_showcase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerDashboardShowcaseFakes();
  registerClientShowcaseFakes();
  registerCaptainShowcaseFakes();

  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'dashboard-executive-overview';
  final dark = params['theme'] == 'dark';

  runApp(_Showcase(screen: screen, dark: dark));
}

class _Showcase extends StatelessWidget {
  const _Showcase({required this.screen, required this.dark});

  final String screen;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dashboardScreens.containsKey(screen)) {
      return buildDashboardShowcase(screen, dark: dark);
    }
    if (clientScreens.containsKey(screen)) {
      return buildClientShowcase(screen, dark: dark);
    }
    if (captainScreens.containsKey(screen)) {
      return buildCaptainShowcase(screen, dark: dark);
    }
    return _UnknownScreen(screen: screen);
  }
}

class _UnknownScreen extends StatelessWidget {
  const _UnknownScreen({required this.screen});

  final String screen;

  @override
  Widget build(BuildContext context) {
    final known = [
      ...dashboardScreens.keys,
      ...clientScreens.keys,
      ...captainScreens.keys,
    ]..sort();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unknown screen: "$screen"',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 20),
                for (final id in known)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '?screen=$id',
                      style: const TextStyle(
                        color: Color(0xFF8FB6FF),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
