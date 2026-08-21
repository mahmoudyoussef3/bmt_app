import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/finance_entities.dart';
import 'finance_common.dart';
import 'finance_format.dart';

/// One money movement, end to end.
///
/// The ledger row is a summary; this is the whole chain behind it — what was
/// sold, to whom, on which journey, how it was tendered, where the payment
/// stands and where the seat stands. Before this existed a 511 ج.م row marked
/// "قيد التحصيل" was a dead end: the owner could see the amount and had to go
/// to Bookings and search for it to learn anything else.
///
/// Still read-only. There is no approve, refund or cancel here; the footer says
/// where those live and the operator goes there.
class FinanceTransactionDetail extends StatelessWidget {
  const FinanceTransactionDetail({
    super.key,
    required this.entry,
    this.refund,
    this.onOpenModule,
  });

  final FinanceLedgerEntry entry;

  /// The refund request that reverses this entry, when one exists. Matched on
  /// `booking_id`, which is why a subscription never carries one.
  final RefundRequest? refund;

  final ValueChanged<String>? onOpenModule;

  static Future<void> show(
    BuildContext context, {
    required FinanceLedgerEntry entry,
    RefundRequest? refund,
    ValueChanged<String>? onOpenModule,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => FinanceTransactionDetail(
        entry: entry,
        refund: refund,
        onOpenModule: onOpenModule,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);
    final text = Theme.of(context).textTheme;
    final context_ = entry.context;

    return AlertDialog(
      icon: Icon(
        entry.type == FinanceEntryType.booking
            ? Icons.event_seat_outlined
            : Icons.workspace_premium_outlined,
        color: scheme.primary,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.type == FinanceEntryType.booking
                ? 'حركة حجز رحلة'
                : 'حركة اشتراك باقة',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Row(
            children: [
              FinanceStatusBadge(status: entry.status),
              const SizedBox(width: AppSpacing.small),
              Flexible(
                child: Text(
                  FinanceFormat.dateTime(entry.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AmountBanner(entry: entry),
              const SizedBox(height: AppSpacing.medium),

              _Group(
                title: 'الدفع',
                rows: [
                  ('حالة المبلغ', entry.status.label),
                  ('طريقة الدفع', entry.method?.label ?? 'غير مسجلة'),
                  (
                    'تاريخ الحركة',
                    FinanceFormat.dateTime(entry.date),
                  ),
                  if (entry.type == FinanceEntryType.booking)
                    (
                      'إثبات الدفع',
                      context_.hasReceipt
                          ? (entry.awaitingReview
                                ? 'مرفوع وبانتظار المراجعة'
                                : 'مرفوع')
                          : 'لا يوجد',
                    ),
                  if (context_.rejectionReason?.isNotEmpty ?? false)
                    ('سبب الرفض', context_.rejectionReason!),
                  if (entry.outstanding > 0)
                    (
                      'المتبقي على الباقة',
                      FinanceFormat.moneyPrecise(entry.outstanding),
                    ),
                ],
              ),

              if (entry.type == FinanceEntryType.booking) ...[
                const SizedBox(height: AppSpacing.medium),
                _Group(
                  title: 'الحجز والراكب',
                  rows: [
                    ('رقم الحجز', context_.reference ?? '—'),
                    ('الراكب', entry.party),
                    ('الهاتف', context_.phone ?? '—'),
                    ('حالة المقعد', entry.bookingState.label),
                    (
                      'تاريخ الرحلة',
                      context_.serviceDate == null
                          ? '—'
                          : FinanceFormat.date(context_.serviceDate!),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                _RouteBlock(entry: entry),
              ] else ...[
                const SizedBox(height: AppSpacing.medium),
                _Group(
                  title: 'الاشتراك',
                  rows: [
                    ('المشترك', entry.party),
                    ('الباقة', context_.packageName ?? entry.reference),
                    (
                      'بداية السريان',
                      context_.serviceDate == null
                          ? '—'
                          : FinanceFormat.date(context_.serviceDate!),
                    ),
                  ],
                ),
              ],

              if (refund != null) ...[
                const SizedBox(height: AppSpacing.medium),
                _RefundBlock(refund: refund!, palette: palette),
              ],

              const SizedBox(height: AppSpacing.medium),
              _EffectNote(entry: entry),
              const SizedBox(height: AppSpacing.small),
              SelectableText(
                'معرّف الحركة: ${entry.id}',
                maxLines: 2,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (onOpenModule != null && entry.type == FinanceEntryType.booking)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenModule!(_ownerRoute);
            },
            icon: const Icon(DashboardIcons.openModule, size: 18),
            label: Text(
              entry.awaitingReview ? 'افتح مراجعة الإيصالات' : 'افتح الحجوزات',
            ),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  /// The module that can actually change this row. A receipt awaiting a
  /// decision belongs in the verification queue; anything else belongs in the
  /// booking board.
  String get _ownerRoute => entry.awaitingReview
      ? DashboardRoutes.paymentVerification
      : DashboardRoutes.bookings;
}

class _AmountBanner extends StatelessWidget {
  const _AmountBanner({required this.entry});

  final FinanceLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final tone = FinanceStatusBadge.colorOf(context, entry.status);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tone.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tone.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المبلغ',
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text(
            FinanceFormat.moneyPrecise(entry.amount),
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteBlock extends StatelessWidget {
  const _RouteBlock({required this.entry});

  final FinanceLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final origin = entry.context.origin;
    final destination = entry.context.destination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المسار',
          style: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        if (origin != null && destination != null)
          // Composed rather than printed: the stored `route` string reverses
          // under bidi whenever the place names are Latin, which for Egyptian
          // geocoder output is most of them.
          RouteDirectionText(
            origin: origin,
            destination: destination,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          )
        else
          Text(
            entry.reference,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class _RefundBlock extends StatelessWidget {
  const _RefundBlock({required this.refund, required this.palette});

  final RefundRequest refund;
  final DashboardChartPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: palette.accent.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: palette.accent.withAlpha(60)),
      ),
      child: _Group(
        title: 'الاسترداد',
        rows: [
          ('حالة الطلب', refund.status.label),
          ('المبلغ المطلوب', FinanceFormat.moneyPrecise(refund.amount)),
          ('تاريخ الطلب', FinanceFormat.date(refund.date)),
          if (refund.reason.isNotEmpty) ('السبب', refund.reason),
        ],
      ),
    );
  }
}

/// What this one row did to the period's headline number. The arithmetic on the
/// overview is only trustworthy if any single row can be traced into it.
class _EffectNote extends StatelessWidget {
  const _EffectNote({required this.entry});

  final FinanceLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final note = switch (entry.status) {
      PaymentStatus.success when entry.isUnreleasedLiability =>
        'محسوبة ضمن صافي الإيراد، لكن المقعد أُلغي — المبلغ ما زال لدى المكتب '
            'ويحتاج قراراً بالرد أو النقل.',
      PaymentStatus.success =>
        'محسوبة بالكامل ضمن صافي الإيراد لهذه الفترة.',
      PaymentStatus.pending =>
        'خارج صافي الإيراد — تُحسب ضمن «قيد التحصيل» حتى يصل المبلغ.',
      PaymentStatus.refunded =>
        'دخلت ضمن إجمالي المتحصلات ثم خُصمت كمرتجع، فأثرها على الصافي صفر.',
      PaymentStatus.cancelled =>
        'خارج كل الحسابات — مبلغ لن يصل، سواء لرفض الدفع أو لإلغاء المقعد.',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.functions_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              note,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled block of `label — value` rows. Values that the database never
/// recorded render as an em dash rather than being dropped, so the reader can
/// tell "not applicable" from "we did not load it".
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
