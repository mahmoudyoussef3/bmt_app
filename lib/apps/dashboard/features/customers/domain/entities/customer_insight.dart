import 'customer_profile.dart';

/// How strongly an insight should read. Not a severity ranking of the customer —
/// a customer is not a risk score — but of how much the *operator* needs to
/// notice the sentence.
enum CustomerInsightTone { positive, neutral, warning }

/// One sentence about this customer that is true by construction.
///
/// Every insight below is a deterministic function of fields the database
/// recorded. There is no model, no weighting and no score: each one states a
/// fact and, where a number drives it, names the number so the owner can check
/// it against the tab it came from.
class CustomerInsight {
  final String label;
  final CustomerInsightTone tone;

  const CustomerInsight(this.label, this.tone);
}

/// Derives the ملخص العميل chips.
///
/// ## Why this is a function and not a stored column
///
/// Every sentence here is relative to *now* — "خامل منذ ٩٠ يوماً" is false
/// tomorrow for a customer who books tonight. A stored insight is a claim with
/// an expiry date and no one to enforce it.
///
/// ## What is deliberately not here
///
/// No lifetime-value tier, no churn probability, no "likely to book". The
/// office has bookings, payments and a manifest; none of those supports a
/// prediction, and a fabricated one would be indistinguishable on screen from
/// the facts beside it.
abstract final class CustomerInsights {
  const CustomerInsights._();

  static List<CustomerInsight> of(CustomerProfile profile, DateTime now) {
    final metrics = profile.metrics;
    final insights = <CustomerInsight>[];

    final lastActivity = metrics.lastActivityAt;
    if (lastActivity != null) {
      final days = now.difference(lastActivity).inDays;
      if (days <= 30) {
        insights.add(
          const CustomerInsight('عميل نشط', CustomerInsightTone.positive),
        );
      } else if (days >= 90) {
        insights.add(
          CustomerInsight('خامل منذ $days يوماً', CustomerInsightTone.warning),
        );
      }
    } else if (metrics.bookingsTotal == 0) {
      insights.add(
        const CustomerInsight(
          'لا يوجد نشاط مع المكتب',
          CustomerInsightTone.neutral,
        ),
      );
    }

    final subscription = profile.activeSubscription;
    if (subscription != null) {
      final remaining = subscription.daysRemaining(now);
      if (remaining != null && remaining <= 7) {
        insights.add(
          CustomerInsight(
            remaining <= 0
                ? 'اشتراكه ينتهي اليوم'
                : 'اشتراكه ينتهي خلال $remaining أيام',
            CustomerInsightTone.warning,
          ),
        );
      } else {
        insights.add(
          const CustomerInsight(
            'لديه اشتراك ساري',
            CustomerInsightTone.positive,
          ),
        );
      }

      // Only meaningful when the package has an allowance to measure against.
      if (subscription.tripsCount > 0 && subscription.tripsUsed == 0) {
        insights.add(
          const CustomerInsight(
            'لم يستخدم أي رحلة من اشتراكه',
            CustomerInsightTone.warning,
          ),
        );
      }
    }

    final next = metrics.nextTripDate;
    if (next != null) {
      final today = DateTime(now.year, now.month, now.day);
      final days = DateTime(
        next.year,
        next.month,
        next.day,
      ).difference(today).inDays;
      insights.add(
        CustomerInsight(switch (days) {
          <= 0 => 'لديه رحلة اليوم',
          1 => 'لديه رحلة غداً',
          _ => 'لديه رحلة قادمة خلال $days أيام',
        }, CustomerInsightTone.positive),
      );
    }

    // Reported as a share and a count together: "٤٠٪" alone invites the reader
    // to supply their own denominator.
    final cancellationRate = metrics.cancellationRate;
    if (cancellationRate != null && cancellationRate >= 0.3) {
      final percent = (cancellationRate * 100).round();
      insights.add(
        CustomerInsight(
          'ألغى $percent٪ من حجوزاته (${metrics.bookingsCancelled} من ${metrics.bookingsTotal})',
          CustomerInsightTone.warning,
        ),
      );
    }

    if (metrics.noShowCount >= 2) {
      // "N من الرحلات" rather than "N رحلات": Arabic pluralises 2 as رحلتين and
      // 11+ as رحلة, so a single hard-coded plural is wrong for most counts.
      insights.add(
        CustomerInsight(
          'لم يحضر ${metrics.noShowCount} من الرحلات',
          CustomerInsightTone.warning,
        ),
      );
    }

    final balance = metrics.walletBalance;
    if (balance != null && balance > 0) {
      insights.add(
        const CustomerInsight(
          'لديه رصيد في المحفظة',
          CustomerInsightTone.neutral,
        ),
      );
    }

    if (metrics.ticketsOpen > 0) {
      insights.add(
        CustomerInsight(
          'لديه ${metrics.ticketsOpen} شكوى مفتوحة',
          CustomerInsightTone.warning,
        ),
      );
    }

    return insights;
  }
}
