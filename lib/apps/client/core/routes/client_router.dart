import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_cubit_scopes.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/otp_verification_arguments.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/auth_success_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/map_pins_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_cubit.dart';
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
import 'package:bmt_app/apps/client/features/packages/presentation/screens/my_subscription_screen.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/legal_document_data.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/routes/profile_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/screens/legal_document_screen.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/screens/profile_screen.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/routes/referral_routes.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/screens/referral_rewards_screen.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/screens/routes_hub_screen.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/routes/seat_release_routes.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/screens/seat_release_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_center_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_ticket_details_screen.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/routes/wallet_routes.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/screens/client_wallet_screen.dart';
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
    // Reached only via the `easyway://reset-password/` deep link handled in
    // `ClientApp`. The recovery tokens travel through Supabase's own session
    // (see `ResetPasswordCubit`), not through this route's arguments.
    AuthRoutes.resetPassword: (_) =>
        ClientCubitScopes.resetPassword(const ResetPasswordScreen()),
    AuthRoutes.success: (context) {
      final args = _args(context);
      return AuthSuccessScreen(
        email: args is Map ? args['email']?.toString() : null,
      );
    },
    // Passwordless sign-in by SMS. Both screens are registered and navigable,
    // but nothing live points at them yet: the provider buttons that open
    // `phoneLogin` are inert while `AuthMethod.phoneOtp.isAvailable` is false.
    AuthRoutes.phoneLogin: (_) =>
        ClientCubitScopes.socialAuth(const PhoneLoginScreen()),
    AuthRoutes.otpVerification: (context) {
      final args = OtpVerificationArguments.fromArguments(_args(context));
      // Reached without a number means reached out of order — a stale link, a
      // restored stack. Six boxes for a code that was never sent is a dead end,
      // so send the rider back to the step that produces one.
      if (!args.isValid) {
        return ClientCubitScopes.socialAuth(const PhoneLoginScreen());
      }
      return ClientCubitScopes.socialAuth(OtpVerificationScreen(args: args));
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
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => clientGetIt<RouteResultsCubit>()..load(query),
          ),
          // Not loaded here: which office sells this corridor is only known
          // once the results land, so the packages shelf asks for itself.
          BlocProvider(create: (_) => clientGetIt<RoutePackagesCubit>()),
        ],
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
    // fetch, so they render nothing if handed the wrong argument type. The
    // wizard also accepts a map wrapping the route alongside a package the
    // rider reviewed before searching, so its package step can open with it
    // pre-selected.
    BookingRoutes.wizard: (context) {
      final args = _args(context);
      final route = args is Map ? args['route'] : args;
      if (route is! RouteOptionData) return const SizedBox.shrink();
      final initialPackageId = args is Map
          ? args['initialPackageId']?.toString()
          : null;
      return ClientCubitScopes.bookingWizard(
        const BookingWizardScreen(),
        route: route,
        initialPackageId: initialPackageId,
      );
    },
    BookingRoutes.routeOverview: (context) {
      final route = _args(context);
      if (route is! RouteOptionData) return const SizedBox.shrink();
      return RouteOverviewScreen(route: route);
    },
  };

  // --- Seats ----------------------------------------------------------------

  // `SeatSelectionRoutes.seatSelection` is deliberately absent. It fronted a
  // second, older booking funnel (seat map → PaymentCheckoutScreen →
  // PaymentProcessingScreen) that nothing navigates to and that no longer works:
  // its confirm call omits `p_package_id` / `p_plan_start_date`, which the live
  // `confirm_seat_booking_v2` requires, so PostgREST cannot resolve the function
  // at all. It also called confirm *without* first taking a seat lock, and
  // rendered "Payment submitted" after a card checkout the rider had cancelled.
  //
  // Seats are chosen in the booking wizard (`BookingRoutes.wizard`), which locks
  // and confirms as one unit through `PlaceSeatBookingUseCase`. Registering the
  // old path here made a broken money flow one `action_url` away from a rider.
  static Map<String, WidgetBuilder> get _seats => <String, WidgetBuilder>{
    SeatReleaseRoutes.seatRelease: (_) =>
        ClientCubitScopes.seatRelease(const SeatReleaseScreen()),
  };

  // --- Payments & packages --------------------------------------------------

  // `PaymentRoutes.checkout` is deliberately absent — see the note on [_seats].
  // It was the second half of the dead funnel, and the only caller left
  // (the package catalogue) reached it with no trip and no seat, so its pay bar
  // could never unblock: a screen a rider could open but never finish.
  //
  // The plan catalogue itself is gone too: it re-listed what an office profile
  // already shows, and packages are paid for inside the wizard's package +
  // payment steps, which is also the only place a subscription can be bound to
  // the route it is sold for.
  static Map<String, WidgetBuilder> get _payments => <String, WidgetBuilder>{
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
    // A notification tap or a stale `action_url` can reach this path without an
    // id. Falling back to the ticket list is the honest answer; the previous
    // `_args(context)! as String` crashed on the null-check operator instead.
    SupportRoutes.ticketDetails: (context) {
      final ticketId = _args(context);
      if (ticketId is! String || ticketId.trim().isEmpty) {
        return ClientCubitScopes.support(const SupportCenterScreen());
      }
      return ClientCubitScopes.supportTicketDetails(
        const SupportTicketDetailsScreen(),
        ticketId: ticketId,
      );
    },
  };

  // --- Engagement -----------------------------------------------------------

  static Map<String, WidgetBuilder> get _engagement => <String, WidgetBuilder>{
    CommunicationRoutes.communication: (_) =>
        ClientCubitScopes.communication(const CommunicationScreen()),
    CommunicationRoutes.chatThread: (context) {
      final args = ChatThreadArguments.fromArguments(_args(context));
      // A stale notification/deep link can reach this without a valid
      // conversation id. Falling back to the thread list is the honest
      // answer; a blank SizedBox with no app bar or back button is a dead end.
      if (!args.isValid) {
        return ClientCubitScopes.communication(const CommunicationScreen());
      }
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
    // Also the destination every wallet and refund notification deep-links to:
    // the backend stamps `action_url = '/wallet'`, which
    // `resolveNotificationDestination` passes through unchanged.
    WalletRoutes.wallet: (_) =>
        ClientCubitScopes.wallet(const ClientWalletScreen()),
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
