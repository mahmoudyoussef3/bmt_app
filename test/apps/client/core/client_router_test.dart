import 'package:bmt_app/apps/client/core/routes/client_router.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/routes/communication_routes.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/routes/loyalty_routes.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/routes/wallet_routes.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/routes/payment_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/routes/profile_routes.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/routes/referral_routes.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/routes/seat_release_routes.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/routes/seat_selection_routes.dart';
import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/routes/routes_feature_routes.dart';

/// Every route name the app declares, by the constant that owns it.
///
/// Navigating with a raw string once desynced from the registered path and
/// silently broke phone signup; that class of bug is now prevented by the
/// compiler, since every call site references a constant. What the compiler
/// cannot see is the table itself — a constant nobody registers, a raw string
/// registered under no constant, or one path claimed by two owners. This list
/// is the declared surface those checks run against, so it must be updated
/// whenever a route is added or removed.
const Map<String, String> _declaredRoutes = <String, String>{
  'ClientRoutes.home': ClientRoutes.home,
  'ClientRoutes.terms': ClientRoutes.terms,
  'ClientRoutes.privacy': ClientRoutes.privacy,
  'AuthRoutes.welcome': AuthRoutes.welcome,
  'AuthRoutes.signIn': AuthRoutes.signIn,
  'AuthRoutes.signUp': AuthRoutes.signUp,
  'AuthRoutes.forgotPassword': AuthRoutes.forgotPassword,
  'AuthRoutes.resetPassword': AuthRoutes.resetPassword,
  'AuthRoutes.success': AuthRoutes.success,
  // Registered and navigable, but with no live entry point: the provider
  // buttons that would open them are inert while `AuthMethod.phoneOtp` is off.
  'AuthRoutes.phoneLogin': AuthRoutes.phoneLogin,
  'AuthRoutes.otpVerification': AuthRoutes.otpVerification,
  'BookingRoutes.search': BookingRoutes.search,
  'BookingRoutes.routeSelection': BookingRoutes.routeSelection,
  'BookingRoutes.popularRoutes': BookingRoutes.popularRoutes,
  'BookingRoutes.mapSelection': BookingRoutes.mapSelection,
  'BookingRoutes.routeMap': BookingRoutes.routeMap,
  'BookingRoutes.vehicleListing': BookingRoutes.vehicleListing,
  'BookingRoutes.vehicleDetails': BookingRoutes.vehicleDetails,
  'BookingRoutes.dailyBooking': BookingRoutes.dailyBooking,
  'BookingRoutes.wizard': BookingRoutes.wizard,
  'BookingRoutes.routeOverview': BookingRoutes.routeOverview,
  'SeatReleaseRoutes.seatRelease': SeatReleaseRoutes.seatRelease,
  'PackagesRoutes.mySubscription': PackagesRoutes.mySubscription,
  'PackagesRoutes.legacyExpiryAlias': PackagesRoutes.legacyExpiryAlias,
  'TripsRoutes.myTrips': TripsRoutes.myTrips,
  'TripsRoutes.tripDetails': TripsRoutes.tripDetails,
  'TrackingRoutes.tracking': TrackingRoutes.tracking,
  'SupportRoutes.center': SupportRoutes.center,
  'SupportRoutes.createTicket': SupportRoutes.createTicket,
  'SupportRoutes.ticketDetails': SupportRoutes.ticketDetails,
  'CommunicationRoutes.communication': CommunicationRoutes.communication,
  'CommunicationRoutes.chatThread': CommunicationRoutes.chatThread,
  'OfficesRoutes.directory': OfficesRoutes.directory,
  'OfficesRoutes.profile': OfficesRoutes.profile,
  'RoutesFeatureRoutes.details': RoutesFeatureRoutes.details,
  'ReferralRoutes.rewards': ReferralRoutes.rewards,
  'LoyaltyRoutes.loyalty': LoyaltyRoutes.loyalty,
  'WalletRoutes.wallet': WalletRoutes.wallet,
  'ProfileRoutes.profile': ProfileRoutes.profile,
};

/// Paths the router must NOT register.
///
/// The first two fronted a second, older booking funnel (seat map ->
/// PaymentCheckout -> PaymentProcessing). Nothing navigates to them, and the
/// funnel no longer works against the live database: its confirm call omits
/// `p_package_id` and `p_plan_start_date`, which `confirm_seat_booking_v2`
/// requires, and it called confirm without first taking a seat lock.
/// Registering them left a broken money path one server-supplied `action_url`
/// away from a rider.
///
/// `/subscription` was the standalone package catalogue, deleted because it
/// re-listed plans an office profile already shows and the booking wizard
/// already sells. Its constant is gone, so it is spelled out here — the retired
/// seat-map screen still pushes the raw string, and re-registering the path
/// would quietly resurrect the catalogue behind it.
///
/// They are asserted absent rather than merely deleted from [_declaredRoutes] so
/// re-adding one fails loudly instead of quietly reopening the flow.
const Map<String, String> _retiredRoutes = <String, String>{
  'SeatSelectionRoutes.seatSelection': SeatSelectionRoutes.seatSelection,
  'PaymentRoutes.checkout': PaymentRoutes.checkout,
  'the deleted package catalogue': '/subscription',
};

void main() {
  group('ClientRouter', () {
    test('does not register the retired booking funnel', () {
      final registered = ClientRouter.routes.keys.toSet();

      final resurrected = <String>[
        for (final entry in _retiredRoutes.entries)
          if (registered.contains(entry.value))
            '${entry.key} -> ${entry.value}',
      ];

      expect(
        resurrected,
        isEmpty,
        reason:
            'These paths front a booking flow that cannot complete against the '
            'live confirm_seat_booking_v2 signature and that skips the seat '
            'lock. Seats are booked through BookingRoutes.wizard.',
      );
    });

    test('registers a builder for every declared route constant', () {
      final registered = ClientRouter.routes.keys.toSet();

      final missing = <String>[
        for (final entry in _declaredRoutes.entries)
          if (!registered.contains(entry.value))
            '${entry.key} -> ${entry.value}',
      ];

      expect(
        missing,
        isEmpty,
        reason:
            'These constants name routes the router never registers, so '
            'navigating to them throws at runtime.',
      );
    });

    test('registers no route that no constant declares', () {
      final declared = _declaredRoutes.values.toSet();
      final undeclared = ClientRouter.routes.keys
          .where((route) => !declared.contains(route))
          .toList();

      expect(
        undeclared,
        isEmpty,
        reason:
            'Every registered path must come from a route constant — a raw '
            'string here is a path with no single source of truth.',
      );
    });

    test('declares each path exactly once across all route registries', () {
      final owners = <String, List<String>>{};
      for (final entry in _declaredRoutes.entries) {
        owners.putIfAbsent(entry.value, () => <String>[]).add(entry.key);
      }

      final duplicated = <String, List<String>>{
        for (final entry in owners.entries)
          if (entry.value.length > 1) entry.key: entry.value,
      };

      expect(
        duplicated,
        isEmpty,
        reason:
            'Two constants naming one path is how ClientRoutes and the feature '
            'registries drifted apart; each path gets exactly one owner.',
      );
    });

    test('route table size matches the declared surface', () {
      expect(ClientRouter.routes, hasLength(_declaredRoutes.length));
    });
  });
}
