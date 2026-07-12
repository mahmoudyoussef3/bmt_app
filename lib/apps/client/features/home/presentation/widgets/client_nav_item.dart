import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/client_nav_destination.dart';

/// One tab of the floating nav island: icon over label, both animating between
/// the resting and selected treatments.
///
/// The selected item sits on top of the gradient indicator painted by
/// `ClientBottomNavigation`, so its content flips to the inverse color rather
/// than carrying a background of its own.
class ClientNavItem extends StatelessWidget {
  const ClientNavItem({
    super.key,
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final ClientNavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? ClientColors.textInverse
        : ClientColors.textTertiaryFor(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: destination.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1,
                duration: ClientMotion.slow,
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: ClientMotion.fast,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(
                    isActive ? destination.activeIcon : destination.icon,
                    key: ValueKey<bool>(isActive),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: ClientMotion.base,
                curve: ClientMotion.curve,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1,
                  color: color,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: isActive ? 0.2 : 0,
                ),
                child: Text(destination.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
