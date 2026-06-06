import 'package:get_it/get_it.dart';

import '../../features/dashboard_home/data/datasources/mock_dashboard_home_datasource.dart';
import '../../features/dashboard_home/data/repositories/dashboard_home_repository_impl.dart';
import '../../features/dashboard_home/domain/repositories/dashboard_home_repository.dart';
import '../../features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../theme/dashboard_theme_cubit.dart';
import '../theme/dashboard_theme_repository.dart';

final GetIt dashboardDi = GetIt.instance;

void registerDashboardDependencies() {
  if (!dashboardDi.isRegistered<DashboardThemeRepository>()) {
    dashboardDi.registerLazySingleton<DashboardThemeRepository>(
      DashboardThemeRepository.new,
    );
  }

  if (!dashboardDi.isRegistered<DashboardThemeCubit>()) {
    dashboardDi.registerFactory(
      () => DashboardThemeCubit(dashboardDi<DashboardThemeRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DashboardHomeDatasource>()) {
    dashboardDi.registerLazySingleton<DashboardHomeDatasource>(
      MockDashboardHomeDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<DashboardHomeRepository>()) {
    dashboardDi.registerLazySingleton<DashboardHomeRepository>(
      () => DashboardHomeRepositoryImpl(dashboardDi<DashboardHomeDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetDashboardHomeUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetDashboardHomeUseCase(dashboardDi<DashboardHomeRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DashboardHomeCubit>()) {
    dashboardDi.registerFactory(
      () => DashboardHomeCubit(dashboardDi<GetDashboardHomeUseCase>()),
    );
  }
}
