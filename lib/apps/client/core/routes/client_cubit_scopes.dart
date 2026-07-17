import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/phone_auth_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_cubit.dart';
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
/// a screen starts from a clean state. The one exception is [phoneAuth], which
/// shares a single instance across the multi-step OTP flow.
abstract final class ClientCubitScopes {
  const ClientCubitScopes._();

  static Widget auth(Widget child) => BlocProvider<ClientAuthCubit>(
    create: (_) => clientGetIt<ClientAuthCubit>(),
    child: child,
  );

  static Widget forgotPassword(Widget child) =>
      BlocProvider<ForgotPasswordCubit>(
        create: (_) => clientGetIt<ForgotPasswordCubit>(),
        child: child,
      );

  /// The phone sign-in flow spans several screens (phone → OTP → profile) and
  /// must observe one cubit's state throughout, so this shares the instance
  /// provided at the app root rather than creating a new one.
  static Widget phoneAuth(Widget child) =>
      BlocProvider.value(value: clientGetIt<PhoneAuthCubit>(), child: child);

  static Widget trips(Widget child) => BlocProvider<TripsCubit>(
    create: (_) => clientGetIt<TripsCubit>(),
    child: child,
  );

  static Widget booking(Widget child) => BlocProvider<BookingCubit>(
    create: (_) => clientGetIt<BookingCubit>(),
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

  static Widget packages(Widget child) => BlocProvider<PackagesCubit>(
    create: (_) => clientGetIt<PackagesCubit>(),
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

  static Widget notifications(Widget child) => BlocProvider<NotificationsCubit>(
    create: (_) => clientGetIt<NotificationsCubit>(),
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

  static Widget communication(Widget child) => BlocProvider<CommunicationCubit>(
    create: (_) => clientGetIt<CommunicationCubit>(),
    child: child,
  );

  static Widget referralRewards(Widget child) =>
      BlocProvider<ReferralRewardsCubit>(
        create: (_) => clientGetIt<ReferralRewardsCubit>(),
        child: child,
      );

  static Widget loyalty(Widget child) => BlocProvider<LoyaltyCubit>(
    create: (_) => clientGetIt<LoyaltyCubit>(),
    child: child,
  );
}
