import 'package:flutter/material.dart';

class ComponentBottomNavigation extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;

  const ComponentBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <({String id, String label, IconData icon})>[
      (id: 'home', label: 'Home', icon: Icons.home_rounded),
      (id: 'bookings', label: 'My Trips', icon: Icons.luggage_rounded),
      (id: 'tracking', label: 'Tracking', icon: Icons.map_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(220),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(34),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab.id;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChange(tab.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withAlpha(40)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 22,
                      color: isActive
                          ? scheme.primary
                          : scheme.onSurface.withAlpha(155),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isActive
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
