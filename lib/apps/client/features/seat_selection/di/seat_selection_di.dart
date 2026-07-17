// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/seat_selection/data/datasources/seat_selection_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_selection/data/datasources/supabase_seat_selection_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_selection/data/repositories/seat_selection_repository_impl.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/repositories/seat_selection_repository.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/book_trip_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/confirm_seat_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/get_seat_selection_data_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/release_trip_seat_lock_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/select_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/update_existing_booking_payment_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';

/// Registers the seat_selection feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerSeatSelectionDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SeatSelectionDatasource>()) {
    getIt.registerLazySingleton<SeatSelectionDatasource>(
      () => SupabaseSeatSelectionDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<SeatSelectionRepository>()) {
    getIt.registerLazySingleton<SeatSelectionRepository>(
      () => SeatSelectionRepositoryImpl(getIt<SeatSelectionDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetSeatSelectionDataUseCase>()) {
    getIt.registerLazySingleton<GetSeatSelectionDataUseCase>(
      () => GetSeatSelectionDataUseCase(getIt<SeatSelectionRepository>()),
    );
  }

  if (!getIt.isRegistered<SelectSeatUseCase>()) {
    getIt.registerLazySingleton<SelectSeatUseCase>(
      () => const SelectSeatUseCase(),
    );
  }

  if (!getIt.isRegistered<BookTripSeatUseCase>()) {
    getIt.registerLazySingleton<BookTripSeatUseCase>(
      () => BookTripSeatUseCase(getIt<SeatSelectionRepository>()),
    );
  }

  if (!getIt.isRegistered<LockTripSeatUseCase>()) {
    getIt.registerLazySingleton<LockTripSeatUseCase>(
      () => LockTripSeatUseCase(getIt<SeatSelectionRepository>()),
    );
  }

  if (!getIt.isRegistered<ReleaseTripSeatLockUseCase>()) {
    getIt.registerLazySingleton<ReleaseTripSeatLockUseCase>(
      () => ReleaseTripSeatLockUseCase(getIt<SeatSelectionRepository>()),
    );
  }

  if (!getIt.isRegistered<ConfirmSeatBookingUseCase>()) {
    getIt.registerLazySingleton<ConfirmSeatBookingUseCase>(
      () => ConfirmSeatBookingUseCase(getIt<SeatSelectionRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateExistingBookingPaymentUseCase>()) {
    getIt.registerLazySingleton<UpdateExistingBookingPaymentUseCase>(
      () => UpdateExistingBookingPaymentUseCase(
        getIt<SeatSelectionRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<SeatSelectionCubit>()) {
    getIt.registerFactory<SeatSelectionCubit>(
      () => SeatSelectionCubit(
        getSeatSelectionData: getIt<GetSeatSelectionDataUseCase>(),
        selectSeat: getIt<SelectSeatUseCase>(),
        lockTripSeat: getIt<LockTripSeatUseCase>(),
      ),
    );
  }
}
