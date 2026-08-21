import 'package:flutter/widgets.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

import '../../../bookings/domain/entities/operation_booking.dart';
import '../../../finance/presentation/widgets/finance_format.dart';
import '../../domain/entities/customer_insight.dart';

/// العملاء's formatting and status vocabulary.
///
/// ## Why the labels come from the bookings domain
///
/// [BookingStatus] and [PaymentStatus] mirror the database's own CHECK
/// allowlists and already carry their Arabic labels. Re-declaring them here
/// would create a second vocabulary that drifts the first time a status is
/// added — which has already happened once in this codebase, when `cancelled`
/// was missing from [PaymentStatus] and every cancelled payment rendered as
/// "قيد الانتظار". This module resolves against the existing enums instead.
///
/// The three vocabularies that are *not* in the bookings domain — boarding,
/// subscription state and wallet movement — are declared below because nothing
/// else in the console owns them as a labelled type.
abstract final class CustomersFormat {
  const CustomersFormat._();

  /// Money reuses Finance's vocabulary rather than sitting beside it: the two
  /// modules report the same money to the same person, and a total rendered
  /// `١٢٬٣٤٥` next to a Finance figure rendered `12,345` is how one office ends
  /// up believing it has two different numbers.
  static String money(double value) => FinanceFormat.money(value);

  static String moneyPrecise(double value) => FinanceFormat.moneyPrecise(value);

  static String count(num value) => FinanceFormat.count(value);

  static String date(DateTime value) => FinanceFormat.date(value);

  static String dateTime(DateTime value) => FinanceFormat.dateTime(value);

  /// `منذ ٣ ساعات` — recency for "last activity", where the exact timestamp is
  /// noise and how long ago is the signal. Falls back to an absolute date past
  /// a month, when "منذ 47 يوم" stops being easier to read than the date.
  static String age(DateTime? value, DateTime now) {
    if (value == null) return 'لا يوجد نشاط';
    final diff = now.difference(value);
    if (diff.isNegative) return FinanceFormat.date(value);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return FinanceFormat.date(value);
  }

  /// `اليوم` / `غداً` / a date. Used for the next trip, where "when" is the
  /// whole question and a bare date makes the reader do the arithmetic.
  static String relativeDay(DateTime? value, DateTime now) {
    if (value == null) return '—';
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final days = target.difference(today).inDays;
    return switch (days) {
      0 => 'اليوم',
      1 => 'غداً',
      -1 => 'أمس',
      _ => FinanceFormat.date(value),
    };
  }

  /// `12:00` from the `HH:MM[:SS]` text the booking carries. Returned as-is if
  /// it is not in that shape — inventing a time is worse than showing the raw
  /// value the operator can recognise.
  static String tripTime(String? value) {
    if (value == null || value.isEmpty) return '—';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  // ── Status vocabularies ──────────────────────────────────────────────────

  /// `operation_bookings.status` → the label the console already uses.
  /// Unknown values render as themselves rather than as a wrong label.
  static String bookingStatus(String value) =>
      BookingStatus.values
          .where((status) => status.name == _camel(value))
          .map((status) => status.label)
          .firstOrNull ??
      value;

  static String paymentStatus(String? value) {
    if (value == null || value.isEmpty) return '—';
    return PaymentStatus.values
            .where((status) => status.name == _camel(value))
            .map((status) => status.label)
            .firstOrNull ??
        value;
  }

  static String paymentMethod(String? value) {
    if (value == null || value.isEmpty) return '—';
    return switch (value) {
      'instapay' => BookingPaymentMethod.instaPay.label,
      'vodafone_cash' => BookingPaymentMethod.vodafoneCash.label,
      'cash' => BookingPaymentMethod.cash.label,
      'card' => BookingPaymentMethod.card.label,
      'bank_transfer' => BookingPaymentMethod.bankTransfer.label,
      _ => value,
    };
  }

  /// `trip_passengers.status`. Its own vocabulary, not the booking's: a
  /// passenger who did not turn up still holds a confirmed booking.
  static String boardingStatus(String? value) => switch (value) {
    'reserved' => 'لم يصعد بعد',
    'completed' => 'صعد',
    'no_show' => 'لم يحضر',
    null || '' => '—',
    _ => value,
  };

  /// `subscriptions.status`.
  static String subscriptionStatus(String value) => switch (value) {
    'active' => 'ساري',
    'expired' => 'منتهي',
    'cancelled' => 'ملغى',
    _ => value,
  };

  /// `clients.status`.
  static String clientStatus(String value) => switch (value) {
    'active' => 'نشط',
    'suspended' => 'موقوف',
    'blocked' => 'محظور',
    _ => value,
  };

  /// `wallet_transactions.kind`, matching محفظة العملاء's own words.
  static String walletKind(String value) => switch (value) {
    'cashback' => 'كاش باك',
    'manual_credit' => 'إضافة رصيد',
    'manual_debit' => 'خصم رصيد',
    'refund' => 'استرداد',
    _ => value,
  };

  // ── Tones ────────────────────────────────────────────────────────────────

  static Color bookingTone(String value, BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    return switch (value) {
      'completed' || 'boarded' => palette.positive,
      'confirmed' => palette.active,
      'reserved' || 'draft' => palette.warning,
      'cancelled' => palette.negative,
      _ => palette.neutral,
    };
  }

  static Color paymentTone(String? value, BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    return switch (value) {
      'approved' => palette.positive,
      'submitted' || 'pending' || 'under_review' => palette.warning,
      'rejected' || 'failed' => palette.negative,
      // A refund is a corrected record, not a failure. Colouring it red would
      // tell the operator something untrue about a row working as designed.
      'refunded' || 'cancelled' => palette.neutral,
      _ => palette.neutral,
    };
  }

  static Color boardingTone(String? value, BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    return switch (value) {
      'completed' => palette.positive,
      'no_show' => palette.negative,
      'reserved' => palette.warning,
      _ => palette.neutral,
    };
  }

  static Color subscriptionTone(
    String value,
    bool isCurrent,
    BuildContext context,
  ) {
    final palette = DashboardChartPalette.of(context);
    // `status` alone goes stale — expiry is swept by a job the الاشتراكات
    // module triggers — so a row claiming `active` past its end date reads
    // neutral rather than green.
    if (value == 'active' && !isCurrent) return palette.neutral;
    return switch (value) {
      'active' => palette.positive,
      'expired' => palette.neutral,
      'cancelled' => palette.negative,
      _ => palette.neutral,
    };
  }

  static Color insightTone(CustomerInsightTone tone, BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    return switch (tone) {
      CustomerInsightTone.positive => palette.positive,
      CustomerInsightTone.warning => palette.warning,
      CustomerInsightTone.neutral => palette.neutral,
    };
  }

  /// `no_show` → `noShow`, so a database value can be matched against an enum
  /// declared in Dart's casing.
  static String _camel(String value) {
    final parts = value.split('_');
    if (parts.length == 1) return value;
    return parts.first +
        parts
            .skip(1)
            .map(
              (part) => part.isEmpty
                  ? part
                  : part[0].toUpperCase() + part.substring(1),
            )
            .join();
  }
}
