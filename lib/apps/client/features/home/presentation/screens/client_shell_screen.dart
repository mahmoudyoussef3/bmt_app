import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/routes/client_cubit_scopes.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/home_screen.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/client_bottom_navigation.dart';

class ClientShellScreen extends StatefulWidget {
  const ClientShellScreen({
    super.key,
    required this.routesBuilder,
    required this.tripsBuilder,
    required this.profileBuilder,
    required this.notificationsBuilder,
  });

  final WidgetBuilder routesBuilder;
  final WidgetBuilder tripsBuilder;
  final WidgetBuilder profileBuilder;
  final WidgetBuilder notificationsBuilder;

  @override
  State<ClientShellScreen> createState() => _ClientShellScreenState();
}

class _ClientShellScreenState extends State<ClientShellScreen> {
  int _index = 0;

  void _openRoute(String route, [Object? arguments]) {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: widget.notificationsBuilder),
    );
  }

  /// Home draws its own gradient behind the status bar, so it manages the top
  /// inset itself and forces light status-bar icons. Other tabs keep the
  /// standard SafeArea and theme-appropriate icons.
  Widget _standardTab(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: SafeArea(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ClientCubitScopes.home(
          HomeScreen(
            onOpenRoute: _openRoute,
            onOpenNotifications: _openNotifications,
            onSwitchTab: (tab) => setState(() => _index = _indexForTab(tab)),
          ),
        ),
      ),
      _standardTab(widget.routesBuilder(context)),
      _standardTab(widget.tripsBuilder(context)),
      _standardTab(widget.profileBuilder(context)),
    ];

    return Scaffold(
      
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: ClientBottomNavigation(
        activeTab: _tabForIndex(_index),
        onTabChange: (tab) {
          setState(() => _index = _indexForTab(tab));
        },
      ),
    );
  }

  int _indexForTab(String tab) {
    switch (tab) {
      case 'routes':
        return 1;
      case 'trips':
        return 2;
      case 'profile':
        return 3;
      case 'home':
      default:
        return 0;
    }
  }

  String _tabForIndex(int index) {
    switch (index) {
      case 1:
        return 'routes';
      case 2:
        return 'trips';
      case 3:
        return 'profile';
      case 0:
      default:
        return 'home';
    }
  }
}
