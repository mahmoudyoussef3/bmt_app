import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import 'booking_review_intents.dart' as intents;
import 'booking_status_chips.dart';
import 'bookings_queue_board.dart' show bookingRelativeTime;

/// One booking on the card layout.
///
/// Three tiers — who → which trip → how much, and what the desk should do about
/// it. Four things were wrong with the version before this one, all of them
/// visible in a single screenshot of the review queue:
///
///  - The **approve button was unreadable**: `backgroundColor: approved.ink`
///    with white text painted a pastel `#A5F3FC` slab in dark mode. It now
///    takes the tone's [AppStatusStyle.fill] / [AppStatusStyle.onFill] pair.
///  - **A cancelled booking still offered قبول / رفض / إعادة رفع**, all three of
///    which the server refuses. Actions are keyed to
///    [BookingReviewRules.canReviewPayment] now, and a booking that is out of
///    the desk's hands says why instead.
///  - The **two state chips sat in different tiers** (payment at the top,
///    booking status four rows down beside the fare), so "where does this stand"
///    took two reads. They are one cluster.
///  - The **route was one ellipsized line** — a long bidi corridor name
///    truncated to `…Al Marj, Cairo, Egypt → American University in Cairo (AUC)`
///    tells an operator nothing. Origin and destination get a line each.
///
/// The start rail is the scanning aid: colour it once per card and a column of
/// twelve reads as a queue rather than as twelve equally-loud boxes.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.selected,
    required this.opened,
    this.isProcessing = false,
  });

  final OperationBooking booking;
  final bool selected;
  final bool opened;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();
    final tone = context.status(bookingAccentTone(booking));

    return AnimatedContainer(
      duration: AppTokens.motionFast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        // Constant width in both states: animating 1 → 2 nudged every card in
        // the row by a pixel as the operator moved between them.
        border: Border.all(
          color: opened
              ? scheme.primary
              : selected
              ? scheme.primary.withAlpha(120)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: opened
            ? [
                BoxShadow(
                  color: scheme.primary.withAlpha(45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: AppCard(
        onTap: () => cubit.openBooking(booking),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          // Stretch, not IntrinsicHeight: the rail takes the height the content
          // column ends up with, for free.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StateRail(color: tone.accent),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardHeader(
                    booking: booking,
                    selected: selected,
                    isProcessing: isProcessing,
                    onToggleSelection: () => cubit.toggleSelection(booking.id),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _TripBlock(booking: booking),
                  const SizedBox(height: AppSpacing.medium),
                  _AmountRow(booking: booking),
                  const SizedBox(height: AppSpacing.medium),
                  _CardActions(
                    booking: booking,
                    cubit: cubit,
                    isProcessing: isProcessing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full-height colour bar down the start edge of the card.
class _StateRail extends StatelessWidget {
  const _StateRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.booking,
    required this.selected,
    required this.isProcessing,
    required this.onToggleSelection,
  });

  final OperationBooking booking;
  final bool selected;
  final bool isProcessing;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.canReviewPayment)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.xSmall,
                ),
                child: Tooltip(
                  message: 'تحديد للمراجعة الجماعية',
                  child: Checkbox(
                    value: selected,
                    onChanged: isProcessing ? null : (_) => onToggleSelection(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.passengerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (booking.bookingNumber.isNotEmpty)
                        booking.bookingNumber,
                      if (booking.phone.isNotEmpty) booking.phone,
                      bookingRelativeTime(booking.createdAt),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        // Both machines in one cluster. Split across two tiers of the card they
        // read as unrelated facts rather than as one answer.
        Wrap(
          spacing: AppSpacing.xSmall,
          runSpacing: AppSpacing.xSmall,
          children: [
            BookingStateChip.payment(booking.paymentStatus, dense: true),
            BookingStateChip.booking(booking.status, dense: true),
          ],
        ),
      ],
    );
  }
}

class _TripBlock extends StatelessWidget {
  const _TripBlock({required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final facts = <(IconData, String)>[
      if (booking.date.isNotEmpty) (Icons.event_rounded, booking.date),
      if (booking.tripTime.isNotEmpty)
        (Icons.schedule_rounded, booking.tripTime),
      if (booking.seat.isNotEmpty) (Icons.event_seat_rounded, booking.seat),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        // The token for a tile inside a card, not an alpha wash over the card:
        // `surfaceContainerHighest.withAlpha(70)` came out muddy on both themes
        // and different on each.
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteLine(route: booking.route),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Divider(height: 1, color: scheme.outline.withAlpha(60)),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.medium,
              runSpacing: AppSpacing.xSmall,
              children: [
                for (final (icon, value) in facts)
                  _Fact(icon: icon, value: value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Origin above destination, with a connector — the shape the corridor actually
/// has. A single `A → B` line is only legible while both ends are short, and
/// mixing a latin place name into an RTL line makes the ellipsis land in an
/// unpredictable place.
class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.route});

  final String route;

  /// Splits on the separators the route builder actually produces. `→` is tried
  /// first: a corridor whose *destination* contains a dash
  /// (`… (AUC) - New Cairo`) must not split there.
  static (String, String)? _split(String route) {
    for (final separator in const ['→', '➜', ' - ', ' – ', ' — ']) {
      final index = route.indexOf(separator);
      if (index <= 0) continue;
      final from = route.substring(0, index).trim();
      final to = route.substring(index + separator.length).trim();
      if (from.isEmpty || to.isEmpty) continue;
      return (from, to);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = text.bodyMedium?.copyWith(fontWeight: FontWeight.w800);

    if (route.isEmpty) {
      return Row(
        children: [
          Icon(Icons.route_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xSmall),
          Text(
            'مسار غير محدد',
            style: style?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    final parts = _split(route);
    if (parts == null) {
      return Row(
        children: [
          Icon(Icons.route_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: AppSpacing.xSmall),
          Expanded(
            child: Text(
              route,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RouteEnd(label: parts.$1, color: scheme.primary, filled: false),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4.5),
          child: SizedBox(
            width: 1,
            height: 10,
            child: ColoredBox(color: scheme.outline),
          ),
        ),
        _RouteEnd(label: parts.$2, color: scheme.primary, filled: true),
      ],
    );
  }
}

class _RouteEnd extends StatelessWidget {
  const _RouteEnd({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The fare, and whether there is evidence to decide it on.
class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            booking.amountLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          child: Text(
            booking.paymentMethod.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const Spacer(),
        // A payment review is decided on the receipt, so whether one exists
        // belongs on the card rather than one click inside the inspector.
        _ReceiptBadge(booking: booking),
      ],
    );
  }
}

class _ReceiptBadge extends StatelessWidget {
  const _ReceiptBadge({required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasReceipt = booking.hasReceipt;
    // A missing receipt is only a *problem* on a row the desk is being asked to
    // decide — everywhere else it is just a fact about the booking.
    final tone = context.status(
      hasReceipt
          ? AppStatusTone.info
          : booking.canReviewPayment
          ? AppStatusTone.warning
          : AppStatusTone.neutral,
    );

    return Tooltip(
      message: hasReceipt
          ? 'إيصال مرفوع — افتح التفاصيل لمعاينته'
          : booking.canReviewPayment
          ? 'الدفع بانتظار المراجعة ولا يوجد إيصال للاطلاع عليه'
          : 'لا يوجد إيصال مرفوع على هذا الحجز',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasReceipt
                ? Icons.receipt_long_rounded
                : Icons.receipt_long_outlined,
            size: 14,
            color: tone.accent,
          ),
          const SizedBox(width: 4),
          Text(
            hasReceipt ? 'إيصال' : 'بلا إيصال',
            style: text.labelSmall?.copyWith(
              color: tone.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The decision pair, then the secondary moves.
///
/// The old row put four controls of four different weights in one `Wrap`, so
/// "قبول" — the thing the queue exists for — was one of four equal-looking
/// chips. Approve and reject now split the full width the way the inspector's
/// action bar does, and everything else is a text button underneath.
class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.booking,
    required this.cubit,
    required this.isProcessing,
  });

  final OperationBooking booking;
  final BookingsCubit cubit;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final approved = context.status(AppStatusTone.success);
    final rejected = context.status(AppStatusTone.error);
    final enabled = !isProcessing;

    if (!booking.canReviewPayment) {
      return _ClosedActions(booking: booking, cubit: cubit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: enabled
                    ? () => intents.approveBooking(context, cubit, booking)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: approved.fill,
                  foregroundColor: approved.onFill,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('قبول'),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled
                    ? () => intents.rejectBooking(context, cubit, booking)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: rejected.accent,
                  side: BorderSide(color: rejected.accent.withAlpha(110)),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('رفض'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        // A `Wrap`, not a `Row` with a `Spacer`: at two columns on a 760px
        // window a card is ~312px wide, and the two secondary labels together
        // need more than that at any text scale.
        Wrap(
          spacing: AppSpacing.xSmall,
          runSpacing: AppSpacing.xSmall,
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: enabled
                  ? () => intents.requestReupload(context, cubit, booking)
                  : null,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة رفع'),
            ),
            TextButton.icon(
              onPressed: () => cubit.openBooking(booking),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text('التفاصيل'),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a card says when there is no decision to take: the reason, not three
/// buttons the server would refuse.
class _ClosedActions extends StatelessWidget {
  const _ClosedActions({required this.booking, required this.cubit});

  final OperationBooking booking;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final action = resolveNextAction(
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      hasReceipt: booking.hasReceipt,
    );
    final contradiction = action.kind == BookingActionKind.resolveContradiction;
    final tone = context.status(
      contradiction ? AppStatusTone.error : AppStatusTone.neutral,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          contradiction
              ? Icons.error_outline_rounded
              : Icons.info_outline_rounded,
          size: 16,
          color: contradiction ? tone.accent : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            action.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              color: contradiction ? tone.accent : scheme.onSurfaceVariant,
              fontWeight: contradiction ? FontWeight.w700 : null,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xSmall),
        TextButton.icon(
          onPressed: () => cubit.openBooking(booking),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text('التفاصيل'),
        ),
      ],
    );
  }
}
