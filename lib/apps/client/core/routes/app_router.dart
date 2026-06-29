import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Booking
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/available_trips_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/booking_approval_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/booking_wizard_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/daily_booking_flow_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/map_route_selection_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/popular_routes_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/route_overview_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/route_selection_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/search_trip_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/vehicle_details_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/screens/vehicle_listing_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_selection/presentation/screens/seat_selection_screen.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_release/presentation/cubit/seat_release_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_release/presentation/screens/seat_release_screen.dart';

// Auth
import 'package:bmt_app/apps/client/modules/account/auth/presentation/screens/sign_in_screen.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/screens/sign_up_screen.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/screens/auth_success_screen.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:bmt_app/apps/client/modules/account/auth/presentation/cubit/auth_cubit.dart';

// Trips
import 'package:bmt_app/apps/client/modules/trips/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/modules/trips/trips/presentation/screens/trip_details_screen.dart';

// Payments
import 'package:bmt_app/apps/client/modules/payments/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/presentation/cubit/payment_cubit.dart';
import 'package:bmt_app/apps/client/modules/payments/payments/presentation/screens/payment_checkout_screen.dart';

// Services
import 'package:bmt_app/apps/client/modules/services/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/modules/services/packages/presentation/screens/subscription_screen.dart';

// Tracking
import 'package:bmt_app/apps/client/modules/tracking/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/modules/tracking/tracking/presentation/screens/tracking_screen.dart';

// Operations
import 'package:bmt_app/apps/client/modules/operations/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/modules/operations/support/presentation/screens/support_center_screen.dart';
import 'package:bmt_app/apps/client/modules/operations/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:bmt_app/apps/client/modules/operations/support/presentation/screens/support_ticket_details_screen.dart';
import 'package:bmt_app/apps/client/modules/operations/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/client/modules/operations/communication/presentation/screens/communication_screen.dart';

// Rewards
import 'package:bmt_app/apps/client/modules/rewards/referrals/presentation/cubit/referral_rewards_cubit.dart';
import 'package:bmt_app/apps/client/modules/rewards/referrals/presentation/screens/referral_rewards_screen.dart';
import 'package:bmt_app/apps/client/modules/rewards/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/modules/rewards/loyalty/presentation/screens/loyalty_screen.dart';

// Account
import 'package:bmt_app/apps/client/modules/account/settings/presentation/cubit/settings_cubit.dart';
import 'package:bmt_app/apps/client/modules/account/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static int _parseMoney(Object? value) {
    if (value is num) return value.round();
    return num.tryParse(value?.toString() ?? '')?.round() ?? 0;
  }

  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case ClientRoutes.authWelcome:
        return MaterialPageRoute(builder: (_) => _buildAuthScope(const WelcomeScreen()));
      case ClientRoutes.authSignIn:
        return MaterialPageRoute(builder: (_) => _buildAuthScope(const SignInScreen()));
      case ClientRoutes.authSignUp:
        return MaterialPageRoute(builder: (_) => _buildAuthScope(const SignUpScreen()));
      case ClientRoutes.authForgotPassword:
        return MaterialPageRoute(builder: (_) => _buildForgotPasswordScope(const ForgotPasswordScreen()));
      case ClientRoutes.authSuccess:
        final args = settings.arguments;
        final email = args is Map ? args['email']?.toString() : null;
        return MaterialPageRoute(builder: (_) => AuthSuccessScreen(email: email));

      // Booking
      case ClientRoutes.bookingSearch:
        return MaterialPageRoute(
          builder: (_) => _buildBookingScope(
            SearchTripScreen(
              initialQuery: BookingSearchQuery.fromArguments(settings.arguments),
            ),
          ),
        );
      case ClientRoutes.bookingRouteSelection:
        return MaterialPageRoute(builder: (_) => _buildBookingScope(const RouteSelectionScreen()));
      case ClientRoutes.bookingPopularRoutes:
        return MaterialPageRoute(builder: (_) => _buildBookingScope(const PopularRoutesScreen()));
      case ClientRoutes.bookingMapSelection:
        return MaterialPageRoute(builder: (_) => _buildBookingScope(const MapRouteSelectionScreen()));
      case ClientRoutes.bookingAvailableTrips:
        return MaterialPageRoute(builder: (_) => _buildBookingScope(const AvailableTripsScreen()));
      case ClientRoutes.bookingVehicleListing:
        return MaterialPageRoute(builder: (_) => _buildBookingScope(const VehicleListingScreen()));
      case ClientRoutes.bookingVehicleDetails:
        final args = settings.arguments;
        String? vehicleId;
        if (args is Map) {
          vehicleId = args['vehicleId']?.toString();
        }
        return MaterialPageRoute(builder: (_) => _buildBookingScope(VehicleDetailsScreen(vehicleId: vehicleId)));
      case ClientRoutes.bookingWizard:
        final route = settings.arguments;
        if (route is! RouteOptionData) return MaterialPageRoute(builder: (_) => const SizedBox.shrink());
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => BookingWizardCubit(route),
            child: const BookingWizardScreen(),
          ),
        );
      case ClientRoutes.bookingRouteOverview:
        final route = settings.arguments;
        if (route is! RouteOptionData) return MaterialPageRoute(builder: (_) => const SizedBox.shrink());
        return MaterialPageRoute(builder: (_) => RouteOverviewScreen(route: route));
      case ClientRoutes.bookingApproval:
        final args = settings.arguments;
        final m = args is Map ? args : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => BookingApprovalScreen(
            routeName: m['routeName']?.toString() ?? '',
            pickup: m['pickup']?.toString() ?? '',
            dropoff: m['dropoff']?.toString() ?? '',
            departure: m['departure']?.toString() ?? '',
            seat: m['seat']?.toString() ?? '',
            package: m['package']?.toString() ?? '',
            total: m['total']?.toString() ?? '0',
          ),
        );
      case '/daily-booking':
        return MaterialPageRoute(builder: (_) => _buildBookingScope(const DailyBookingFlowScreen()));
      case '/seat-selection':
        return MaterialPageRoute(builder: (_) => _buildSeatSelectionScope(const SeatSelectionScreen()));
      case '/seat-release':
        return MaterialPageRoute(builder: (_) => _buildSeatReleaseScope(const SeatReleaseScreen()));

      // Payments
      case '/payment-checkout':
        final args = settings.arguments;
        final checkoutData = args is Map
            ? PaymentCheckoutData(
                tripId: args['tripId']?.toString() ?? '',
                pickupPoint: args['pickupPoint']?.toString() ?? '',
                destination: args['destination']?.toString() ?? '',
                vehicleNumber: args['vehicleNumber']?.toString() ?? '',
                tripDate: args['tripDate']?.toString() ?? '',
                departureTime: args['departureTime']?.toString() ?? '',
                arrivalTime: args['arrivalTime']?.toString() ?? '',
                selectedSeatId: args['selectedSeatId']?.toString() ?? '',
                selectedSeat: args['selectedSeat']?.toString() ?? '',
                driverName: args['driverName']?.toString() ?? '',
                baseFare: _parseMoney(args['baseFare']),
                serviceFee: _parseMoney(args['serviceFee']),
                tax: _parseMoney(args['tax']),
              )
            : PaymentCheckoutData(
                tripId: '',
                pickupPoint: '',
                destination: '',
                vehicleNumber: '',
                tripDate: '',
                departureTime: '',
                arrivalTime: '',
                selectedSeatId: '',
                selectedSeat: '',
                driverName: '',
              );
        return MaterialPageRoute(builder: (_) => _buildPaymentScope(PaymentCheckoutScreen(checkoutData: checkoutData)));

      // Trips
      case ClientRoutes.tripDetails:
        final args = settings.arguments;
        String? tripId;
        if (args is Map) {
          tripId = args['tripId']?.toString();
        }
        return MaterialPageRoute(builder: (_) => _buildTripsScope(TripDetailsScreen(tripId: tripId)));

      // Services / Tracking / Other
      case ClientRoutes.subscription:
        final args = settings.arguments;
        final hasActiveSub = args is Map && args['hasActiveSubscription'] == true;
        return MaterialPageRoute(builder: (_) => _buildPackagesScope(SubscriptionScreen(hasActiveSubscription: hasActiveSub)));
      case ClientRoutes.tracking:
        final args = settings.arguments;
        String? bookingId;
        String? tripId;
        if (args is Map) {
          bookingId = args['bookingId']?.toString();
          tripId = args['tripId']?.toString();
        }
        return MaterialPageRoute(builder: (_) => _buildTrackingScope(TrackingScreen(bookingId: bookingId, tripId: tripId)));
      case ClientRoutes.support:
        return MaterialPageRoute(builder: (_) => _buildSupportScope(const SupportCenterScreen()));
      case ClientRoutes.createTicket:
        final args = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => _buildSupportScope(CreateSupportTicketScreen(initialCategory: args)));
      case ClientRoutes.ticketDetails:
        final args = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => _buildSupportScope(SupportTicketDetailsScreen(ticketId: args)));
      case '/communication':
        return MaterialPageRoute(builder: (_) => _buildCommunicationScope(const CommunicationScreen()));
      case '/rewards':
        return MaterialPageRoute(builder: (_) => _buildReferralRewardsScope(const ReferralRewardsScreen()));
      case '/loyalty':
        return MaterialPageRoute(builder: (_) => _buildLoyaltyScope(const LoyaltyScreen()));
      case '/settings':
        return MaterialPageRoute(builder: (_) => _buildSettingsScope(const SettingsScreen()));

      default:
        return null;
    }
  }

  static Widget _buildAuthScope(Widget child) {
    return BlocProvider<ClientAuthCubit>(
      create: (_) => clientGetIt<ClientAuthCubit>(),
      child: child,
    );
  }

  static Widget _buildForgotPasswordScope(Widget child) {
    return BlocProvider<ForgotPasswordCubit>(
      create: (_) => clientGetIt<ForgotPasswordCubit>(),
      child: child,
    );
  }

  static Widget _buildTripsScope(Widget child) {
    return BlocProvider<TripsCubit>(
      create: (_) => clientGetIt<TripsCubit>(),
      child: child,
    );
  }

  static Widget _buildBookingScope(Widget child) {
    // Note: Assuming BookingCubit was removed earlier and this is a placeholder 
    // or just pass through if no global booking cubit is required.
    // If BookingCubit is needed, uncomment and import.
    // return BlocProvider<BookingCubit>(
    //   create: (_) => clientGetIt<BookingCubit>(),
    //   child: child,
    // );
    return child;
  }

  static Widget _buildSeatSelectionScope(Widget child) {
    return BlocProvider<SeatSelectionCubit>(
      create: (_) => clientGetIt<SeatSelectionCubit>(),
      child: child,
    );
  }

  static Widget _buildSeatReleaseScope(Widget child) {
    return BlocProvider<SeatReleaseCubit>(
      create: (_) => clientGetIt<SeatReleaseCubit>(),
      child: child,
    );
  }

  static Widget _buildPaymentScope(Widget child) {
    return BlocProvider<PaymentCubit>(
      create: (_) => clientGetIt<PaymentCubit>(),
      child: child,
    );
  }

  static Widget _buildPackagesScope(Widget child) {
    return BlocProvider<PackagesCubit>(
      create: (_) => clientGetIt<PackagesCubit>(),
      child: child,
    );
  }

  static Widget _buildTrackingScope(Widget child) {
    return BlocProvider<TrackingCubit>(
      create: (_) => clientGetIt<TrackingCubit>(),
      child: child,
    );
  }

  static Widget _buildSupportScope(Widget child) {
    return BlocProvider<SupportCubit>(
      create: (_) => clientGetIt<SupportCubit>(),
      child: child,
    );
  }

  static Widget _buildCommunicationScope(Widget child) {
    return BlocProvider<CommunicationCubit>(
      create: (_) => clientGetIt<CommunicationCubit>(),
      child: child,
    );
  }

  static Widget _buildReferralRewardsScope(Widget child) {
    return BlocProvider<ReferralRewardsCubit>(
      create: (_) => clientGetIt<ReferralRewardsCubit>(),
      child: child,
    );
  }

  static Widget _buildLoyaltyScope(Widget child) {
    return BlocProvider<LoyaltyCubit>(
      create: (_) => clientGetIt<LoyaltyCubit>(),
      child: child,
    );
  }

  static Widget _buildSettingsScope(Widget child) {
    return BlocProvider<SettingsCubit>(
      create: (_) => clientGetIt<SettingsCubit>(),
      child: child,
    );
  }
}
