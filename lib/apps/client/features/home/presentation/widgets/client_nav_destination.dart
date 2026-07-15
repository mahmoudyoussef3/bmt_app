import 'package:flutter/material.dart';

import 'package:bmt_app/l10n/app_localizations.dart';

/// A single destination in the client shell's bottom navigation.
///
/// [icon] is the resting (outlined) glyph and [activeIcon] the selected
/// (filled) one — the pair drives the outline→filled morph in `ClientNavItem`.
/// The label is resolved from [id] at render time so it follows the app locale.
class ClientNavDestination {
  const ClientNavDestination({
    required this.id,
    required this.icon,
    required this.activeIcon,
  });

  final String id;
  final IconData icon;
  final IconData activeIcon;

  String labelFor(AppLocalizations l10n) {
    switch (id) {
      case 'routes':
        return l10n.nav_routes;
      case 'trips':
        return l10n.nav_trips;
      case 'profile':
        return l10n.nav_profile;
      case 'home':
      default:
        return l10n.nav_home;
    }
  }

  static const List<ClientNavDestination> all = <ClientNavDestination>[
    ClientNavDestination(
      id: 'home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    ClientNavDestination(
      id: 'routes',
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
    ),
    ClientNavDestination(
      id: 'trips',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
    ),
    ClientNavDestination(
      id: 'profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];
}
