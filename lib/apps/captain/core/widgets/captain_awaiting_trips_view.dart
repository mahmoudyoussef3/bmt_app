import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import 'captain_awaiting_step.dart';
import 'captain_button.dart';
import 'captain_live_sync_chip.dart';
import 'captain_pulse_badge.dart';

/// Shown whenever operations has not assigned the captain a trip yet — on the
/// day view and on the post-approval home. It places the captain inside the
/// assignment workflow, promises automatic arrival (no re-login), and still
/// offers an explicit refresh.
class CaptainAwaitingTripsView extends StatelessWidget {
  const CaptainAwaitingTripsView({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
    this.title = 'لا توجد رحلات مسندة بعد',
    this.message =
        'فريق العمليات يجهّز جدولك. فور إسناد رحلة لك ستظهر هنا تلقائياً — '
        'لا حاجة لتسجيل الخروج والدخول مرة أخرى.',
    this.currentStepLabel = 'بانتظار إسناد رحلة من العمليات',
  });

  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final String title;
  final String message;
  final String currentStepLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(
          color: CaptainColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const CaptainPulseBadge(icon: Icons.route_rounded),
          const SizedBox(height: CaptainDesignTokens.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: CaptainTypography.bodyMedium(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            decoration: BoxDecoration(
              color: CaptainColors.primary.withValues(alpha: 0.04),
              borderRadius: CaptainDesignTokens.br16,
              border: Border.all(
                color: CaptainColors.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                const CaptainAwaitingStep(
                  label: 'تم تفعيل حسابك كسائق',
                  state: CaptainStepState.done,
                ),
                CaptainAwaitingStep(
                  label: currentStepLabel,
                  state: CaptainStepState.current,
                ),
                const CaptainAwaitingStep(
                  label: 'تبدأ رحلتك من هذه الشاشة',
                  state: CaptainStepState.upcoming,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          CaptainLiveSyncChip(isRefreshing: isRefreshing),
          const SizedBox(height: CaptainDesignTokens.s16),
          CaptainButton(
            label: 'تحديث الآن',
            icon: Icons.refresh_rounded,
            isLoading: isRefreshing,
            variant: CaptainButtonVariant.secondary,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
