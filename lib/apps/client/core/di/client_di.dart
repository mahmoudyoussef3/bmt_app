import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/check_onboarding_status_usecase.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../../../core/security/secure_storage.dart';

import '../../features/auth/data/datasources/client_auth_datasource.dart';
import '../../features/auth/data/datasources/supabase_client_auth_datasource.dart';
import '../../features/auth/data/repositories/client_auth_repository_impl.dart';
import '../../features/auth/data/repositories/remember_me_repository_impl.dart';
import '../../features/auth/domain/repositories/client_auth_repository.dart';
import '../../features/auth/domain/repositories/remember_me_repository.dart';
import '../../features/auth/domain/usecases/clear_remembered_credentials_usecase.dart';
import '../../features/auth/domain/usecases/get_remembered_credentials_usecase.dart';
import '../../features/auth/domain/usecases/save_remembered_credentials_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import '../../features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../../features/auth/presentation/cubit/remember_me_coordinator.dart';
import '../storage/remember_me_store.dart';

import '../../features/booking/data/datasources/booking_search_datasource.dart';
import '../../features/booking/data/datasources/daily_booking_datasource.dart';
import '../../features/booking/data/datasources/supabase_booking_search_datasource.dart';
import '../../features/booking/data/datasources/supabase_daily_booking_datasource.dart';
import '../../features/booking/data/datasources/supabase_vehicle_booking_datasource.dart';
import '../../features/booking/data/datasources/vehicle_booking_datasource.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/get_booking_routes_usecase.dart';
import '../../features/booking/domain/usecases/get_daily_booking_data_usecase.dart';
import '../../features/booking/domain/usecases/get_map_pins_usecase.dart';
import '../../features/booking/domain/usecases/get_popular_routes_usecase.dart';
import '../../features/booking/domain/usecases/get_search_options_usecase.dart';
import '../../features/booking/domain/usecases/get_vehicle_details_usecase.dart';
import '../../features/booking/domain/usecases/get_vehicles_usecase.dart';
import '../../features/booking/domain/usecases/sort_vehicles_usecase.dart';
import '../../features/booking/presentation/cubit/booking_search_cubit.dart';
import '../../features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import '../../features/booking/presentation/cubit/daily_booking_cubit.dart';
import '../../features/booking/presentation/cubit/map_pins_cubit.dart';
import '../../features/booking/presentation/cubit/popular_routes_cubit.dart';
import '../../features/booking/presentation/cubit/route_results_cubit.dart';
import '../../features/booking/presentation/cubit/vehicle_details_cubit.dart';
import '../../features/booking/presentation/cubit/vehicle_listing_cubit.dart';
import '../../features/communication/data/datasources/communication_datasource.dart';
import '../../features/communication/data/datasources/supabase_communication_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/usecases/get_conversation_usecase.dart';
import '../../features/communication/domain/usecases/get_conversations_usecase.dart';
import '../../features/communication/domain/usecases/send_conversation_message_usecase.dart';
import '../../features/communication/presentation/cubit/chat_thread_cubit.dart';
import '../../features/communication/presentation/cubit/communication_cubit.dart';
import '../../features/home/data/datasources/home_datasource.dart';
import '../../features/home/data/datasources/supabase_home_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data_usecase.dart';
import '../../features/home/domain/usecases/watch_home_changes_usecase.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/loyalty/data/datasources/loyalty_datasource.dart';
import '../../features/loyalty/data/datasources/supabase_loyalty_datasource.dart';
import '../../features/loyalty/data/repositories/loyalty_repository_impl.dart';
import '../../features/loyalty/domain/repositories/loyalty_repository.dart';
import '../../features/loyalty/domain/usecases/get_loyalty_data_usecase.dart';
import '../../features/loyalty/domain/usecases/redeem_loyalty_reward_usecase.dart';
import '../../features/loyalty/presentation/cubit/loyalty_cubit.dart';
import '../../features/notifications/data/datasources/supabase_notifications_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/watch_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/mark_as_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import '../../features/notifications/domain/usecases/watch_unread_count_usecase.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/cubit/notification_badge_cubit.dart';
import '../../features/payments/data/datasources/payment_datasource.dart';
import '../../features/payments/data/datasources/supabase_payment_datasource.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/payments/domain/usecases/apply_promo_code_usecase.dart';
import '../../features/payments/domain/usecases/await_card_settlement_usecase.dart';
import '../../features/payments/domain/usecases/create_card_payment_session_usecase.dart';
import '../../features/payments/domain/usecases/get_payment_methods_usecase.dart';
import '../../features/payments/domain/usecases/start_card_checkout_usecase.dart';
import '../../features/payments/domain/usecases/upload_payment_receipt_usecase.dart';
import '../../features/payments/presentation/cubit/payment_cubit.dart';
import '../../features/packages/data/datasources/packages_datasource.dart';
import '../../features/packages/data/datasources/supabase_packages_datasource.dart';
import '../../features/packages/data/repositories/packages_repository_impl.dart';
import '../../features/packages/domain/repositories/packages_repository.dart';
import '../../features/packages/domain/usecases/filter_packages_usecase.dart';
import '../../features/packages/domain/usecases/get_my_subscription_usecase.dart';
import '../../features/packages/domain/usecases/get_packages_usecase.dart';
import '../../features/packages/presentation/cubit/my_subscription_cubit.dart';
import '../../features/packages/presentation/cubit/packages_cubit.dart';
import '../../features/profile/data/datasources/profile_datasource.dart';
import '../../features/profile/data/datasources/supabase_profile_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_data_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/routes/data/datasources/supabase_routes_hub_datasource.dart';
import '../../features/routes/data/repositories/routes_hub_repository_impl.dart';
import '../../features/routes/domain/repositories/routes_hub_repository.dart';
import '../../features/routes/domain/usecases/get_routes_hub_data_usecase.dart';
import '../../features/routes/presentation/cubit/routes_hub_cubit.dart';
import '../../features/referrals/data/datasources/supabase_referral_rewards_datasource.dart';
import '../../features/referrals/data/repositories/referral_rewards_repository_impl.dart';
import '../../features/referrals/domain/repositories/referral_rewards_repository.dart';
import '../../features/referrals/domain/usecases/get_referral_rewards_data_usecase.dart';
import '../../features/referrals/domain/usecases/update_referral_rewards_usecase.dart';
import '../../features/referrals/presentation/cubit/referral_rewards_cubit.dart';
import '../../features/seat_selection/data/datasources/seat_selection_datasource.dart';
import '../../features/seat_selection/data/datasources/supabase_seat_selection_datasource.dart';
import '../../features/seat_selection/data/repositories/seat_selection_repository_impl.dart';
import '../../features/seat_selection/domain/repositories/seat_selection_repository.dart';
import '../../features/seat_selection/domain/usecases/get_seat_selection_data_usecase.dart';
import '../../features/seat_selection/domain/usecases/select_seat_usecase.dart';
import '../../features/seat_selection/domain/usecases/book_trip_seat_usecase.dart';
import '../../features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
import '../../features/seat_selection/domain/usecases/release_trip_seat_lock_usecase.dart';
import '../../features/seat_selection/domain/usecases/confirm_seat_booking_usecase.dart';
import '../../features/seat_selection/domain/usecases/update_existing_booking_payment_usecase.dart';
import '../../features/seat_selection/domain/usecases/place_seat_booking_usecase.dart';
import '../../features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import '../../features/seat_release/data/datasources/supabase_seat_release_datasource.dart';
import '../../features/seat_release/data/repositories/seat_release_repository_impl.dart';
import '../../features/seat_release/domain/repositories/seat_release_repository.dart';
import '../../features/seat_release/domain/usecases/get_seat_release_data_usecase.dart';
import '../../features/seat_release/presentation/cubit/seat_release_cubit.dart';
import '../../features/support/data/datasources/supabase_support_datasource.dart';
import '../../features/support/data/repositories/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/domain/usecases/create_support_ticket_usecase.dart';
import '../../features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import '../../features/support/domain/usecases/get_ticket_details_usecase.dart';

import '../../features/support/presentation/cubit/support_cubit.dart';
import '../../features/trips/data/datasources/supabase_trip_reviews_datasource.dart';
import '../../features/trips/data/datasources/supabase_trips_datasource.dart';
import '../../features/trips/data/datasources/trip_reviews_datasource.dart';
import '../../features/trips/data/datasources/trips_datasource.dart';
import '../../features/trips/data/repositories/trip_reviews_repository_impl.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/repositories/trip_reviews_repository.dart';
import '../../features/trips/domain/repositories/trips_repository.dart';
import '../../features/trips/domain/usecases/cancel_booking_usecase.dart';
import '../../features/trips/domain/usecases/get_trip_details_usecase.dart';
import '../../features/trips/domain/usecases/get_trip_review_usecase.dart';
import '../../features/trips/domain/usecases/get_trips_usecase.dart';
import '../../features/trips/domain/usecases/submit_trip_review_usecase.dart';
import '../../features/trips/domain/usecases/watch_trips_usecase.dart';
import '../../features/trips/presentation/cubit/trip_review_cubit.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../../features/tracking/data/datasources/supabase_tracking_datasource.dart';
import '../../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import '../../features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import '../../features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import '../../features/tracking/presentation/cubit/tracking_cubit.dart';
import '../../../../core/network/network_di.dart';

final GetIt clientGetIt = GetIt.instance;

void registerClientDependencies() {
  _registerCoreDependencies();
  _registerAuthDependencies();
  // Register Core Networking (Dio, Retrofit ApiService)
  registerNetworkDependencies(clientGetIt);

  // Register Core dependencies();
  _registerOnboardingDependencies();
  _registerHomeDependencies();
  _registerTripsDependencies();
  _registerBookingDependencies();
  _registerSeatSelectionDependencies();
  _registerSeatReleaseDependencies();
  _registerPaymentDependencies();
  _registerPackagesDependencies();
  _registerTrackingDependencies();
  _registerSupportDependencies();
  _registerNotificationsDependencies();
  _registerProfileDependencies();
  _registerRoutesHubDependencies();
  _registerCommunicationDependencies();
  _registerReferralRewardsDependencies();
  _registerLoyaltyDependencies();
}

void _registerCoreDependencies() {
  if (!clientGetIt.isRegistered<SupabaseClient>()) {
    clientGetIt.registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    );
  }
}

void _registerOnboardingDependencies() {
  if (!clientGetIt.isRegistered<OnboardingLocalDataSource>()) {
    clientGetIt.registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSourceImpl(SecureStorage()),
    );
  }

  if (!clientGetIt.isRegistered<OnboardingRepository>()) {
    clientGetIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(clientGetIt<OnboardingLocalDataSource>()),
    );
  }

  if (!clientGetIt.isRegistered<CheckOnboardingStatusUseCase>()) {
    clientGetIt.registerLazySingleton<CheckOnboardingStatusUseCase>(
      () => CheckOnboardingStatusUseCase(clientGetIt<OnboardingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<CompleteOnboardingUseCase>()) {
    clientGetIt.registerLazySingleton<CompleteOnboardingUseCase>(
      () => CompleteOnboardingUseCase(clientGetIt<OnboardingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<OnboardingCubit>()) {
    clientGetIt.registerFactory<OnboardingCubit>(
      () => OnboardingCubit(
        clientGetIt<CheckOnboardingStatusUseCase>(),
        clientGetIt<CompleteOnboardingUseCase>(),
      ),
    );
  }
}

void _registerAuthDependencies() {
  if (!clientGetIt.isRegistered<ClientAuthDatasource>()) {
    clientGetIt.registerLazySingleton<ClientAuthDatasource>(
      () => SupabaseClientAuthDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<ClientAuthRepository>()) {
    clientGetIt.registerLazySingleton<ClientAuthRepository>(
      () => ClientAuthRepositoryImpl(clientGetIt<ClientAuthDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<SignInWithEmailUseCase>()) {
    clientGetIt.registerLazySingleton<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(clientGetIt<ClientAuthRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SignUpWithEmailUseCase>()) {
    clientGetIt.registerLazySingleton<SignUpWithEmailUseCase>(
      () => SignUpWithEmailUseCase(clientGetIt<ClientAuthRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SignOutUseCase>()) {
    clientGetIt.registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(clientGetIt<ClientAuthRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<RememberMeStore>()) {
    clientGetIt.registerLazySingleton<RememberMeStore>(() => RememberMeStore());
  }

  if (!clientGetIt.isRegistered<RememberMeRepository>()) {
    clientGetIt.registerLazySingleton<RememberMeRepository>(
      () => RememberMeRepositoryImpl(clientGetIt<RememberMeStore>()),
    );
  }

  if (!clientGetIt.isRegistered<SaveRememberedCredentialsUseCase>()) {
    clientGetIt.registerLazySingleton<SaveRememberedCredentialsUseCase>(
      () =>
          SaveRememberedCredentialsUseCase(clientGetIt<RememberMeRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetRememberedCredentialsUseCase>()) {
    clientGetIt.registerLazySingleton<GetRememberedCredentialsUseCase>(
      () =>
          GetRememberedCredentialsUseCase(clientGetIt<RememberMeRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<ClearRememberedCredentialsUseCase>()) {
    clientGetIt.registerLazySingleton<ClearRememberedCredentialsUseCase>(
      () => ClearRememberedCredentialsUseCase(
        clientGetIt<RememberMeRepository>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<ClientAuthCubit>()) {
    clientGetIt.registerFactory<ClientAuthCubit>(
      () => ClientAuthCubit(
        signInWithEmail: clientGetIt<SignInWithEmailUseCase>(),
        signUpWithEmail: clientGetIt<SignUpWithEmailUseCase>(),
        signOut: clientGetIt<SignOutUseCase>(),
        rememberMe: RememberMeCoordinator(
          save: clientGetIt<SaveRememberedCredentialsUseCase>(),
          get: clientGetIt<GetRememberedCredentialsUseCase>(),
          clear: clientGetIt<ClearRememberedCredentialsUseCase>(),
        ),
      ),
    );
  }

  if (!clientGetIt.isRegistered<SendPasswordResetEmailUseCase>()) {
    clientGetIt.registerLazySingleton<SendPasswordResetEmailUseCase>(
      () => SendPasswordResetEmailUseCase(clientGetIt<ClientAuthRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<ForgotPasswordCubit>()) {
    clientGetIt.registerFactory<ForgotPasswordCubit>(
      () => ForgotPasswordCubit(clientGetIt<SendPasswordResetEmailUseCase>()),
    );
  }
}

void _registerHomeDependencies() {
  if (!clientGetIt.isRegistered<HomeDatasource>()) {
    clientGetIt.registerLazySingleton<HomeDatasource>(
      () => SupabaseHomeDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<HomeRepository>()) {
    clientGetIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(clientGetIt<HomeDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetHomeDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetHomeDataUseCase>(
      () => GetHomeDataUseCase(clientGetIt<HomeRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<WatchHomeChangesUseCase>()) {
    clientGetIt.registerLazySingleton<WatchHomeChangesUseCase>(
      () => WatchHomeChangesUseCase(clientGetIt<HomeRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<HomeCubit>()) {
    clientGetIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        clientGetIt<GetHomeDataUseCase>(),
        clientGetIt<WatchHomeChangesUseCase>(),
      ),
    );
  }
}

void _registerTripsDependencies() {
  if (!clientGetIt.isRegistered<TripsDatasource>()) {
    clientGetIt.registerLazySingleton<TripsDatasource>(
      () => SupabaseTripsDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<TripsRepository>()) {
    clientGetIt.registerLazySingleton<TripsRepository>(
      () => TripsRepositoryImpl(clientGetIt<TripsDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTripsUseCase>()) {
    clientGetIt.registerLazySingleton<GetTripsUseCase>(
      () => GetTripsUseCase(clientGetIt<TripsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTripDetailsUseCase>()) {
    clientGetIt.registerLazySingleton<GetTripDetailsUseCase>(
      () => GetTripDetailsUseCase(clientGetIt<TripsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<WatchTripsUseCase>()) {
    clientGetIt.registerLazySingleton<WatchTripsUseCase>(
      () => WatchTripsUseCase(clientGetIt<TripsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<CancelBookingUseCase>()) {
    clientGetIt.registerLazySingleton<CancelBookingUseCase>(
      () => CancelBookingUseCase(clientGetIt<TripsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<TripsCubit>()) {
    clientGetIt.registerFactory<TripsCubit>(
      () => TripsCubit(
        getTrips: clientGetIt<GetTripsUseCase>(),
        getTripDetails: clientGetIt<GetTripDetailsUseCase>(),
        watchTrips: clientGetIt<WatchTripsUseCase>(),
        cancelBooking: clientGetIt<CancelBookingUseCase>(),
      ),
    );
  }

  _registerTripReviewDependencies();
}

void _registerTripReviewDependencies() {
  if (!clientGetIt.isRegistered<TripReviewsDatasource>()) {
    clientGetIt.registerLazySingleton<TripReviewsDatasource>(
      () => SupabaseTripReviewsDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<TripReviewsRepository>()) {
    clientGetIt.registerLazySingleton<TripReviewsRepository>(
      () => TripReviewsRepositoryImpl(clientGetIt<TripReviewsDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTripReviewUseCase>()) {
    clientGetIt.registerLazySingleton<GetTripReviewUseCase>(
      () => GetTripReviewUseCase(clientGetIt<TripReviewsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SubmitTripReviewUseCase>()) {
    clientGetIt.registerLazySingleton<SubmitTripReviewUseCase>(
      () => SubmitTripReviewUseCase(clientGetIt<TripReviewsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<TripReviewCubit>()) {
    clientGetIt.registerFactory<TripReviewCubit>(
      () => TripReviewCubit(
        getReview: clientGetIt<GetTripReviewUseCase>(),
        submitReview: clientGetIt<SubmitTripReviewUseCase>(),
      ),
    );
  }
}

void _registerBookingDependencies() {
  if (!clientGetIt.isRegistered<BookingSearchDatasource>()) {
    clientGetIt.registerLazySingleton<BookingSearchDatasource>(
      () => SupabaseBookingSearchDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<DailyBookingDatasource>()) {
    clientGetIt.registerLazySingleton<DailyBookingDatasource>(
      () => SupabaseDailyBookingDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<VehicleBookingDatasource>()) {
    clientGetIt.registerLazySingleton<VehicleBookingDatasource>(
      () => SupabaseVehicleBookingDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<BookingRepository>()) {
    clientGetIt.registerLazySingleton<BookingRepository>(
      () => BookingRepositoryImpl(
        searchDatasource: clientGetIt<BookingSearchDatasource>(),
        dailyBookingDatasource: clientGetIt<DailyBookingDatasource>(),
        vehicleDatasource: clientGetIt<VehicleBookingDatasource>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<GetDailyBookingDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetDailyBookingDataUseCase>(
      () => GetDailyBookingDataUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetBookingRoutesUseCase>()) {
    clientGetIt.registerLazySingleton<GetBookingRoutesUseCase>(
      () => GetBookingRoutesUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetPopularRoutesUseCase>()) {
    clientGetIt.registerLazySingleton<GetPopularRoutesUseCase>(
      () => GetPopularRoutesUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetMapPinsUseCase>()) {
    clientGetIt.registerLazySingleton<GetMapPinsUseCase>(
      () => GetMapPinsUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetSearchOptionsUseCase>()) {
    clientGetIt.registerLazySingleton<GetSearchOptionsUseCase>(
      () => GetSearchOptionsUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetVehiclesUseCase>()) {
    clientGetIt.registerLazySingleton<GetVehiclesUseCase>(
      () => GetVehiclesUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetVehicleDetailsUseCase>()) {
    clientGetIt.registerLazySingleton<GetVehicleDetailsUseCase>(
      () => GetVehicleDetailsUseCase(clientGetIt<BookingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SortVehiclesUseCase>()) {
    clientGetIt.registerLazySingleton<SortVehiclesUseCase>(
      () => const SortVehiclesUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<DailyBookingCubit>()) {
    clientGetIt.registerFactory<DailyBookingCubit>(
      () => DailyBookingCubit(clientGetIt<GetDailyBookingDataUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<RouteResultsCubit>()) {
    clientGetIt.registerFactory<RouteResultsCubit>(
      () => RouteResultsCubit(clientGetIt<GetBookingRoutesUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<PopularRoutesCubit>()) {
    clientGetIt.registerFactory<PopularRoutesCubit>(
      () => PopularRoutesCubit(clientGetIt<GetPopularRoutesUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<MapPinsCubit>()) {
    clientGetIt.registerFactory<MapPinsCubit>(
      () => MapPinsCubit(clientGetIt<GetMapPinsUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<BookingSearchCubit>()) {
    clientGetIt.registerFactory<BookingSearchCubit>(
      () => BookingSearchCubit(clientGetIt<GetSearchOptionsUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<VehicleListingCubit>()) {
    clientGetIt.registerFactory<VehicleListingCubit>(
      () => VehicleListingCubit(
        clientGetIt<GetVehiclesUseCase>(),
        clientGetIt<SortVehiclesUseCase>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<VehicleDetailsCubit>()) {
    clientGetIt.registerFactory<VehicleDetailsCubit>(
      () => VehicleDetailsCubit(
        clientGetIt<GetVehicleDetailsUseCase>(),
        clientGetIt<GetVehiclesUseCase>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<BookingWizardConfirmCubit>()) {
    clientGetIt.registerFactory<BookingWizardConfirmCubit>(
      () => BookingWizardConfirmCubit(
        placeSeatBooking: clientGetIt<PlaceSeatBookingUseCase>(),
        updateExistingBookingPayment:
            clientGetIt<UpdateExistingBookingPaymentUseCase>(),
        startCardCheckout: clientGetIt<StartCardCheckoutUseCase>(),
        awaitCardSettlement: clientGetIt<AwaitCardSettlementUseCase>(),
      ),
    );
  }
}

void _registerSeatSelectionDependencies() {
  if (!clientGetIt.isRegistered<SeatSelectionDatasource>()) {
    clientGetIt.registerLazySingleton<SeatSelectionDatasource>(
      () => SupabaseSeatSelectionDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<SeatSelectionRepository>()) {
    clientGetIt.registerLazySingleton<SeatSelectionRepository>(
      () => SeatSelectionRepositoryImpl(clientGetIt<SeatSelectionDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetSeatSelectionDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetSeatSelectionDataUseCase>(
      () => GetSeatSelectionDataUseCase(clientGetIt<SeatSelectionRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SelectSeatUseCase>()) {
    clientGetIt.registerLazySingleton<SelectSeatUseCase>(
      () => const SelectSeatUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<BookTripSeatUseCase>()) {
    clientGetIt.registerLazySingleton<BookTripSeatUseCase>(
      () => BookTripSeatUseCase(clientGetIt<SeatSelectionRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<LockTripSeatUseCase>()) {
    clientGetIt.registerLazySingleton<LockTripSeatUseCase>(
      () => LockTripSeatUseCase(clientGetIt<SeatSelectionRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<ReleaseTripSeatLockUseCase>()) {
    clientGetIt.registerLazySingleton<ReleaseTripSeatLockUseCase>(
      () => ReleaseTripSeatLockUseCase(clientGetIt<SeatSelectionRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<ConfirmSeatBookingUseCase>()) {
    clientGetIt.registerLazySingleton<ConfirmSeatBookingUseCase>(
      () => ConfirmSeatBookingUseCase(clientGetIt<SeatSelectionRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<UpdateExistingBookingPaymentUseCase>()) {
    clientGetIt.registerLazySingleton<UpdateExistingBookingPaymentUseCase>(
      () => UpdateExistingBookingPaymentUseCase(
        clientGetIt<SeatSelectionRepository>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<PlaceSeatBookingUseCase>()) {
    clientGetIt.registerLazySingleton<PlaceSeatBookingUseCase>(
      () => PlaceSeatBookingUseCase(
        lockTripSeat: clientGetIt<LockTripSeatUseCase>(),
        confirmSeatBooking: clientGetIt<ConfirmSeatBookingUseCase>(),
        releaseTripSeatLock: clientGetIt<ReleaseTripSeatLockUseCase>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<SeatSelectionCubit>()) {
    clientGetIt.registerFactory<SeatSelectionCubit>(
      () => SeatSelectionCubit(
        getSeatSelectionData: clientGetIt<GetSeatSelectionDataUseCase>(),
        selectSeat: clientGetIt<SelectSeatUseCase>(),
        lockTripSeat: clientGetIt<LockTripSeatUseCase>(),
      ),
    );
  }
}

void _registerSeatReleaseDependencies() {
  if (!clientGetIt.isRegistered<SupabaseSeatReleaseDatasource>()) {
    clientGetIt.registerLazySingleton<SupabaseSeatReleaseDatasource>(
      () => SupabaseSeatReleaseDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<SeatReleaseRepository>()) {
    clientGetIt.registerLazySingleton<SeatReleaseRepository>(
      () => SeatReleaseRepositoryImpl(
        clientGetIt<SupabaseSeatReleaseDatasource>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<GetSeatReleaseDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetSeatReleaseDataUseCase>(
      () => GetSeatReleaseDataUseCase(clientGetIt<SeatReleaseRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SeatReleaseCubit>()) {
    clientGetIt.registerFactory<SeatReleaseCubit>(
      () => SeatReleaseCubit(clientGetIt<GetSeatReleaseDataUseCase>()),
    );
  }
}

void _registerPaymentDependencies() {
  if (!clientGetIt.isRegistered<PaymentDatasource>()) {
    clientGetIt.registerLazySingleton<PaymentDatasource>(
      () => SupabasePaymentDatasource(clientGetIt<SupabaseClient>()),
    );
  }

  if (!clientGetIt.isRegistered<PaymentRepository>()) {
    clientGetIt.registerLazySingleton<PaymentRepository>(
      () => PaymentRepositoryImpl(clientGetIt<PaymentDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetPaymentMethodsUseCase>()) {
    clientGetIt.registerLazySingleton<GetPaymentMethodsUseCase>(
      () => GetPaymentMethodsUseCase(clientGetIt<PaymentRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<UploadPaymentReceiptUseCase>()) {
    clientGetIt.registerLazySingleton<UploadPaymentReceiptUseCase>(
      () => UploadPaymentReceiptUseCase(clientGetIt<PaymentRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<CreateCardPaymentSessionUseCase>()) {
    clientGetIt.registerLazySingleton<CreateCardPaymentSessionUseCase>(
      () => CreateCardPaymentSessionUseCase(clientGetIt<PaymentRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<AwaitCardSettlementUseCase>()) {
    clientGetIt.registerLazySingleton<AwaitCardSettlementUseCase>(
      () => AwaitCardSettlementUseCase(clientGetIt<PaymentRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<StartCardCheckoutUseCase>()) {
    clientGetIt.registerLazySingleton<StartCardCheckoutUseCase>(
      () => StartCardCheckoutUseCase(
        getPaymentMethods: clientGetIt<GetPaymentMethodsUseCase>(),
        createCardPaymentSession:
            clientGetIt<CreateCardPaymentSessionUseCase>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<ApplyPromoCodeUseCase>()) {
    clientGetIt.registerLazySingleton<ApplyPromoCodeUseCase>(
      () => ApplyPromoCodeUseCase(clientGetIt<PaymentRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<PaymentCubit>()) {
    clientGetIt.registerFactory<PaymentCubit>(
      () => PaymentCubit(
        getPaymentMethods: clientGetIt<GetPaymentMethodsUseCase>(),
        applyPromoCode: clientGetIt<ApplyPromoCodeUseCase>(),
      ),
    );
  }
}

void _registerPackagesDependencies() {
  if (!clientGetIt.isRegistered<PackagesDatasource>()) {
    clientGetIt.registerLazySingleton<PackagesDatasource>(
      () => SupabasePackagesDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<PackagesRepository>()) {
    clientGetIt.registerLazySingleton<PackagesRepository>(
      () => PackagesRepositoryImpl(clientGetIt<PackagesDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetPackagesUseCase>()) {
    clientGetIt.registerLazySingleton<GetPackagesUseCase>(
      () => GetPackagesUseCase(clientGetIt<PackagesRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<FilterPackagesUseCase>()) {
    clientGetIt.registerLazySingleton<FilterPackagesUseCase>(
      () => const FilterPackagesUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<PackagesCubit>()) {
    clientGetIt.registerFactory<PackagesCubit>(
      () => PackagesCubit(
        getPackages: clientGetIt<GetPackagesUseCase>(),
        filterPackages: clientGetIt<FilterPackagesUseCase>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<GetMySubscriptionUseCase>()) {
    clientGetIt.registerLazySingleton<GetMySubscriptionUseCase>(
      () => GetMySubscriptionUseCase(clientGetIt<PackagesRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<MySubscriptionCubit>()) {
    clientGetIt.registerFactory<MySubscriptionCubit>(
      () => MySubscriptionCubit(clientGetIt<GetMySubscriptionUseCase>()),
    );
  }
}

void _registerTrackingDependencies() {
  if (!clientGetIt.isRegistered<SupabaseTrackingDatasource>()) {
    clientGetIt.registerLazySingleton<SupabaseTrackingDatasource>(
      () => SupabaseTrackingDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<TrackingRepository>()) {
    clientGetIt.registerLazySingleton<TrackingRepository>(
      () => TrackingRepositoryImpl(clientGetIt<SupabaseTrackingDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTrackingTripUseCase>()) {
    clientGetIt.registerLazySingleton<GetTrackingTripUseCase>(
      () => GetTrackingTripUseCase(clientGetIt<TrackingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<WatchVehiclePositionUseCase>()) {
    clientGetIt.registerLazySingleton<WatchVehiclePositionUseCase>(
      () => WatchVehiclePositionUseCase(clientGetIt<TrackingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<WatchTrackingTripUseCase>()) {
    clientGetIt.registerLazySingleton<WatchTrackingTripUseCase>(
      () => WatchTrackingTripUseCase(clientGetIt<TrackingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<TrackingCubit>()) {
    clientGetIt.registerFactory<TrackingCubit>(
      () => TrackingCubit(
        getTrackingTrip: clientGetIt<GetTrackingTripUseCase>(),
        watchVehiclePosition: clientGetIt<WatchVehiclePositionUseCase>(),
        watchTrackingTrip: clientGetIt<WatchTrackingTripUseCase>(),
      ),
    );
  }
}

void _registerSupportDependencies() {
  if (!clientGetIt.isRegistered<SupabaseSupportDatasource>()) {
    clientGetIt.registerLazySingleton<SupabaseSupportDatasource>(
      () => SupabaseSupportDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<SupportRepository>()) {
    clientGetIt.registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(clientGetIt<SupabaseSupportDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetMySupportTicketsUseCase>()) {
    clientGetIt.registerLazySingleton<GetMySupportTicketsUseCase>(
      () => GetMySupportTicketsUseCase(clientGetIt<SupportRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<CreateSupportTicketUseCase>()) {
    clientGetIt.registerLazySingleton<CreateSupportTicketUseCase>(
      () => CreateSupportTicketUseCase(clientGetIt<SupportRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTicketDetailsUseCase>()) {
    clientGetIt.registerLazySingleton<GetTicketDetailsUseCase>(
      () => GetTicketDetailsUseCase(clientGetIt<SupportRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SupportCubit>()) {
    clientGetIt.registerFactory<SupportCubit>(
      () => SupportCubit(
        getMySupportTickets: clientGetIt<GetMySupportTicketsUseCase>(),
        createSupportTicket: clientGetIt<CreateSupportTicketUseCase>(),
        getTicketDetails: clientGetIt<GetTicketDetailsUseCase>(),
        supportRepository: clientGetIt<SupportRepository>(),
      ),
    );
  }
}

void _registerNotificationsDependencies() {
  if (!clientGetIt.isRegistered<SupabaseNotificationsDatasource>()) {
    clientGetIt.registerLazySingleton<SupabaseNotificationsDatasource>(
      () => SupabaseNotificationsDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<NotificationsRepository>()) {
    clientGetIt.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        clientGetIt<SupabaseNotificationsDatasource>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<GetNotificationsUseCase>()) {
    clientGetIt.registerLazySingleton<GetNotificationsUseCase>(
      () => GetNotificationsUseCase(clientGetIt<NotificationsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<WatchNotificationsUseCase>()) {
    clientGetIt.registerLazySingleton<WatchNotificationsUseCase>(
      () => WatchNotificationsUseCase(clientGetIt<NotificationsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<MarkAsReadUseCase>()) {
    clientGetIt.registerLazySingleton<MarkAsReadUseCase>(
      () => MarkAsReadUseCase(clientGetIt<NotificationsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<MarkAllAsReadUseCase>()) {
    clientGetIt.registerLazySingleton<MarkAllAsReadUseCase>(
      () => MarkAllAsReadUseCase(clientGetIt<NotificationsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<WatchUnreadCountUseCase>()) {
    clientGetIt.registerLazySingleton<WatchUnreadCountUseCase>(
      () => WatchUnreadCountUseCase(clientGetIt<NotificationsRepository>()),
    );
  }

  // Singleton badge cubit — always alive, drives the bell badge everywhere.
  if (!clientGetIt.isRegistered<NotificationBadgeCubit>()) {
    clientGetIt.registerLazySingleton<NotificationBadgeCubit>(
      () => NotificationBadgeCubit(clientGetIt<WatchUnreadCountUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<NotificationsCubit>()) {
    clientGetIt.registerFactory<NotificationsCubit>(
      () => NotificationsCubit(
        watchNotifications: clientGetIt<WatchNotificationsUseCase>(),
        markAsRead: clientGetIt<MarkAsReadUseCase>(),
        markAllAsRead: clientGetIt<MarkAllAsReadUseCase>(),
      ),
    );
  }
}

void _registerProfileDependencies() {
  if (!clientGetIt.isRegistered<ProfileDatasource>()) {
    clientGetIt.registerLazySingleton<ProfileDatasource>(
      () => SupabaseProfileDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<ProfileRepository>()) {
    clientGetIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(clientGetIt<ProfileDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetProfileDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetProfileDataUseCase>(
      () => GetProfileDataUseCase(clientGetIt<ProfileRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<UpdateProfileUseCase>()) {
    clientGetIt.registerLazySingleton<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(clientGetIt<ProfileRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<ProfileCubit>()) {
    clientGetIt.registerFactory<ProfileCubit>(
      () => ProfileCubit(
        clientGetIt<GetProfileDataUseCase>(),
        clientGetIt<UpdateProfileUseCase>(),
      ),
    );
  }
}

void _registerRoutesHubDependencies() {
  if (!clientGetIt.isRegistered<SupabaseRoutesHubDatasource>()) {
    clientGetIt.registerLazySingleton<SupabaseRoutesHubDatasource>(
      () => SupabaseRoutesHubDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<RoutesHubRepository>()) {
    clientGetIt.registerLazySingleton<RoutesHubRepository>(
      () => RoutesHubRepositoryImpl(clientGetIt<SupabaseRoutesHubDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetRoutesHubDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetRoutesHubDataUseCase>(
      () => GetRoutesHubDataUseCase(clientGetIt<RoutesHubRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<RoutesHubCubit>()) {
    clientGetIt.registerFactory<RoutesHubCubit>(
      () => RoutesHubCubit(clientGetIt<GetRoutesHubDataUseCase>()),
    );
  }
}

void _registerCommunicationDependencies() {
  if (!clientGetIt.isRegistered<CommunicationDatasource>()) {
    clientGetIt.registerLazySingleton<CommunicationDatasource>(
      () => SupabaseCommunicationDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<CommunicationRepository>()) {
    clientGetIt.registerLazySingleton<CommunicationRepository>(
      () => CommunicationRepositoryImpl(clientGetIt<CommunicationDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetConversationsUseCase>()) {
    clientGetIt.registerLazySingleton<GetConversationsUseCase>(
      () => GetConversationsUseCase(clientGetIt<CommunicationRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetConversationUseCase>()) {
    clientGetIt.registerLazySingleton<GetConversationUseCase>(
      () => GetConversationUseCase(clientGetIt<CommunicationRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SendConversationMessageUseCase>()) {
    clientGetIt.registerLazySingleton<SendConversationMessageUseCase>(
      () => SendConversationMessageUseCase(
        clientGetIt<CommunicationRepository>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<CommunicationCubit>()) {
    clientGetIt.registerFactory<CommunicationCubit>(
      () => CommunicationCubit(clientGetIt<GetConversationsUseCase>()),
    );
  }

  if (!clientGetIt.isRegistered<ChatThreadCubit>()) {
    clientGetIt.registerFactory<ChatThreadCubit>(
      () => ChatThreadCubit(
        getConversation: clientGetIt<GetConversationUseCase>(),
        sendMessage: clientGetIt<SendConversationMessageUseCase>(),
      ),
    );
  }
}

void _registerReferralRewardsDependencies() {
  if (!clientGetIt.isRegistered<SupabaseReferralRewardsDatasource>()) {
    clientGetIt.registerLazySingleton<SupabaseReferralRewardsDatasource>(
      () => SupabaseReferralRewardsDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<ReferralRewardsRepository>()) {
    clientGetIt.registerLazySingleton<ReferralRewardsRepository>(
      () => ReferralRewardsRepositoryImpl(
        clientGetIt<SupabaseReferralRewardsDatasource>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<GetReferralRewardsDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetReferralRewardsDataUseCase>(
      () => GetReferralRewardsDataUseCase(
        clientGetIt<ReferralRewardsRepository>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<InviteContactUseCase>()) {
    clientGetIt.registerLazySingleton<InviteContactUseCase>(
      () => const InviteContactUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<RedeemRewardsUseCase>()) {
    clientGetIt.registerLazySingleton<RedeemRewardsUseCase>(
      () => RedeemRewardsUseCase(clientGetIt<ReferralRewardsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<RevealVoucherUseCase>()) {
    clientGetIt.registerLazySingleton<RevealVoucherUseCase>(
      () => const RevealVoucherUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<ReferralRewardsCubit>()) {
    clientGetIt.registerFactory<ReferralRewardsCubit>(
      () => ReferralRewardsCubit(
        getData: clientGetIt<GetReferralRewardsDataUseCase>(),
        inviteContact: clientGetIt<InviteContactUseCase>(),
        redeemRewards: clientGetIt<RedeemRewardsUseCase>(),
        revealVoucher: clientGetIt<RevealVoucherUseCase>(),
      ),
    );
  }
}

void _registerLoyaltyDependencies() {
  if (!clientGetIt.isRegistered<LoyaltyDatasource>()) {
    clientGetIt.registerLazySingleton<LoyaltyDatasource>(
      () => SupabaseLoyaltyDatasource(Supabase.instance.client),
    );
  }

  if (!clientGetIt.isRegistered<LoyaltyRepository>()) {
    clientGetIt.registerLazySingleton<LoyaltyRepository>(
      () => LoyaltyRepositoryImpl(clientGetIt<LoyaltyDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetLoyaltyDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetLoyaltyDataUseCase>(
      () => GetLoyaltyDataUseCase(clientGetIt<LoyaltyRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<RedeemLoyaltyRewardUseCase>()) {
    clientGetIt.registerLazySingleton<RedeemLoyaltyRewardUseCase>(
      () => RedeemLoyaltyRewardUseCase(clientGetIt<LoyaltyRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<LoyaltyCubit>()) {
    clientGetIt.registerFactory<LoyaltyCubit>(
      () => LoyaltyCubit(
        getData: clientGetIt<GetLoyaltyDataUseCase>(),
        redeemReward: clientGetIt<RedeemLoyaltyRewardUseCase>(),
      ),
    );
  }
}
