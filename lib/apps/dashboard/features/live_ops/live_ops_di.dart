import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/dashboard_session.dart';
import 'data/datasources/live_ops_datasource.dart';
import 'data/datasources/supabase_live_ops_datasource.dart';
import 'data/repositories/live_ops_repository_impl.dart';
import 'domain/repositories/live_ops_repository.dart';
import 'domain/usecases/live_ops_usecases.dart';
import 'presentation/bloc/fleet_tracking_bloc.dart';
import 'presentation/cubit/live_ops_cubit.dart';

/// Registers the Live Operations Center dependency graph:
/// datasource → repository → use cases → cubit + feed Bloc. Idempotent, matching
/// the rest of `registerDashboardDependencies`.
void registerLiveOpsDependencies(GetIt di) {
  if (!di.isRegistered<LiveOpsDatasource>()) {
    di.registerLazySingleton<LiveOpsDatasource>(
      () => SupabaseLiveOpsDatasource(
        di<SupabaseClient>(),
        di<DashboardSession>(),
      ),
    );
  }

  if (!di.isRegistered<LiveOpsRepository>()) {
    di.registerLazySingleton<LiveOpsRepository>(
      () => LiveOpsRepositoryImpl(di<LiveOpsDatasource>()),
    );
  }

  if (!di.isRegistered<GetLiveOpsSnapshotUseCase>()) {
    di.registerLazySingleton(
      () => GetLiveOpsSnapshotUseCase(di<LiveOpsRepository>()),
    );
  }
  if (!di.isRegistered<WatchLiveOpsUseCase>()) {
    di.registerLazySingleton(
      () => WatchLiveOpsUseCase(di<LiveOpsRepository>()),
    );
  }
  if (!di.isRegistered<UpdateIncidentStatusUseCase>()) {
    di.registerLazySingleton(
      () => UpdateIncidentStatusUseCase(di<LiveOpsRepository>()),
    );
  }
  if (!di.isRegistered<WatchFleetFeedUseCase>()) {
    di.registerLazySingleton(
      () => WatchFleetFeedUseCase(di<LiveOpsRepository>()),
    );
  }
  if (!di.isRegistered<GetLatestFleetFixesUseCase>()) {
    di.registerLazySingleton(
      () => GetLatestFleetFixesUseCase(di<LiveOpsRepository>()),
    );
  }

  if (!di.isRegistered<LiveOpsCubit>()) {
    di.registerFactory(
      () => LiveOpsCubit(
        getSnapshot: di<GetLiveOpsSnapshotUseCase>(),
        watch: di<WatchLiveOpsUseCase>(),
        updateIncident: di<UpdateIncidentStatusUseCase>(),
      ),
    );
  }

  // A factory, like every other state holder here: it owns a realtime
  // subscription and two timers, so each visit to the board must get a fresh one
  // rather than inherit a closed singleton.
  if (!di.isRegistered<FleetTrackingBloc>()) {
    di.registerFactory(
      () => FleetTrackingBloc(
        watchFleetFeed: di<WatchFleetFeedUseCase>(),
        getLatestFixes: di<GetLatestFleetFixesUseCase>(),
      ),
    );
  }
}
