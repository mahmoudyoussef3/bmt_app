import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import 'captain_awaiting_step.dart';
import 'captain_button.dart';
import 'captain_list_group.dart';
import 'captain_live_sync_chip.dart';
import 'captain_section_label.dart';

/// Shown whenever operations has not assigned the captain a trip yet — on the
/// day view and on the post-approval home.
///
/// It is a *page*, not a card. It used to be one framed, shadowed rectangle
/// holding a headline, a paragraph, a bordered step panel and two controls —
/// the titled-card-per-block pattern the rest of the captain app was rebuilt to
/// get away from, and the loudest surviving example of it, since on an empty
/// day it was the only thing on screen. Now the hero sits directly on the page
/// background and each block below it is named from the outside by a
/// [CaptainSectionLabel], the same shape the profile and trip-execution screens
/// use.
///
/// Two things it must keep doing: place the captain inside the assignment
/// workflow so waiting reads as progress rather than as a dead app, and promise
/// that the trip arrives on its own — a captain who believes they have to
/// re-login will re-login, repeatedly.
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

  /// Somewhere for the captain to go while the schedule is empty — rows for a
  /// [CaptainListGroup], supplied by the screen that knows what it can reach.
  ///
  /// Empty on the onboarding home, which has no tabs to offer yet; the day view
  /// fills it. Without these the screen is a dead end whose only control
  /// re-asks a question it has already answered ("still nothing").
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
        // One child, so the group draws no dividers through the step
        // connector: the three steps are a single progression, not three rows.
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

/// The standby emblem: an icon inside two soft halos.
///
/// Static, and a size smaller than the badge it replaces. That badge breathed
/// on a repeating controller, which is the wrong call twice over on this
/// screen: the captain's phone sits in a cradle for a whole shift, so an
/// animation that never settles is a battery cost carrying no information — and
/// a never-settling animation hangs `pumpAndSettle` for every widget test that
/// renders an empty day. The halos say "standing by" without moving, the same
/// way `FocusLiveDot` says "live".
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
