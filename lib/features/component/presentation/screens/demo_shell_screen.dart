import 'package:flutter/material.dart';
import 'package:bmt_app/features/component/presentation/screens/trips/my_trips_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/home_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/profile_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/features/component/presentation/widgets/bottom_navigation.dart';

class DemoShellScreen extends StatefulWidget {
  const DemoShellScreen({super.key});

  @override
  State<DemoShellScreen> createState() => _DemoShellScreenState();
}

class _DemoShellScreenState extends State<DemoShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onOpenRoute: (route, [arguments]) =>
            Navigator.of(context).pushNamed(route, arguments: arguments),
      ),
      MyTripsScreen(
        onOpenRoute: (route, [arguments]) =>
            Navigator.of(context).pushNamed(route, arguments: arguments),
      ),
      const TrackingScreen(shellMode: true),
      ProfileScreen(
        onOpenRoute: (route, [arguments]) =>
            Navigator.of(context).pushNamed(route, arguments: arguments),
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: ComponentBottomNavigation(
        activeTab: _tabForIndex(_index),
        onTabChange: (tab) {
          setState(() => _index = _indexForTab(tab));
        },
      ),
    );
  }

  int _indexForTab(String tab) {
    switch (tab) {
      case 'bookings':
        return 1;
      case 'tracking':
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
        return 'bookings';
      case 2:
        return 'tracking';
      case 3:
        return 'profile';
      case 0:
      default:
        return 'home';
    }
  }
}
