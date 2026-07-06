import 'package:flutter/material.dart';


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
      (id: 'routes', label: 'Routes', icon: Icons.map_rounded),
      (id: 'trips', label: 'Trips', icon: Icons.directions_bus_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_outline_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isActive = activeTab == tab.id;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTabChange(tab.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 20 : 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? scheme.primary.withAlpha(25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 26,
                        color: isActive ? scheme.primary : scheme.onSurfaceVariant.withAlpha(150),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
