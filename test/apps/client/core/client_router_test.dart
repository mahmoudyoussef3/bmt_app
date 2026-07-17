import 'package:bmt_app/apps/client/core/routes/client_router.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/routes/communication_routes.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/routes/loyalty_routes.dart';
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
  'AuthRoutes.success': AuthRoutes.success,
  'AuthRoutes.phoneLogin': AuthRoutes.phoneLogin,
  'AuthRoutes.otp': AuthRoutes.otp,
  'AuthRoutes.completeProfile': AuthRoutes.completeProfile,
  'BookingRoutes.search': BookingRoutes.search,
  'BookingRoutes.routeSelection': BookingRoutes.routeSelection,
  'BookingRoutes.popularRoutes': BookingRoutes.popularRoutes,
  'BookingRoutes.mapSelection': BookingRoutes.mapSelection,
  'BookingRoutes.availableTrips': BookingRoutes.availableTrips,
  'BookingRoutes.vehicleListing': BookingRoutes.vehicleListing,
  'BookingRoutes.vehicleDetails': BookingRoutes.vehicleDetails,
  'BookingRoutes.dailyBooking': BookingRoutes.dailyBooking,
  'BookingRoutes.wizard': BookingRoutes.wizard,
  'BookingRoutes.routeOverview': BookingRoutes.routeOverview,
  'SeatSelectionRoutes.seatSelection': SeatSelectionRoutes.seatSelection,
  'SeatReleaseRoutes.seatRelease': SeatReleaseRoutes.seatRelease,
  'PaymentRoutes.checkout': PaymentRoutes.checkout,
  'PackagesRoutes.subscription': PackagesRoutes.subscription,
  'TripsRoutes.myTrips': TripsRoutes.myTrips,
  'TripsRoutes.tripDetails': TripsRoutes.tripDetails,
  'TrackingRoutes.tracking': TrackingRoutes.tracking,
  'SupportRoutes.center': SupportRoutes.center,
  'SupportRoutes.createTicket': SupportRoutes.createTicket,
  'SupportRoutes.ticketDetails': SupportRoutes.ticketDetails,
  'CommunicationRoutes.communication': CommunicationRoutes.communication,
  'ReferralRoutes.rewards': ReferralRoutes.rewards,
  'LoyaltyRoutes.loyalty': LoyaltyRoutes.loyalty,
  'ProfileRoutes.profile': ProfileRoutes.profile,
};

void main() {
  group('ClientRouter', () {
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
