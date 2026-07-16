import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Fast shortcuts to the focus trip's most time-critical actions, so the
/// captain doesn't have to open the trip first to reach them. A subset of
/// the full action grid inside trip execution — not a duplicate of it, a
/// shortcut to it.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.qr_code_scanner_rounded,
            label: 'تسجيل الدخول',
            onTap: () => context.openCheckIn(tripId),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.my_location_rounded,
            label: 'إرسال الموقع',
            onTap: () => context.openLocationUpdate(tripId),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.report_problem_outlined,
            label: 'بلاغ طارئ',
            destructive: true,
            onTap: () => context.openReportIncident(tripId),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CaptainColors.error : CaptainColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaptainDesignTokens.br16,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s12,
          ),
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br16,
            border: Border.all(
              color: destructive
                  ? CaptainColors.error.withValues(alpha: 0.15)
                  : CaptainColors.dividerFor(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: destructive
                      ? CaptainColors.error
                      : CaptainColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
