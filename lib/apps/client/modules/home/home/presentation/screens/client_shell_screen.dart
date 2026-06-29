import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/screens/home_screen.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/widgets/client_bottom_navigation.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      BlocProvider<HomeCubit>(
        create: (_) => clientGetIt<HomeCubit>()..load(),
        child: HomeScreen(
          onOpenRoute: _openRoute,
          onOpenNotifications: _openNotifications,
        ),
      ),
      widget.routesBuilder(context),
      widget.tripsBuilder(context),
      widget.profileBuilder(context),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
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
