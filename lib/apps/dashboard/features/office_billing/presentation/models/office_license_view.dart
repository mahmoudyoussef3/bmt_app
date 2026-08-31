import 'package:bmt_app/core/theme/colors.dart';

import '../../../../core/entitlements/entitlement_context.dart';

/// One licence status, turned into everything the screen needs to say about it.
///
/// The eight statuses were being told in three different voices — a banner that
/// only appeared for five of them, a KPI detail line that repeated the label,
/// and nothing at all for `none`. They are one statement with one tone here, so
/// «موقوفة» cannot be quiet on one half of the screen and loud on the other.
///
/// The distinction the copy keeps making, because it is the one owners get
/// wrong: **a hold degrades the account to read-only, it never blacks it out.**
/// Sold tickets, running trips and captain sign-in continue in every state.
class LicenseStatusView {
  const LicenseStatusView({
    required this.tone,
    required this.statusLabel,
    required this.headline,
    this.consequence,
    this.deadlineLabel,
    this.deadline,
    this.isRestricted = false,
    this.needsAction = false,
  });

  final AppStatusTone tone;

  /// «نشطة», «مهلة أخيرة» — the same words [LicenseSummary.statusLabelAr] uses.
  final String statusLabel;

  /// What the state means, in one sentence.
  final String headline;

  /// What happens next, or what stops working. Null when there is nothing to
  /// warn about — an active licence does not need a paragraph.
  final String? consequence;

  /// «التجديد التالي», «تنتهي المهلة» — names the date rather than leaving the
  /// owner to work out which of four dates this one is.
  final String? deadlineLabel;
  final DateTime? deadline;

  /// The account is in read-only mode: creation is blocked, everything already
  /// sold keeps running.
  final bool isRestricted;

  /// The owner has something to do — pay, choose a plan, or ask the platform.
  final bool needsAction;

  /// Whole days from now until [deadline]; negative once it has passed. Null
  /// when there is no date to count to.
  int? get daysLeft {
    final at = deadline;
    if (at == null) return null;
    return at.difference(DateTime.now()).inDays;
  }

  /// The deadline is close enough to be the loudest thing on the card.
  bool get deadlineIsImminent {
    final left = daysLeft;
    return left != null && left <= 7;
  }

  static const _readOnly =
      'لا يمكن إنشاء رحلات أو سائقين أو خطوط جديدة. التذاكر المُباعة '
      'والرحلات الجارية ودخول الكباتن تعمل كالمعتاد.';

  factory LicenseStatusView.of(LicenseSummary license) {
    switch (license.status) {
      case 'active':
        return LicenseStatusView(
          tone: AppStatusTone.success,
          statusLabel: license.statusLabelAr,
          headline: 'الحساب يعمل بالكامل، وكل ما تشمله باقتك متاح.',
          consequence: license.autoRenew
              ? null
              : 'التجديد التلقائي متوقف — تنتهي الباقة في نهاية الفترة الحالية '
                    'ما لم تُجدَّد.',
          deadlineLabel: license.autoRenew ? 'التجديد التالي' : 'تنتهي الفترة',
          deadline: license.periodEnd,
          needsAction: !license.autoRenew,
        );

      case 'trialing':
        return LicenseStatusView(
          tone: AppStatusTone.info,
          statusLabel: license.statusLabelAr,
          headline: 'أنت في فترة تجريبية — الحساب يعمل بالكامل.',
          consequence:
              'عند انتهاء التجربة يتوقف إنشاء الجديد ما لم تُختَر باقة. '
              'لا يُحذف أي بيان.',
          deadlineLabel: 'تنتهي التجربة',
          deadline: license.trialEndsAt,
          needsAction: true,
        );

      case 'past_due':
        return LicenseStatusView(
          tone: AppStatusTone.warning,
          statusLabel: license.statusLabelAr,
          headline: 'هناك فاتورة اشتراك لم تُسدَّد بعد.',
          consequence:
              'الحساب يعمل بالكامل. سدّد الفاتورة لتجنّب التقييد — بعد المهلة '
              'يتحوّل الحساب إلى وضع القراءة فقط.',
          deadlineLabel: 'تنتهي الفترة',
          deadline: license.periodEnd,
          needsAction: true,
        );

      case 'grace':
        return LicenseStatusView(
          tone: AppStatusTone.warning,
          statusLabel: license.statusLabelAr,
          headline: 'مهلة أخيرة قبل تقييد الحساب.',
          consequence:
              'عند انتهاء المهلة يتحوّل الحساب إلى وضع القراءة فقط: $_readOnly',
          deadlineLabel: 'تنتهي المهلة',
          deadline: license.graceEndsAt ?? license.periodEnd,
          needsAction: true,
        );

      case 'suspended':
        return LicenseStatusView(
          tone: AppStatusTone.error,
          statusLabel: license.statusLabelAr,
          headline: 'الحساب في وضع القراءة فقط.',
          consequence: _readOnly,
          deadlineLabel: 'آخر فترة مدفوعة انتهت',
          deadline: license.periodEnd,
          isRestricted: true,
          needsAction: true,
        );

      case 'cancelled':
        return LicenseStatusView(
          tone: AppStatusTone.error,
          statusLabel: license.statusLabelAr,
          headline: 'تم إلغاء الترخيص، والحساب في وضع القراءة فقط.',
          consequence: _readOnly,
          deadlineLabel: 'آخر فترة مدفوعة انتهت',
          deadline: license.periodEnd,
          isRestricted: true,
          needsAction: true,
        );

      case 'expired':
        return LicenseStatusView(
          tone: AppStatusTone.error,
          statusLabel: license.statusLabelAr,
          headline: 'انتهى الترخيص، والحساب في وضع القراءة فقط.',
          consequence: 'جدّد الاشتراك لاستئناف الإنشاء. لم يُحذف أي بيان.',
          deadlineLabel: 'انتهى في',
          deadline: license.periodEnd,
          isRestricted: true,
          needsAction: true,
        );

      // `none` — no licence row at all. It used to produce the calmest screen
      // in the module: no banner, a dash for a plan name, and nothing said.
      default:
        return const LicenseStatusView(
          tone: AppStatusTone.warning,
          statusLabel: 'بدون ترخيص',
          headline: 'لا توجد باقة مرتبطة بمكتبك بعد.',
          consequence:
              'يعمل المكتب على الإعدادات الافتراضية للمنصة. تواصل مع إدارة '
              'المنصة لتفعيل اشتراك واعتماد باقة.',
          needsAction: true,
        );
    }
  }
}

/// «شهريًا» / «سنويًا» / «عقد مخصص» / «مجانية», or an empty string when the
/// licence carries no cycle at all.
String licenseCycleLabel(String? cycle) => switch (cycle) {
  'yearly' => 'سنويًا',
  'monthly' => 'شهريًا',
  'custom' => 'عقد مخصص',
  'free' => 'مجانية',
  _ => '',
};
