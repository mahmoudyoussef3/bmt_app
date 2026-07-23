import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_cubit_scopes.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/auth_success_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/map_pins_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_details_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/vehicle_listing_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/booking_wizard_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/daily_booking_flow_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/map_route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/popular_routes_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_overview_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/search_trip_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/vehicle_details_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/search_date_options.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/vehicle_listing_screen.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/routes/chat_thread_arguments.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/routes/communication_routes.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/screens/chat_thread_screen.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/screens/communication_screen.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/client_shell_screen.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/routes/loyalty_routes.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/screens/loyalty_screen.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/office_profile_screen.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/offices_directory_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/subscription_arguments.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/my_subscription_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/routes/payment_routes.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/payment_checkout_screen.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/legal_document_data.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/routes/profile_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/screens/legal_document_screen.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/screens/profile_screen.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/routes/referral_routes.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/screens/referral_rewards_screen.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/screens/routes_hub_screen.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/routes/seat_release_routes.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/screens/seat_release_screen.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/routes/seat_selection_routes.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/screens/seat_selection_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_center_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_ticket_details_screen.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/trip_details_screen.dart';

/// The Client App's route table.
///
/// Every entry resolves its screen's cubits through [ClientCubitScopes] and its
/// arguments through the owning entity's `fromArguments` factory — route
/// builders stay declarative, and argument shapes stay testable next to the
/// types they produce.
abstract final class ClientRouter {
  const ClientRouter._();

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    ClientRoutes.home: (_) => buildShell(),
    ..._auth,
    ..._booking,
    ..._seats,
    ..._payments,
    ..._trips,
    ..._support,
    ..._engagement,
    ..._profile,
    ..._serverAliases,
  };

  /// Paths the backend writes into `notifications.action_url` that do not match
  /// this app's canonical route names.
  ///
  /// Tapping such a notification pushes the stored string verbatim (here and in
  /// `FcmService`), so an unmapped value used to throw "Could not find a
  /// generator for route". Production rows already carry these strings, so they
  /// are resolved here rather than by rewriting historical data.
  static Map<String, WidgetBuilder> get _serverAliases =>
      <String, WidgetBuilder>{
        // Sent when a package expires or is exhausted ("renew now"), which is
        // what My Subscription is for.
        PackagesRoutes.legacyExpiryAlias: (_) =>
            ClientCubitScopes.mySubscription(const MySubscriptionScreen()),
      };

  /// The authenticated shell hosting the bottom navigation. Also used as the
  /// landing screen once a session is restored, so it is exposed rather than
  /// inlined into the table.
  static Widget buildShell() {
    return ClientShellScreen(
      routesBuilder: (context) => ClientCubitScopes.routesHub(
        RoutesHubScreen(onOpenRoute: _opener(context)),
      ),
      tripsBuilder: (context) =>
          ClientCubitScopes.trips(MyTripsScreen(onOpenRoute: _opener(context))),
      profileBuilder: (context) => ClientCubitScopes.profile(
        ProfileScreen(onOpenRoute: _opener(context)),
      ),
      notificationsBuilder: (context) =>
          ClientCubitScopes.notifications(const NotificationsScreen()),
    );
  }

  /// Screens inside the shell push onto the root navigator rather than owning
  /// navigation themselves.
  static void Function(String, [Object?]) _opener(BuildContext context) {
    return (route, [arguments]) =>
        Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  static Object? _args(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments;

  // --- Auth -----------------------------------------------------------------

  static Map<String, WidgetBuilder> get _auth => <String, WidgetBuilder>{
    AuthRoutes.welcome: (_) => ClientCubitScopes.auth(const WelcomeScreen()),
    AuthRoutes.signIn: (_) => ClientCubitScopes.auth(const SignInScreen()),
    AuthRoutes.signUp: (_) => ClientCubitScopes.auth(const SignUpScreen()),
    AuthRoutes.forgotPassword: (_) =>
        ClientCubitScopes.forgotPassword(const ForgotPasswordScreen()),
    AuthRoutes.success: (context) {
      final args = _args(context);
      return AuthSuccessScreen(
        email: args is Map ? args['email']?.toString() : null,
      );
    },
  };

  // --- Booking --------------------------------------------------------------

  static Map<String, WidgetBuilder> get _booking => <String, WidgetBuilder>{
    BookingRoutes.search: (context) {
      final query = BookingSearchQuery.fromArguments(_args(context));
      return BlocProvider(
        create: (_) =>
            clientGetIt<BookingSearchCubit>()
              ..init(query, todayDate: todaySearchDateLabel(context)),
        child: const SearchTripScreen(),
      );
    },
    BookingRoutes.routeSelection: (context) {
      final query = BookingSearchQuery.fromArguments(_args(context));
      return BlocProvider(
        create: (_) => clientGetIt<RouteResultsCubit>()..load(query),
        child: RouteSelectionScreen(query: query),
      );
    },
    BookingRoutes.popularRoutes: (context) => ClientCubitScopes.popularRoutes(
      PopularRoutesScreen(
        query: BookingSearchQuery.fromArguments(_args(context)),
      ),
    ),
    BookingRoutes.mapSelection: (context) {
      final query = BookingSearchQuery.fromArguments(_args(context));
      return BlocProvider(
        create: (_) => clientGetIt<MapPinsCubit>()..load(query),
        child: const MapRouteSelectionScreen(),
      );
    },
    BookingRoutes.vehicleListing: (context) {
      final query = BookingSearchQuery.fromArguments(_args(context));
      return BlocProvider(
        create: (_) =>
            clientGetIt<VehicleListingCubit>()..load(routeId: query.routeId),
        child: VehicleListingScreen(query: query),
      );
    },
    BookingRoutes.vehicleDetails: (context) {
      final args = _args(context);
      final vehicleId = args is Map ? args['vehicleId']?.toString() : null;
      return BlocProvider(
        create: (_) => clientGetIt<VehicleDetailsCubit>()..load(vehicleId),
        child: VehicleDetailsScreen(vehicleId: vehicleId),
      );
    },
    BookingRoutes.dailyBooking: (_) =>
        ClientCubitScopes.dailyBooking(const DailyBookingFlowScreen()),

    // The wizard and overview are driven by a route object rather than a cubit
    // fetch, so they render nothing if handed the wrong argument type.
    BookingRoutes.wizard: (context) {
      final route = _args(context);
      if (route is! RouteOptionData) return const SizedBox.shrink();
      return ClientCubitScopes.bookingWizard(
        const BookingWizardScreen(),
        route: route,
      );
    },
    BookingRoutes.routeOverview: (context) {
      final route = _args(context);
      if (route is! RouteOptionData) return const SizedBox.shrink();
      return RouteOverviewScreen(route: route);
    },
  };

  // --- Seats ----------------------------------------------------------------

  static Map<String, WidgetBuilder> get _seats => <String, WidgetBuilder>{
    SeatSelectionRoutes.seatSelection: (_) =>
        ClientCubitScopes.seatSelection(const SeatSelectionScreen()),
    SeatReleaseRoutes.seatRelease: (_) =>
        ClientCubitScopes.seatRelease(const SeatReleaseScreen()),
  };

  // --- Payments & packages --------------------------------------------------

  static Map<String, WidgetBuilder> get _payments => <String, WidgetBuilder>{
    PaymentRoutes.checkout: (context) => ClientCubitScopes.payment(
      PaymentCheckoutScreen(
        checkoutData: PaymentCheckoutData.fromArguments(_args(context)),
      ),
    ),
    PackagesRoutes.subscription: (context) => ClientCubitScopes.packages(
      SubscriptionScreen(
        arguments: SubscriptionArguments.fromArguments(_args(context)),
      ),
    ),
    PackagesRoutes.mySubscription: (_) =>
        ClientCubitScopes.mySubscription(const MySubscriptionScreen()),
  };

  // --- Trips & tracking -----------------------------------------------------

  static Map<String, WidgetBuilder> get _trips => <String, WidgetBuilder>{
    TripsRoutes.myTrips: (context) => ClientCubitScopes.trips(
      MyTripsScreen(onOpenRoute: _opener(context), showBackButton: true),
    ),
    TripsRoutes.tripDetails: (context) {
      final args = _args(context);
      final tripId = args is Map ? args['tripId']?.toString() : null;
      return ClientCubitScopes.tripDetails(
        TripDetailsScreen(tripId: tripId),
        tripId: tripId,
      );
    },
    TrackingRoutes.tracking: (context) {
      final args = _args(context);
      return ClientCubitScopes.tracking(
        TrackingScreen(
          bookingId: args is Map ? args['bookingId']?.toString() : null,
          tripId: args is Map ? args['tripId']?.toString() : null,
        ),
      );
    },
  };

  // --- Support --------------------------------------------------------------

  static Map<String, WidgetBuilder> get _support => <String, WidgetBuilder>{
    SupportRoutes.center: (_) =>
        ClientCubitScopes.support(const SupportCenterScreen()),
    SupportRoutes.createTicket: (_) =>
        ClientCubitScopes.support(const CreateSupportTicketScreen()),
    SupportRoutes.ticketDetails: (context) =>
        ClientCubitScopes.supportTicketDetails(
          const SupportTicketDetailsScreen(),
          ticketId: _args(context)! as String,
        ),
  };

  // --- Engagement -----------------------------------------------------------

  static Map<String, WidgetBuilder> get _engagement => <String, WidgetBuilder>{
    CommunicationRoutes.communication: (_) =>
        ClientCubitScopes.communication(const CommunicationScreen()),
    CommunicationRoutes.chatThread: (context) {
      final args = ChatThreadArguments.fromArguments(_args(context));
      if (!args.isValid) return const SizedBox.shrink();
      return ClientCubitScopes.chatThread(
        const ChatThreadScreen(),
        conversationId: args.conversationId,
      );
    },
    OfficesRoutes.directory: (_) =>
        ClientCubitScopes.officesDirectory(const OfficesDirectoryScreen()),
    OfficesRoutes.profile: (context) {
      final office = OfficeSummary.fromArguments(_args(context));
      if (office == null) return const SizedBox.shrink();
      return ClientCubitScopes.officeProfile(
        OfficeProfileScreen(office: office),
        officeId: office.id,
      );
    },
    ReferralRoutes.rewards: (_) =>
        ClientCubitScopes.referralRewards(const ReferralRewardsScreen()),
    LoyaltyRoutes.loyalty: (_) =>
        ClientCubitScopes.loyalty(const LoyaltyScreen()),
  };

  // --- Profile & legal ------------------------------------------------------

  static Map<String, WidgetBuilder> get _profile => <String, WidgetBuilder>{
    ProfileRoutes.profile: (context) =>
        ClientCubitScopes.profile(ProfileScreen(onOpenRoute: _opener(context))),
    ClientRoutes.terms: (_) =>
        const LegalDocumentScreen(document: LegalDocument.terms),
    ClientRoutes.privacy: (_) =>
        const LegalDocumentScreen(document: LegalDocument.privacy),
  };
}
