import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/datasources/customers_datasource.dart';
import 'data/datasources/supabase_customers_datasource.dart';
import 'data/repositories/customers_repository_impl.dart';
import 'domain/repositories/customers_repository.dart';
import 'domain/usecases/customers_usecases.dart';
import 'presentation/cubit/customers_cubit.dart';

/// Registers العملاء: datasource → repository → use cases → cubit.
/// Idempotent, matching the rest of `registerDashboardDependencies`.
///
/// [CustomerProfileCubit] is deliberately absent: it takes the client id it
/// serves as a constructor argument, so it is built at the call site rather
/// than resolved from the graph. Registering it would mean either a factory
/// that cannot receive the id or a singleton shared between two customers.
void registerCustomersDependencies(GetIt di) {
  if (!di.isRegistered<CustomersDatasource>()) {
    di.registerLazySingleton<CustomersDatasource>(
      () => SupabaseCustomersDatasource(di<SupabaseClient>()),
    );
  }

  if (!di.isRegistered<CustomersRepository>()) {
    di.registerLazySingleton<CustomersRepository>(
      () => CustomersRepositoryImpl(di<CustomersDatasource>()),
    );
  }

  void useCase<T extends Object>(T Function() create) {
    if (!di.isRegistered<T>()) di.registerLazySingleton<T>(create);
  }

  CustomersRepository repository() => di<CustomersRepository>();

  useCase<GetCustomersOverviewUseCase>(
    () => GetCustomersOverviewUseCase(repository()),
  );
  useCase<GetCustomerDirectoryUseCase>(
    () => GetCustomerDirectoryUseCase(repository()),
  );
  useCase<GetCustomerProfileUseCase>(
    () => GetCustomerProfileUseCase(repository()),
  );
  useCase<GetCustomerTripsUseCase>(() => GetCustomerTripsUseCase(repository()));
  useCase<GetCustomerSubscriptionsUseCase>(
    () => GetCustomerSubscriptionsUseCase(repository()),
  );
  useCase<GetCustomerPaymentsUseCase>(
    () => GetCustomerPaymentsUseCase(repository()),
  );
  useCase<GetCustomerActivityUseCase>(
    () => GetCustomerActivityUseCase(repository()),
  );

  if (!di.isRegistered<CustomersCubit>()) {
    di.registerFactory(
      () => CustomersCubit(
        getOverview: di<GetCustomersOverviewUseCase>(),
        getDirectory: di<GetCustomerDirectoryUseCase>(),
      ),
    );
  }
}
