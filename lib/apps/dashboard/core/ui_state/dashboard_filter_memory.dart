import 'package:flutter/foundation.dart';

/// Remembers the filters an operator applied to a module, for the lifetime of
/// the signed-in session.
///
/// ## Why this exists
///
/// The shell rebuilds a module from scratch on every navigation — each route
/// calls `dashboardDi<XCubit>()..load()`, so the cubit holding the filters is a
/// brand new object. An operator who narrows الحجوزات to "بانتظار المراجعة",
/// opens one booking to check a receipt, and comes back finds the full,
/// unfiltered queue again. Every time. That round trip is the single most
/// repeated motion in the console, and rebuilding the filter by hand is the tax
/// on it.
///
/// This is the sibling of `DashboardSectionStateStore`, which already solves
/// exactly this problem for collapse state, for exactly this reason, with
/// exactly this lifetime. Filters are the second tenant of that idea.
///
/// ## Why an opaque [Object]
///
/// Every module's filters have their own shape — `BookingFilters` is five
/// fields, tickets' is two enums, finance's is a date range. Forcing them
/// through a common interface would mean rewriting five value types to gain
/// nothing: this store never inspects, compares or serialises what it holds, it
/// only hands the same instance back. [read] is generic so the type check
/// happens at the call site and a key collision surfaces as `null` (falling
/// back to the module's own defaults) rather than as a cast error in front of
/// an operator.
///
/// ## Why not persisted
///
/// Same argument as the section store, but stronger. A filter that survived a
/// restart would greet an operator with a partial list they have no memory of
/// choosing, and every count on the screen would be a lie they had no reason to
/// doubt. Within one session the operator set the filter themselves minutes
/// ago, and the module still shows an active-filter count with a clear
/// affordance beside it — the state stays visible, which is what makes
/// remembering it safe.
class DashboardFilterMemory {
  DashboardFilterMemory._();

  static final DashboardFilterMemory instance = DashboardFilterMemory._();

  final Map<String, Object> _byId = <String, Object>{};

  /// The remembered filters for [filterId], or null when this module has not
  /// been filtered yet in this session (or remembered something of another
  /// type, which means the key is being shared by mistake).
  T? read<T extends Object>(String filterId) {
    final remembered = _byId[filterId];
    return remembered is T ? remembered : null;
  }

  /// Records the operator's current filter selection for [filterId].
  void write(String filterId, Object filters) {
    _byId[filterId] = filters;
  }

  /// Forgets [filterId] — what a module calls when the operator clears its
  /// filters, so "cleared" survives navigation just as a selection does.
  void forget(String filterId) {
    _byId.remove(filterId);
  }

  /// Drops every remembered filter.
  ///
  /// Called on sign-out, so the next operator on this machine does not inherit
  /// a predecessor's narrowed view of the queue and read it as the whole queue.
  void clear() => _byId.clear();

  @visibleForTesting
  Map<String, Object> get debugSnapshot => Map.unmodifiable(_byId);
}

/// Stable identifiers for every module that remembers its filters.
///
/// Same reasoning as `DashboardSectionIds`: a string typo would quietly give a
/// module a private key (harmless but useless), and a duplicated one would make
/// two modules read each other's filters — which [DashboardFilterMemory.read]
/// degrades to "no memory" rather than a crash, but only because it type-checks
/// defensively. Declaring them here keeps the whole set greppable.
class DashboardFilterIds {
  DashboardFilterIds._();

  static const bookings = 'bookings.filters';
  static const tickets = 'tickets.filters';
}
