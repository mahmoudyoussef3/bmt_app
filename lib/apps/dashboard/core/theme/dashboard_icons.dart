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

  /// The landing screen. A console overview, not a house: the operator is
  /// already inside their workspace.
  static const home = Icons.space_dashboard_outlined;
  static const homeActive = Icons.space_dashboard_rounded;

  /// The executive overview. An upward business trend, deliberately *not* the
  /// [trend] chart glyph: that one marks a chart inside a page, this one marks
  /// the page whose whole subject is how the business is doing.
  static const businessOverview = Icons.insights_outlined;
  static const businessOverviewActive = Icons.insights_rounded;

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

  /// Customer credit balances and their ledger. A wallet, deliberately *not* the
  /// banknotes used for [payments]: money the office has taken is not the same
  /// concept as money the office still owes back.
  static const wallet = Icons.account_balance_wallet_outlined;
  static const walletActive = Icons.account_balance_wallet_rounded;

  /// Generated reports and statements.
  static const reports = Icons.assessment_outlined;
  static const reportsActive = Icons.assessment_rounded;

  /// The owner's business read of the office.

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

  /// Plans: named bundles of feature values the platform sells.
  static const plans = Icons.workspace_premium_outlined;
  static const plansActive = Icons.workspace_premium_rounded;

  /// The feature catalog: what the platform *can* sell.
  static const featureCatalog = Icons.toggle_on_outlined;
  static const featureCatalogActive = Icons.toggle_on_rounded;

  /// Each office's licence, plan and status.
  static const licenses = Icons.verified_user_outlined;
  static const licensesActive = Icons.verified_user_rounded;

  /// Platform invoices and renewals.
  static const billing = Icons.request_quote_outlined;
  static const billingActive = Icons.request_quote_rounded;

  /// Consumption against limits, across offices.
  static const usage = Icons.speed_outlined;
  static const usageActive = Icons.speed_rounded;

  /// The licensing decision trail.
  static const audit = Icons.fact_check_outlined;
  static const auditActive = Icons.fact_check_rounded;

  /// The office's own plan and invoices.
  static const officeBilling = Icons.credit_card_outlined;
  static const officeBillingActive = Icons.credit_card_rounded;

  /// A module the office could buy but has not — shown locked, not hidden.
  static const locked = Icons.lock_outline_rounded;

  /// Dashboard accounts and what each one may do.
  static const users = Icons.manage_accounts_outlined;
  static const usersActive = Icons.manage_accounts_rounded;

  static const settings = Icons.settings_outlined;
  static const settingsActive = Icons.settings_rounded;

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

  /// A graded health reading — the business is fine / needs a look / is broken.
  static const health = Icons.monitor_heart_outlined;

  /// An interpreted finding: what a number *means*, not the number itself.
  static const insight = Icons.lightbulb_outline_rounded;

  /// A shortcut to a common action.
  static const quickAction = Icons.bolt_rounded;

  /// The customer base as a group, as opposed to [passenger] (one traveller)
  /// or `users` (an operator account).
  static const customers = Icons.groups_2_outlined;

  /// A summarised financial position.
  static const financial = Icons.account_balance_outlined;

  /// Today's operations, summarised.
  static const operations = Icons.dashboard_customize_outlined;

  /// A captain's incident report.
  static const incident = Icons.report_gmailerrorred_rounded;

  /// Movement against a previous period.
  ///
  /// Up and down are diagonal and carry their meaning in the vertical axis, so
  /// RTL leaves them alone. "No change" is a dash rather than
  /// `Icons.trending_flat`, whose horizontal arrow is mirrored under RTL and
  /// would read as direction where none is meant.
  static const trendUp = Icons.trending_up_rounded;
  static const trendDown = Icons.trending_down_rounded;
  static const trendFlat = Icons.remove_rounded;

  static const refresh = Icons.refresh_rounded;
  static const add = Icons.add_rounded;
  static const logout = Icons.logout_rounded;
  static const menu = Icons.menu_rounded;

  /// Collapse / expand the navigation rail.
  static const collapseNav = Icons.menu_open_rounded;
  static const expandNav = Icons.menu_rounded;

  // ## Directional glyphs — name the intent, never the glyph
  //
  // Material's arrows and chevrons carry `matchTextDirection: true`, so the
  // framework mirrors them itself under RTL. That makes them this console's
  // most reliable trap: a developer who wants a "back" button — which points
  // *right* in Arabic — reaches for `chevron_right`, the framework flips it,
  // and it renders pointing left. The rule is to always name the
  // **LTR-semantic** glyph and let the framework do the flip.
  //
  // The rule is one sentence long and was still broken at eight call sites,
  // because at the call site nobody is thinking about mirroring — they are
  // thinking "this button goes back". So the tokens below are named for the
  // *intent*. Say what the control does; the right glyph follows.
  // `dashboard_rtl_test.dart` fails the build if a raw directional glyph
  // appears anywhere in the dashboard outside this file.

  /// "Go to this module." The sidebar/overview affordance into a whole screen.
  static const openModule = Icons.chevron_right_rounded;

  /// Advance: drill into a row's details, or move to the next step of a flow.
  static const forward = Icons.arrow_forward_rounded;

  /// Retreat: return to the list, or to the previous step of a flow.
  static const back = Icons.arrow_back_rounded;

  /// Pagination controls. Chevrons rather than arrows because they sit in a
  /// dense bar where an arrow reads as an action rather than a step.
  static const paginationPrevious = Icons.chevron_left_rounded;
  static const paginationNext = Icons.chevron_right_rounded;

  /// The separator between breadcrumb crumbs, and the marker on a selected row.
  /// Points the way the eye travels, so it mirrors with everything else.
  static const breadcrumbSeparator = Icons.chevron_right_rounded;

  /// A transition between two values — a journey's origin → destination, or an
  /// audit entry's before → after. Not navigation: nothing is clickable here.
  static const transition = Icons.arrow_forward_rounded;
}
