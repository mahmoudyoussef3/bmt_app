import 'package:flutter/material.dart';

/// A single destination in the client shell's bottom navigation.
///
/// [icon] is the resting (outlined) glyph and [activeIcon] the selected
/// (filled) one — the pair drives the outline→filled morph in `ClientNavItem`.
class ClientNavDestination {
  const ClientNavDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  static const List<ClientNavDestination> all = <ClientNavDestination>[
    ClientNavDestination(
      id: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    ClientNavDestination(
      id: 'routes',
      label: 'Routes',
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
    ),
    ClientNavDestination(
      id: 'trips',
      label: 'Trips',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
    ),
    ClientNavDestination(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];
}
