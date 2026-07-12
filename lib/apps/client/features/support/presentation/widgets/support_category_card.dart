import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// A single quick-action tile in the Support Center's category rail.
/// Tapping it jumps straight into ticket creation pre-filled with [title],
/// so returning users never have to hunt through a category dropdown.
class SupportCategoryCard extends StatelessWidget {
  const SupportCategoryCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  IconData _getIconForCategory(String cat) {
    if (cat.contains('Booking')) return Icons.book_online_rounded;
    if (cat.contains('Payment')) return Icons.payments_rounded;
    if (cat.contains('Delay')) return Icons.schedule_rounded;
    if (cat.contains('Driver') || cat.contains('Vehicle')) {
      return Icons.directions_bus_filled_rounded;
    }
    if (cat.contains('Route')) return Icons.map_rounded;
    if (cat.contains('Subscription')) return Icons.workspace_premium_rounded;
    if (cat.contains('Lost')) return Icons.inventory_2_rounded;
    if (cat.contains('Technical')) return Icons.computer_rounded;
    if (cat.contains('Refund')) return Icons.attach_money_rounded;
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.sm),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ClientColors.primaryContainerFor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForCategory(title),
                color: ClientColors.primaryFor(context),
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ClientTypography.labelSmall(context).copyWith(
                fontWeight: FontWeight.w700,
                color: ClientColors.textPrimaryFor(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
