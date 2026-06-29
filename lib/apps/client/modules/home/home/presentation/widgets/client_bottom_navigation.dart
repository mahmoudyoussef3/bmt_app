import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';

class ClientBottomNavigation extends StatelessWidget {
  const ClientBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  final String activeTab;
  final ValueChanged<String> onTabChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <({String id, String label, IconData icon})>[
      (id: 'home', label: 'Home', icon: Icons.home_rounded),
      (id: 'routes', label: 'Routes', icon: Icons.route_rounded),
      (id: 'trips', label: 'My Trips', icon: Icons.receipt_long_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(40))),
      ),
      padding: const EdgeInsets.only(
        top: AppLayout.spaceSm,
        bottom: AppLayout.spaceSm,
        left: AppLayout.spaceSm,
        right: AppLayout.spaceSm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: tabs.map((tab) {
            final isActive = activeTab == tab.id;
            return Expanded(
              child: InkWell(
                onTap: () => onTabChange(tab.id),
                borderRadius: BorderRadius.circular(AppLayout.radiusLg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppLayout.spaceXs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 24,
                        color: isActive
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withAlpha(150),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurfaceVariant.withAlpha(150),
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
