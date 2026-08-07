/// The owner's to-do list: every queue with something actually in it.
///
/// The sibling of Home's `HomeAttentionKind`, and deliberately a separate
/// vocabulary rather than an import of it. Home answers "what must an *operator*
/// clear today" — a bus with no driver, a receipt waiting on a decision. This
/// answers "what needs the *owner*" and so also carries the commercial queues
/// Home has no business showing a support agent: refund requests, plan limits
/// about to bite, bookings stranded on a cancelled trip.
///
/// Both are counted off the same loaded lists, so where the two overlap they
/// agree by construction.
library;

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';

/// How loudly an item speaks. Weakest → strongest, so `index` sorts directly.
enum BusinessAttentionSeverity { info, warning, urgent }

/// The kinds of work that can be waiting on an owner.
///
/// Severity lives on the kind rather than the instance, for the same reason it
/// does on Home: "money waiting to be handed back" is always urgent and "a new
/// captain applied" never is, and letting each call site decide is how the same
/// queue ends up amber on one screen and red on another.
enum BusinessAttentionKind {
  paymentsAwaitingReview(BusinessAttentionSeverity.urgent),
  refundRequests(BusinessAttentionSeverity.urgent),
  tripsWithoutCaptain(BusinessAttentionSeverity.urgent),
  bookingConflicts(BusinessAttentionSeverity.urgent),
  staleTrips(BusinessAttentionSeverity.warning),
  highCancellationRate(BusinessAttentionSeverity.warning),
  vehiclesInMaintenance(BusinessAttentionSeverity.warning),
  expiringDocuments(BusinessAttentionSeverity.warning),
  urgentComplaints(BusinessAttentionSeverity.warning),
  licenseLimit(BusinessAttentionSeverity.warning),
  captainRequests(BusinessAttentionSeverity.info),
  subscriptionsAwaitingPayment(BusinessAttentionSeverity.info);

  final BusinessAttentionSeverity severity;

  const BusinessAttentionKind(this.severity);
}

/// One queue with something in it.
///
/// Never constructed with a zero [count]: an empty queue is simply absent from
/// the list, because a warning box reading "0 problems" is still a warning box.
class BusinessAttentionItem {
  final BusinessAttentionKind kind;
  final int count;

  /// Shown in place of the count badge when a count is the wrong unit — "٩ من
  /// ١٠ سائقين" for a plan limit, where "9" alone would say nothing.
  final String? note;

  /// What the item is about, when the kind alone does not identify it. Carries
  /// the feature name for [BusinessAttentionKind.licenseLimit].
  final String? subject;

  const BusinessAttentionItem({
    required this.kind,
    required this.count,
    this.note,
    this.subject,
  });
}

/// Plan limits the office is within one step of hitting.
///
/// Read live from the resolved licence rather than from the loaded snapshot:
/// entitlements change when a contract changes, not when the page refreshes,
/// and the shell already re-resolves them on every refusal.
///
/// A limit is raised at **80% consumed or above**, and only while it still has
/// room — once it is spent it is no longer a warning, it is a wall the module
/// itself reports with the upgrade card. Unlimited and unmetered features never
/// appear.
List<BusinessAttentionItem> licenseLimitAttention(
  EntitlementContext? entitlements,
) {
  if (entitlements == null) return const [];

  final items = <BusinessAttentionItem>[];
  for (final feature in entitlements.limits) {
    final cap = feature.value;
    if (cap is! int || cap <= 0) continue;
    final used = feature.used;
    if (used == null) continue;
    if (used < cap * 0.8 || used >= cap) continue;

    final name = feature.nameAr.trim().isEmpty ? feature.key : feature.nameAr;
    final unit = feature.unitAr.trim();
    items.add(
      BusinessAttentionItem(
        kind: BusinessAttentionKind.licenseLimit,
        count: cap - used,
        note: unit.isEmpty ? '$used من $cap' : '$used من $cap $unit',
        subject: name,
      ),
    );
  }
  return items;
}
