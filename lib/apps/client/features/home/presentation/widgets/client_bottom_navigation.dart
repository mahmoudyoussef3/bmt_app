import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

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
      (id: 'trips', label: 'Trips', icon: Icons.receipt_long_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: ClientElevation.lg(context),
      ),
      padding: const EdgeInsets.only(
        top: ClientSpacing.sm,
        bottom: ClientSpacing.sm,
        left: ClientSpacing.xs,
        right: ClientSpacing.xs,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs.map((tab) {
            final isActive = activeTab == tab.id;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTabChange(tab.id),
                child: AnimatedContainer(
                  duration: ClientMotion.fast,
                  curve: ClientMotion.curve,
                  padding: const EdgeInsets.symmetric(
                    vertical: ClientSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: ClientMotion.fast,
                        curve: ClientMotion.curve,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActive ? 20 : 0,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? scheme.primary.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(ClientRadius.pill),
                        ),
                        child: Icon(
                          tab.icon,
                          size: 24,
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurfaceVariant.withAlpha(150),
                        ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
