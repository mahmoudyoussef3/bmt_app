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
import '../../features/auth/domain/repositories/client_auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import '../../features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../../features/booking/data/datasources/booking_search_datasource.dart';
import '../../features/booking/data/datasources/daily_booking_datasource.dart';
import '../../features/booking/data/datasources/supabase_booking_search_datasource.dart';
import '../../features/booking/data/datasources/supabase_daily_booking_datasource.dart';
import '../../features/booking/data/datasources/supabase_vehicle_booking_datasource.dart';
import '../../features/booking/data/datasources/vehicle_booking_datasource.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/get_available_trips_usecase.dart';
import '../../features/booking/domain/usecases/get_booking_hub_data_usecase.dart';
import '../../features/booking/domain/usecases/get_booking_routes_usecase.dart';
import '../../features/booking/domain/usecases/get_daily_booking_data_usecase.dart';
import '../../features/booking/domain/usecases/get_map_pins_usecase.dart';
import '../../features/booking/domain/usecases/get_popular_routes_usecase.dart';
import '../../features/booking/domain/usecases/get_vehicle_details_usecase.dart';
import '../../features/booking/domain/usecases/get_vehicles_usecase.dart';
import '../../features/booking/domain/usecases/sort_vehicles_usecase.dart';
import '../../features/booking/presentation/cubit/booking_cubit.dart';
import '../../features/communication/data/datasources/supabase_communication_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/usecases/add_conversation_message_usecase.dart';
import '../../features/communication/domain/usecases/get_conversations_usecase.dart';
import '../../features/communication/presentation/cubit/communication_cubit.dart';
import '../../features/home/data/datasources/home_datasource.dart';
import '../../features/home/data/datasources/supabase_home_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data_usecase.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/loyalty/data/datasources/loyalty_datasource.dart';
import '../../features/loyalty/data/datasources/supabase_loyalty_datasource.dart';
import '../../features/loyalty/data/repositories/loyalty_repository_impl.dart';
import '../../features/loyalty/domain/repositories/loyalty_repository.dart';
import '../../features/loyalty/domain/usecases/get_loyalty_data_usecase.dart';
import '../../features/loyalty/domain/usecases/redeem_loyalty_reward_usecase.dart';
import '../../features/loyalty/presentation/cubit/loyalty_cubit.dart';
import '../../features/notifications/data/datasources/mock_notifications_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/payments/data/datasources/payment_datasource.dart';
import '../../features/payments/data/datasources/static_payment_datasource.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/payments/domain/usecases/apply_promo_code_usecase.dart';
import '../../features/payments/domain/usecases/get_payment_methods_usecase.dart';
import '../../features/payments/presentation/cubit/payment_cubit.dart';
import '../../features/packages/data/datasources/packages_datasource.dart';
import '../../features/packages/data/datasources/supabase_packages_datasource.dart';
import '../../features/packages/data/repositories/packages_repository_impl.dart';
import '../../features/packages/domain/repositories/packages_repository.dart';
import '../../features/packages/domain/usecases/calculate_package_pricing_usecase.dart';
import '../../features/packages/domain/usecases/filter_packages_usecase.dart';
import '../../features/packages/domain/usecases/get_package_selection_data_usecase.dart';
import '../../features/packages/presentation/cubit/packages_cubit.dart';
import '../../features/profile/data/datasources/profile_datasource.dart';
import '../../features/profile/data/datasources/supabase_profile_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_data_usecase.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/routes/data/datasources/supabase_routes_hub_datasource.dart';
import '../../features/routes/data/repositories/routes_hub_repository_impl.dart';
import '../../features/routes/domain/repositories/routes_hub_repository.dart';
import '../../features/routes/domain/usecases/get_routes_hub_data_usecase.dart';
import '../../features/routes/presentation/cubit/routes_hub_cubit.dart';
import '../../features/referrals/data/datasources/mock_referral_rewards_datasource.dart';
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
import '../../features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import '../../features/seat_release/data/datasources/mock_seat_release_datasource.dart';
import '../../features/seat_release/data/repositories/seat_release_repository_impl.dart';
import '../../features/seat_release/domain/repositories/seat_release_repository.dart';
import '../../features/seat_release/domain/usecases/get_seat_release_data_usecase.dart';
import '../../features/seat_release/presentation/cubit/seat_release_cubit.dart';
import '../../features/settings/data/datasources/mock_settings_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings_data_usecase.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/support/data/datasources/supabase_support_datasource.dart';
import '../../features/support/data/repositories/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/domain/usecases/create_support_ticket_usecase.dart';
import '../../features/support/domain/usecases/get_support_workspace_usecase.dart';
import '../../features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import '../../features/support/domain/usecases/get_ticket_details_usecase.dart';


import '../../features/support/presentation/cubit/support_cubit.dart';
import '../../features/trips/data/datasources/supabase_trips_datasource.dart';
import '../../features/trips/data/datasources/trips_datasource.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/repositories/trips_repository.dart';
import '../../features/trips/domain/usecases/get_trip_details_usecase.dart';
import '../../features/trips/domain/usecases/get_trips_usecase.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../../features/tracking/data/datasources/mock_tracking_datasource.dart';
import '../../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/domain/usecases/get_tracking_title_usecase.dart';
import '../../features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import '../../features/tracking/presentation/cubit/tracking_cubit.dart';
import '../../../../core/network/network_di.dart';

final GetIt clientGetIt = GetIt.instance;

void registerClientDependencies() {
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
  _registerSettingsDependencies();
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

  if (!clientGetIt.isRegistered<ClientAuthCubit>()) {
    clientGetIt.registerFactory<ClientAuthCubit>(
      () => ClientAuthCubit(
        signInWithEmail: clientGetIt<SignInWithEmailUseCase>(),
        signUpWithEmail: clientGetIt<SignUpWithEmailUseCase>(),
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

  if (!clientGetIt.isRegistered<HomeCubit>()) {
    clientGetIt.registerFactory<HomeCubit>(
      () => HomeCubit(clientGetIt<GetHomeDataUseCase>()),
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

  if (!clientGetIt.isRegistered<TripsCubit>()) {
    clientGetIt.registerFactory<TripsCubit>(
      () => TripsCubit(
        getTrips: clientGetIt<GetTripsUseCase>(),
        getTripDetails: clientGetIt<GetTripDetailsUseCase>(),
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

  if (!clientGetIt.isRegistered<GetBookingHubDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetBookingHubDataUseCase>(
      () => GetBookingHubDataUseCase(clientGetIt<BookingRepository>()),
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

  if (!clientGetIt.isRegistered<GetAvailableTripsUseCase>()) {
    clientGetIt.registerLazySingleton<GetAvailableTripsUseCase>(
      () => GetAvailableTripsUseCase(clientGetIt<BookingRepository>()),
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

  if (!clientGetIt.isRegistered<BookingCubit>()) {
    clientGetIt.registerFactory<BookingCubit>(
      () => BookingCubit(
        getBookingHubData: clientGetIt<GetBookingHubDataUseCase>(),
        getDailyBookingData: clientGetIt<GetDailyBookingDataUseCase>(),
        getRoutes: clientGetIt<GetBookingRoutesUseCase>(),
        getPopularRoutes: clientGetIt<GetPopularRoutesUseCase>(),
        getMapPins: clientGetIt<GetMapPinsUseCase>(),
        getVehicles: clientGetIt<GetVehiclesUseCase>(),
        getVehicleDetails: clientGetIt<GetVehicleDetailsUseCase>(),
        sortVehicles: clientGetIt<SortVehiclesUseCase>(),
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

  if (!clientGetIt.isRegistered<SeatSelectionCubit>()) {
    clientGetIt.registerFactory<SeatSelectionCubit>(
      () => SeatSelectionCubit(
        getSeatSelectionData: clientGetIt<GetSeatSelectionDataUseCase>(),
        selectSeat: clientGetIt<SelectSeatUseCase>(),
      ),
    );
  }
}

void _registerSeatReleaseDependencies() {
  if (!clientGetIt.isRegistered<MockSeatReleaseDatasource>()) {
    clientGetIt.registerLazySingleton<MockSeatReleaseDatasource>(
      () => const MockSeatReleaseDatasource(),
    );
  }

  if (!clientGetIt.isRegistered<SeatReleaseRepository>()) {
    clientGetIt.registerLazySingleton<SeatReleaseRepository>(
      () => SeatReleaseRepositoryImpl(clientGetIt<MockSeatReleaseDatasource>()),
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
      () => const StaticPaymentDatasource(),
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

  if (!clientGetIt.isRegistered<ApplyPromoCodeUseCase>()) {
    clientGetIt.registerLazySingleton<ApplyPromoCodeUseCase>(
      () => const ApplyPromoCodeUseCase(),
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

void _registerSettingsDependencies() {
  if (!clientGetIt.isRegistered<MockSettingsDatasource>()) {
    clientGetIt.registerLazySingleton<MockSettingsDatasource>(
      () => const MockSettingsDatasource(),
    );
  }

  if (!clientGetIt.isRegistered<SettingsRepository>()) {
    clientGetIt.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(clientGetIt<MockSettingsDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetSettingsDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetSettingsDataUseCase>(
      () => GetSettingsDataUseCase(clientGetIt<SettingsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<SettingsCubit>()) {
    clientGetIt.registerFactory<SettingsCubit>(
      () => SettingsCubit(clientGetIt<GetSettingsDataUseCase>()),
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

  if (!clientGetIt.isRegistered<GetPackageSelectionDataUseCase>()) {
    clientGetIt.registerLazySingleton<GetPackageSelectionDataUseCase>(
      () => GetPackageSelectionDataUseCase(clientGetIt<PackagesRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<FilterPackagesUseCase>()) {
    clientGetIt.registerLazySingleton<FilterPackagesUseCase>(
      () => const FilterPackagesUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<CalculatePackagePricingUseCase>()) {
    clientGetIt.registerLazySingleton<CalculatePackagePricingUseCase>(
      () => const CalculatePackagePricingUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<PackagesCubit>()) {
    clientGetIt.registerFactory<PackagesCubit>(
      () => PackagesCubit(
        getSelectionData: clientGetIt<GetPackageSelectionDataUseCase>(),
        filterPackages: clientGetIt<FilterPackagesUseCase>(),
        calculatePricing: clientGetIt<CalculatePackagePricingUseCase>(),
      ),
    );
  }
}

void _registerTrackingDependencies() {
  if (!clientGetIt.isRegistered<MockTrackingDatasource>()) {
    clientGetIt.registerLazySingleton<MockTrackingDatasource>(
      () => const MockTrackingDatasource(),
    );
  }

  if (!clientGetIt.isRegistered<TrackingRepository>()) {
    clientGetIt.registerLazySingleton<TrackingRepository>(
      () => TrackingRepositoryImpl(clientGetIt<MockTrackingDatasource>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTrackingTripUseCase>()) {
    clientGetIt.registerLazySingleton<GetTrackingTripUseCase>(
      () => GetTrackingTripUseCase(clientGetIt<TrackingRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<GetTrackingTitleUseCase>()) {
    clientGetIt.registerLazySingleton<GetTrackingTitleUseCase>(
      () => const GetTrackingTitleUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<TrackingCubit>()) {
    clientGetIt.registerFactory<TrackingCubit>(
      () => TrackingCubit(
        getTrackingTrip: clientGetIt<GetTrackingTripUseCase>(),
        getTrackingTitle: clientGetIt<GetTrackingTitleUseCase>(),
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

  if (!clientGetIt.isRegistered<GetSupportWorkspaceUseCase>()) {
    clientGetIt.registerLazySingleton<GetSupportWorkspaceUseCase>(
      () => GetSupportWorkspaceUseCase(clientGetIt<SupportRepository>()),
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
        getSupportWorkspace: clientGetIt<GetSupportWorkspaceUseCase>(),
        getMySupportTickets: clientGetIt<GetMySupportTicketsUseCase>(),
        createSupportTicket: clientGetIt<CreateSupportTicketUseCase>(),
        getTicketDetails: clientGetIt<GetTicketDetailsUseCase>(),
        supportRepository: clientGetIt<SupportRepository>(),
      ),
    );
  }
}

void _registerNotificationsDependencies() {
  if (!clientGetIt.isRegistered<MockNotificationsDatasource>()) {
    clientGetIt.registerLazySingleton<MockNotificationsDatasource>(
      () => const MockNotificationsDatasource(),
    );
  }

  if (!clientGetIt.isRegistered<NotificationsRepository>()) {
    clientGetIt.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        clientGetIt<MockNotificationsDatasource>(),
      ),
    );
  }

  if (!clientGetIt.isRegistered<GetNotificationsUseCase>()) {
    clientGetIt.registerLazySingleton<GetNotificationsUseCase>(
      () => GetNotificationsUseCase(clientGetIt<NotificationsRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<NotificationsCubit>()) {
    clientGetIt.registerFactory<NotificationsCubit>(
      () => NotificationsCubit(clientGetIt<GetNotificationsUseCase>()),
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

  if (!clientGetIt.isRegistered<ProfileCubit>()) {
    clientGetIt.registerFactory<ProfileCubit>(
      () => ProfileCubit(clientGetIt<GetProfileDataUseCase>()),
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



  if (!clientGetIt.isRegistered<GetConversationsUseCase>()) {
    clientGetIt.registerLazySingleton<GetConversationsUseCase>(
      () => GetConversationsUseCase(clientGetIt<CommunicationRepository>()),
    );
  }

  if (!clientGetIt.isRegistered<AddConversationMessageUseCase>()) {
    clientGetIt.registerLazySingleton<AddConversationMessageUseCase>(
      () => const AddConversationMessageUseCase(),
    );
  }

  if (!clientGetIt.isRegistered<CommunicationCubit>()) {
    clientGetIt.registerFactory<CommunicationCubit>(
      () => CommunicationCubit(
        getConversations: clientGetIt<GetConversationsUseCase>(),
        addMessage: clientGetIt<AddConversationMessageUseCase>(),
      ),
    );
  }
}

void _registerReferralRewardsDependencies() {
  if (!clientGetIt.isRegistered<MockReferralRewardsDatasource>()) {
    clientGetIt.registerLazySingleton<MockReferralRewardsDatasource>(
      () => const MockReferralRewardsDatasource(),
    );
  }

  if (!clientGetIt.isRegistered<ReferralRewardsRepository>()) {
    clientGetIt.registerLazySingleton<ReferralRewardsRepository>(
      () => ReferralRewardsRepositoryImpl(
        clientGetIt<MockReferralRewardsDatasource>(),
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
      () => const RedeemRewardsUseCase(),
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
      () => const RedeemLoyaltyRewardUseCase(),
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
