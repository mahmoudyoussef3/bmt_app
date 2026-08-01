import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// States in one sentence, plus any contradiction between them.
///
/// The panel previously showed two status chips side by side and left the
/// operator to work out what they meant together — "reserved" + "submitted" is
/// an instruction to review a receipt, but nothing said so, and "cancelled" +
/// "approved" is a passenger's money sitting in the office, which looked no more
/// urgent than any other pair of chips.
///
/// This banner answers *what do I do next, and why*, and shouts when the two
/// states disagree.
class BookingNextActionBanner extends StatelessWidget {
  const BookingNextActionBanner({super.key, required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final issues = detectBookingIssues(
      status: booking.status,
      paymentStatus: booking.paymentStatus,
    );
    final action = resolveNextAction(
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      hasReceipt: booking.hasReceipt,
    );

    // When the next action *is* resolving a contradiction, the issue tiles below
    // already state the problem verbatim. Repeating it in the action tile put the
    // same sentence on screen twice, which reads as a rendering fault rather than
    // emphasis — so the action tile gives the directive and defers the detail.
    final isContradiction =
        action.kind == BookingActionKind.resolveContradiction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tile(
          icon: action.isActionable
              ? Icons.play_circle_fill_rounded
              : Icons.check_circle_outline_rounded,
          title: action.label,
          body: isContradiction
              ? 'حالة الحجز وحالة الدفع غير متوافقتين — راجع التفاصيل أدناه قبل أي إجراء آخر.'
              : action.reason,
          container: action.isActionable
              ? context.status(AppStatusTone.info).tint
              : context.status(AppStatusTone.neutral).tint,
          onContainer: action.isActionable
              ? context.status(AppStatusTone.info).ink
              : context.status(AppStatusTone.neutral).ink,
        ),
        // Contradictions are listed in full rather than summarised: each one is a
        // different remedy (refund, collect, document), so collapsing them would
        // hide the very distinction the operator needs.
        for (final issue in issues) ...[
          const SizedBox(height: AppSpacing.small),
          _Tile(
            icon: issue.severity == BookingIssueSeverity.critical
                ? Icons.error_rounded
                : Icons.warning_amber_rounded,
            title: issue.severity == BookingIssueSeverity.critical
                ? 'تعارض في الحالة'
                : 'حالة تستدعي المراجعة',
            body: issue.message,
            container: issue.severity == BookingIssueSeverity.critical
                ? context.status(AppStatusTone.error).tint
                : context.status(AppStatusTone.warning).tint,
            onContainer: issue.severity == BookingIssueSeverity.critical
                ? context.status(AppStatusTone.error).ink
                : context.status(AppStatusTone.warning).ink,
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.body,
    required this.container,
    required this.onContainer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: onContainer),
          const SizedBox(width: AppSpacing.small),
          // Expanded + wrapping body: the reason lines are full sentences and
          // must never be clipped in a narrow inspector or at a large text scale.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: text.bodySmall?.copyWith(color: onContainer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
