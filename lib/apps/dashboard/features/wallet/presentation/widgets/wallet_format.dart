import 'package:flutter/widgets.dart';

import '../../../finance/presentation/widgets/finance_format.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

/// The wallet module's formatting, layered on [FinanceFormat] rather than
/// beside it.
///
/// Reusing Finance's number vocabulary is deliberate: the two modules report the
/// same money to the same person, and a wallet balance rendered `250.00 ج.م`
/// next to a Finance figure rendered `٢٥٠` is how one office ends up believing
/// it has two different numbers. Everything below is either a ledger-specific
/// need (signed amounts, running balances) or a label.
abstract final class WalletFormat {
  const WalletFormat._();

  /// A ledger always shows piastres. `250` and `250.40` are different balances,
  /// and rounding them together is precisely the discrepancy a customer calls
  /// about.
  static String money(double value) => FinanceFormat.moneyPrecise(value);

  /// `+200.00 ج.م` / `−50.00 ج.م`.
  ///
  /// The minus is U+2212, not a hyphen: at small sizes in an RTL column a hyphen
  /// is easy to miss, and "was that a debit?" is the one question this string
  /// exists to answer.
  static String signed(double value) {
    final sign = value >= 0 ? '+' : '−';
    return '$sign${FinanceFormat.moneyPrecise(value.abs())}';
  }

  static String date(DateTime value) => FinanceFormat.date(value);
  static String dateTime(DateTime value) => FinanceFormat.dateTime(value);
  static String count(num value) => FinanceFormat.count(value);

  /// `منذ 3 ساعات` — relative age for "last activity" columns, where the exact
  /// timestamp is noise and the recency is the signal.
  static String age(DateTime? value, DateTime now) {
    if (value == null) return 'لا يوجد نشاط';
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return FinanceFormat.date(value);
  }

  /// Status colour for a ledger entry.
  ///
  /// A reversed entry reads neutral rather than red: it is not a *failure*, it
  /// is a corrected record, and colouring it as an error would tell the operator
  /// something untrue about a row that is working as designed.
  static Color entryColor(WalletTransaction entry, BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    if (entry.isReversed) return palette.neutral;
    if (entry.isReversal) return palette.warning;
    return entry.isCredit ? palette.positive : palette.negative;
  }

  static Color refundColor(RefundStatus status, BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    return switch (status) {
      RefundStatus.settled => palette.positive,
      RefundStatus.approved => palette.active,
      RefundStatus.pending => palette.warning,
      RefundStatus.rejected || RefundStatus.failed => palette.negative,
      RefundStatus.cancelled => palette.neutral,
    };
  }
}
