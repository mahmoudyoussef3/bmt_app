import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import 'captain_awaiting_step.dart';
import 'captain_button.dart';
import 'captain_list_group.dart';
import 'captain_live_sync_chip.dart';
import 'captain_section_label.dart';

class CaptainAwaitingTripsView extends StatelessWidget {
  const CaptainAwaitingTripsView({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
    this.title = 'لا توجد رحلات مسندة بعد',
    this.message =
        'فور إسناد رحلة لك ستظهر هنا تلقائياً — لا حاجة لتسجيل الخروج '
        'والدخول مرة أخرى.',
    this.currentStepLabel = 'بانتظار إسناد رحلة من العمليات',
    this.shortcuts = const [],
  });

  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final String title;
  final String message;
  final String currentStepLabel;

  final List<Widget> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StandbyMark(),
        const SizedBox(height: CaptainDesignTokens.s20),
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
        const SizedBox(height: CaptainDesignTokens.s16),
        Center(child: CaptainLiveSyncChip(isRefreshing: isRefreshing)),
        const SizedBox(height: CaptainDesignTokens.s32),
        const CaptainSectionLabel('أين وصل جدولك'),
        CaptainListGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(CaptainDesignTokens.s16),
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
          ],
        ),
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: CaptainDesignTokens.s24),
          const CaptainSectionLabel('بينما تنتظر'),
          CaptainListGroup(children: shortcuts),
        ],
        const SizedBox(height: CaptainDesignTokens.s24),
        CaptainButton(
          label: 'تحديث الآن',
          icon: Icons.refresh_rounded,
          isLoading: isRefreshing,
          variant: CaptainButtonVariant.secondary,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _StandbyMark extends StatelessWidget {
  const _StandbyMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(112, 0.06),
          _ring(92, 0.10),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  CaptainColors.primary,
                  CaptainColors.primary.withValues(alpha: 0.75),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              boxShadow: [
                BoxShadow(
                  color: CaptainColors.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.route_rounded,
              size: 34,
              color: CaptainColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CaptainColors.primary.withValues(alpha: alpha),
      ),
    );
  }
}
