/// Row ceilings for the console's list queries, in one place so the numbers can
/// be reviewed against each other rather than discovered one datasource at a
/// time.
///
/// ## Why these exist
///
/// Every operational list used to read the office's entire history on each
/// visit, then paginate in Dart. That is free on a new office and linear on an
/// old one: an office with 50,000 bookings paid for 50,000 joined rows to look
/// at the twelve on screen, several times per session, because the shell
/// rebuilds a module on every navigation.
///
/// ## The contract
///
/// A capped query takes the **newest** rows, and the screen says so when the
/// ceiling is reached. The alternative — silently truncating — is the failure
/// this codebase already refuses elsewhere: a total computed over a truncated
/// set that is presented as the whole.
///
/// A cap is therefore always paired with two things:
///
///  1. `.order(...)` on a time column, descending, so "which rows survive" is a
///     decision and not whatever the planner returned first;
///  2. a `capReached` flag on the state and a [DashboardCapNotice] on the
///     screen, so the operator is told their view is a window.
///
/// ## What a cap is not
///
/// It is not paging. Reaching further back is still a query the console cannot
/// make; the honest answer is to narrow the filters, and the notice says so.
/// Server-side paging with server-side tallies is the end state — see
/// `DASHBOARD_PERFORMANCE.md`.
abstract final class DashboardQueryCaps {
  const DashboardQueryCaps._();

  /// Bookings carry the heaviest row in the console — trip, route, driver,
  /// vehicle and package are joined onto every one — so this is the lowest cap.
  /// A busy office writes a few hundred a day; 2,000 is roughly a trading week
  /// with room over it.
  static const int bookings = 2000;

  /// Trips are created by the office, not by passengers, so the volume is a
  /// couple of dozen a day at most. This holds several months.
  static const int trips = 1500;

  /// Support tickets arrive at a fraction of the booking rate and are worked
  /// through a queue rather than browsed as history.
  static const int tickets = 1000;

  /// One row per sold subscription, and they are read as a live book rather
  /// than an archive.
  static const int subscriptions = 1500;

  /// Reviews are light rows, and the module's averages are the point rather
  /// than the individual rows.
  static const int reviews = 1500;

  /// The financial ledger's own ceiling, in place before the rest and kept at
  /// its original value.
  static const int financeLedger = 3000;
}
