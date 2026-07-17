// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/support/data/datasources/supabase_support_datasource.dart';
import 'package:bmt_app/apps/client/features/support/data/repositories/support_repository_impl.dart';
import 'package:bmt_app/apps/client/features/support/domain/repositories/support_repository.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_ticket_details_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';

/// Registers the support feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerSupportDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseSupportDatasource>()) {
    getIt.registerLazySingleton<SupabaseSupportDatasource>(
      () => SupabaseSupportDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<SupportRepository>()) {
    getIt.registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(getIt<SupabaseSupportDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetMySupportTicketsUseCase>()) {
    getIt.registerLazySingleton<GetMySupportTicketsUseCase>(
      () => GetMySupportTicketsUseCase(getIt<SupportRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateSupportTicketUseCase>()) {
    getIt.registerLazySingleton<CreateSupportTicketUseCase>(
      () => CreateSupportTicketUseCase(getIt<SupportRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTicketDetailsUseCase>()) {
    getIt.registerLazySingleton<GetTicketDetailsUseCase>(
      () => GetTicketDetailsUseCase(getIt<SupportRepository>()),
    );
  }

  if (!getIt.isRegistered<SupportCubit>()) {
    getIt.registerFactory<SupportCubit>(
      () => SupportCubit(
        getMySupportTickets: getIt<GetMySupportTicketsUseCase>(),
        createSupportTicket: getIt<CreateSupportTicketUseCase>(),
        getTicketDetails: getIt<GetTicketDetailsUseCase>(),
        supportRepository: getIt<SupportRepository>(),
      ),
    );
  }
}
