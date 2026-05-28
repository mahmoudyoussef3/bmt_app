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
    final tabs = <({String id, String label, IconData icon})>[
      (id: 'home', label: 'Home', icon: Icons.home_rounded),
      (id: 'bookings', label: 'Bookings', icon: Icons.calendar_month_rounded),
      (id: 'tracking', label: 'Tracking', icon: Icons.map_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.black.withAlpha(15))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab.id;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChange(tab.id),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 22,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
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
