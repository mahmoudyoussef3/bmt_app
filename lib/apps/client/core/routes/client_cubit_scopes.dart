import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/social_auth_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_step_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/daily_booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/popular_routes_cubit.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/chat_thread_cubit.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/cubit/client_wallet_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/my_subscription_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/cubit/seat_release_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';

/// Wraps a screen in the cubit(s) it needs, resolved from the client's service
/// locator.
///
/// Each scope hands the route a *fresh* cubit (`registerFactory`), so revisiting
/// a screen starts from a clean state.
abstract final class ClientCubitScopes {
  const ClientCubitScopes._();

  /// Welcome, sign-in and sign-up.
  ///
  /// Carries [SocialAuthCubit] alongside the email/password one because all
  /// three screens offer the alternative methods under their "or" divider.
  /// Today those buttons are inert and never read it — they are built without a
  /// `BlocBuilder` while the providers are switched off — so this is what will
  /// already be in place when they are turned on.
  static Widget auth(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<ClientAuthCubit>(
        create: (_) => clientGetIt<ClientAuthCubit>(),
      ),
      BlocProvider<SocialAuthCubit>(
        create: (_) => clientGetIt<SocialAuthCubit>(),
      ),
    ],
    child: child,
  );

  /// The phone/OTP screens, which need only the alternative-methods cubit.
  static Widget socialAuth(Widget child) => BlocProvider<SocialAuthCubit>(
    create: (_) => clientGetIt<SocialAuthCubit>(),
    child: child,
  );

  static Widget forgotPassword(Widget child) =>
      BlocProvider<ForgotPasswordCubit>(
        create: (_) => clientGetIt<ForgotPasswordCubit>(),
        child: child,
      );

  static Widget resetPassword(Widget child) => BlocProvider<ResetPasswordCubit>(
    create: (_) => clientGetIt<ResetPasswordCubit>(),
    child: child,
  );

  static Widget trips(Widget child) => BlocProvider<TripsCubit>(
    create: (_) => clientGetIt<TripsCubit>()..loadTrips(),
    child: child,
  );

  static Widget tripDetails(Widget child, {String? tripId}) =>
      BlocProvider<TripsCubit>(
        create: (_) => clientGetIt<TripsCubit>()..loadTripDetails(tripId),
        child: child,
      );

  static Widget dailyBooking(Widget child) => BlocProvider<DailyBookingCubit>(
    create: (_) => clientGetIt<DailyBookingCubit>()..load(),
    child: child,
  );

  static Widget popularRoutes(Widget child) => BlocProvider<PopularRoutesCubit>(
    create: (_) => clientGetIt<PopularRoutesCubit>()..load(),
    child: child,
  );

  static Widget seatSelection(Widget child) => BlocProvider<SeatSelectionCubit>(
    create: (_) => clientGetIt<SeatSelectionCubit>(),
    child: child,
  );

  static Widget seatRelease(Widget child) => BlocProvider<SeatReleaseCubit>(
    create: (_) => clientGetIt<SeatReleaseCubit>(),
    child: child,
  );

  static Widget payment(Widget child) => BlocProvider<PaymentCubit>(
    create: (_) => clientGetIt<PaymentCubit>(),
    child: child,
  );

  static Widget mySubscription(Widget child) =>
      BlocProvider<MySubscriptionCubit>(
        create: (_) => clientGetIt<MySubscriptionCubit>()..load(),
        child: child,
      );

  static Widget tracking(Widget child) => BlocProvider<TrackingCubit>(
    create: (_) => clientGetIt<TrackingCubit>(),
    child: child,
  );

  static Widget support(Widget child) => BlocProvider<SupportCubit>(
    create: (_) => clientGetIt<SupportCubit>(),
    child: child,
  );

  /// Scopes one open ticket, loaded fresh from its id.
  static Widget supportTicketDetails(
    Widget child, {
    required String ticketId,
  }) => BlocProvider<SupportCubit>(
    create: (_) => clientGetIt<SupportCubit>()..openTicketDetails(ticketId),
    child: child,
  );

  /// The inbox is a live subscription, not a fetch, so the watch starts with
  /// the scope rather than from the screen's `initState`.
  static Widget notifications(Widget child) => BlocProvider<NotificationsCubit>(
    create: (_) => clientGetIt<NotificationsCubit>()..startWatching(),
    child: child,
  );

  /// The profile hub also offers sign-out, so it needs the auth cubit too.
  static Widget profile(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<ProfileCubit>(create: (_) => clientGetIt<ProfileCubit>()),
      BlocProvider<ClientAuthCubit>(
        create: (_) => clientGetIt<ClientAuthCubit>(),
      ),
    ],
    child: child,
  );

  static Widget routesHub(Widget child) => BlocProvider<RoutesHubCubit>(
    create: (_) => clientGetIt<RoutesHubCubit>(),
    child: child,
  );

  static Widget officesDirectory(Widget child) =>
      BlocProvider<OfficesDirectoryCubit>(
        create: (_) => clientGetIt<OfficesDirectoryCubit>()..load(),
        child: child,
      );

  /// Home runs on two independent loads: its own data, and the marketplace
  /// directory behind the companies rail. They are scoped together so a slow
  /// or failed directory never holds up the departure board.
  static Widget home(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<HomeCubit>(create: (_) => clientGetIt<HomeCubit>()..load()),
      BlocProvider<OfficesDirectoryCubit>(
        create: (_) => clientGetIt<OfficesDirectoryCubit>()..load(),
      ),
    ],
    child: child,
  );

  /// Scopes one office's profile, loading its routes fresh from its id.
  static Widget officeProfile(Widget child, {required String officeId}) =>
      BlocProvider<OfficeProfileCubit>(
        create: (_) => clientGetIt<OfficeProfileCubit>()..load(officeId),
        child: child,
      );

  static Widget communication(Widget child) => BlocProvider<CommunicationCubit>(
    create: (_) => clientGetIt<CommunicationCubit>()..load(),
    child: child,
  );

  /// Scopes one open conversation, loaded fresh from its id.
  static Widget chatThread(Widget child, {required String conversationId}) =>
      BlocProvider<ChatThreadCubit>(
        create: (_) => clientGetIt<ChatThreadCubit>()..load(conversationId),
        child: child,
      );

  static Widget referralRewards(Widget child) =>
      BlocProvider<ReferralRewardsCubit>(
        create: (_) => clientGetIt<ReferralRewardsCubit>(),
        child: child,
      );

  static Widget loyalty(Widget child) => BlocProvider<LoyaltyCubit>(
    create: (_) => clientGetIt<LoyaltyCubit>()..load(),
    child: child,
  );

  static Widget wallet(Widget child) => BlocProvider<ClientWalletCubit>(
    create: (_) => clientGetIt<ClientWalletCubit>()..load(),
    child: child,
  );

  /// The booking wizard runs on three cubits: the session of answers, the step
  /// on screen, and the confirm attempt. They are scoped together so leaving
  /// the wizard discards a half-finished booking with them.
  static Widget bookingWizard(
    Widget child, {
    required RouteOptionData route,
    String? initialPackageId,
  }) => MultiBlocProvider(
    providers: [
      BlocProvider<BookingWizardCubit>(
        create: (_) =>
            BookingWizardCubit(route, initialPackageId: initialPackageId),
      ),
      BlocProvider<BookingWizardStepCubit>(
        create: (_) => BookingWizardStepCubit(),
      ),
      BlocProvider<BookingWizardConfirmCubit>(
        create: (_) => clientGetIt<BookingWizardConfirmCubit>(),
      ),
    ],
    child: child,
  );
}
