import 'package:flutter/material.dart';

/// The dashboard's single icon vocabulary.
///
/// Every module, nav item, KPI tile and row action reads its glyph from here so
/// one concept is drawn with one glyph everywhere: a bus always means *vehicle*,
/// a timetable board always means *trip*, a ticket always means *booking*.
/// Before this file the shell drew the fleet with a delivery truck, trips with a
/// bus and reports with a sheet of paper — three glyphs that each said something
/// the screen behind them did not.
///
/// ## The two-variant rule
///
/// Each entry comes in a pair: an **outlined** glyph for the resting state and a
/// **rounded (filled)** glyph for the selected/active state. That is the only
/// weight change in the system — nothing here is decorative, and no icon is ever
/// used without a label beside it or a tooltip on it.
abstract final class DashboardIcons {
  const DashboardIcons._();

  // ── Modules ────────────────────────────────────────────────────────────────

  /// The landing screen. A console overview, not a house: the operator is
  /// already inside their workspace.
  static const home = Icons.space_dashboard_outlined;
  static const homeActive = Icons.space_dashboard_rounded;

  /// Live operations — trips moving right now and their tracking health.
  static const liveOps = Icons.sensors_outlined;
  static const liveOpsActive = Icons.sensors_rounded;

  /// A scheduled trip. A departure board, deliberately *not* a bus: the bus is
  /// the vehicle that runs it, and the fleet module owns that meaning.
  static const trips = Icons.departure_board_outlined;
  static const tripsActive = Icons.departure_board_rounded;

  /// A route — the fixed line a trip runs along.
  static const routes = Icons.alt_route_outlined;
  static const routesActive = Icons.alt_route_rounded;

  /// A passenger booking. A ticket, which is what the passenger holds.
  static const bookings = Icons.confirmation_number_outlined;
  static const bookingsActive = Icons.confirmation_number_rounded;

  /// A package subscription — a membership, not a medal.
  static const subscriptions = Icons.card_membership_outlined;
  static const subscriptionsActive = Icons.card_membership_rounded;

  /// The fleet: the buses themselves.
  static const fleet = Icons.directions_bus_outlined;
  static const fleetActive = Icons.directions_bus_filled_rounded;

  /// Captains / drivers as people on the roster.
  static const captains = Icons.badge_outlined;
  static const captainsActive = Icons.badge_rounded;

  /// The queue of captains asking to join — an approval decision.
  static const captainRequests = Icons.how_to_reg_outlined;
  static const captainRequestsActive = Icons.how_to_reg_rounded;

  /// Money in and out.
  static const payments = Icons.payments_outlined;
  static const paymentsActive = Icons.payments_rounded;

  /// Receipts waiting on an approve/reject decision.
  static const paymentReview = Icons.receipt_long_outlined;
  static const paymentReviewActive = Icons.receipt_long_rounded;

  /// Generated reports and statements.
  static const reports = Icons.assessment_outlined;
  static const reportsActive = Icons.assessment_rounded;

  /// The owner's business read of the office.
  static const ownerOverview = Icons.insights_outlined;
  static const ownerOverviewActive = Icons.insights_rounded;

  /// The referral programme.
  static const referrals = Icons.card_giftcard_outlined;
  static const referralsActive = Icons.card_giftcard_rounded;

  /// Passenger complaints / support tickets.
  static const tickets = Icons.support_agent_outlined;
  static const ticketsActive = Icons.support_agent_rounded;

  /// Passenger reviews and ratings.
  static const reviews = Icons.star_outline_rounded;
  static const reviewsActive = Icons.star_rounded;

  static const notifications = Icons.notifications_outlined;
  static const notificationsActive = Icons.notifications_rounded;

  /// The office's own marketplace record.
  static const officeProfile = Icons.storefront_outlined;
  static const officeProfileActive = Icons.storefront_rounded;

  /// Other offices on the platform (platform admins only).
  static const platformOffices = Icons.apartment_outlined;
  static const platformOfficesActive = Icons.apartment_rounded;

  /// Dashboard accounts and what each one may do.
  static const users = Icons.manage_accounts_outlined;
  static const usersActive = Icons.manage_accounts_rounded;

  static const settings = Icons.settings_outlined;
  static const settingsActive = Icons.settings_rounded;

  // ── Attributes (used inside rows, chips and KPI tiles) ────────────────────

  /// A departure or booking time.
  static const time = Icons.schedule_rounded;

  /// The captain running a trip.
  static const captain = Icons.person_outline_rounded;

  /// The bus running a trip.
  static const vehicle = Icons.directions_bus_outlined;

  /// Seats — occupancy, capacity, a booked place.
  static const seats = Icons.event_seat_outlined;

  /// An occupancy or completion share.
  static const occupancy = Icons.donut_large_rounded;

  /// A passenger.
  static const passenger = Icons.person_rounded;

  /// A fleet or captain document that expires.
  static const document = Icons.description_outlined;

  /// Revenue as a figure rather than as a module.
  static const revenue = Icons.account_balance_wallet_outlined;

  // ── States & actions ──────────────────────────────────────────────────────

  /// Something needs a decision. Used only where an action really is required —
  /// never as decoration on a healthy panel.
  static const attention = Icons.error_outline_rounded;

  /// Nothing needs a decision.
  static const allClear = Icons.check_circle_outline_rounded;

  /// A chronological feed of what already happened.
  static const activity = Icons.history_rounded;

  /// A trend over time.
  static const trend = Icons.show_chart_rounded;

  /// A ranking (top routes, busiest days).
  static const ranking = Icons.leaderboard_outlined;

  static const refresh = Icons.refresh_rounded;
  static const add = Icons.add_rounded;
  static const logout = Icons.logout_rounded;
  static const menu = Icons.menu_rounded;

  /// Collapse / expand the navigation rail.
  static const collapseNav = Icons.menu_open_rounded;
  static const expandNav = Icons.menu_rounded;

  /// "Go to this module." Directional: Material mirrors it under RTL, so this
  /// must stay the LTR-semantic glyph (see `dashboard_rtl_test.dart`).
  static const openModule = Icons.chevron_right_rounded;
}
