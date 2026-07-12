import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/client_nav_destination.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/client_nav_item.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/client_nav_selection_pill.dart';

/// Floating capsule navigation for the client shell.
///
/// A single gradient indicator slides between the four equal-width slots rather
/// than each tab owning a background, so the selection reads as one continuous
/// object moving across the bar. The island keeps its own height (it is not an
/// overlay), so tab content never scrolls underneath it.
class ClientBottomNavigation extends StatelessWidget {
  const ClientBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  final String activeTab;
  final ValueChanged<String> onTabChange;

  static const double _height = 64;
  static const double _inset = 8;

  void _select(ClientNavDestination destination) {
    if (destination.id == activeTab) return;
    HapticFeedback.selectionClick();
    onTabChange(destination.id);
  }

  @override
  Widget build(BuildContext context) {
    const destinations = ClientNavDestination.all;
    final activeIndex = destinations
        .indexWhere((d) => d.id == activeTab)
        .clamp(0, destinations.length - 1);

    // The island needs a canvas to float on: the shell Scaffold is near-white,
    // which would swallow a white bar. Painting the strip with the app canvas
    // color also lines it up exactly with the home tab's background.
    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Container(
            height: _height,
            decoration: _islandDecoration(context),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / destinations.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositionedDirectional(
                      duration: ClientMotion.slow,
                      curve: Curves.easeOutQuint,
                      start: activeIndex * slot + _inset,
                      top: _inset,
                      bottom: _inset,
                      width: slot - (_inset * 2),
                      child: const ClientNavSelectionPill(),
                    ),
                    Row(
                      children: [
                        for (final destination in destinations)
                          ClientNavItem(
                            destination: destination,
                            isActive: destination.id == activeTab,
                            onTap: () => _select(destination),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _islandDecoration(BuildContext context) {
    return BoxDecoration(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(ClientRadius.pill),
      border: Border.all(color: ClientColors.borderFor(context)),
      boxShadow: [
        BoxShadow(
          color: ClientColors.shadowFor(context).withAlpha(28),
          blurRadius: 32,
          spreadRadius: -8,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: ClientColors.primaryFor(context).withAlpha(20),
          blurRadius: 24,
          spreadRadius: -10,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
