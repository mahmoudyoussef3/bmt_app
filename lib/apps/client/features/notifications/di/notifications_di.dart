// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/notifications/data/datasources/supabase_notifications_datasource.dart';
import 'package:bmt_app/apps/client/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/watch_notifications_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/watch_unread_count_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notification_badge_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';

/// Registers the notifications feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerNotificationsDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseNotificationsDatasource>()) {
    getIt.registerLazySingleton<SupabaseNotificationsDatasource>(
      () => SupabaseNotificationsDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<NotificationsRepository>()) {
    getIt.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        getIt<SupabaseNotificationsDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetNotificationsUseCase>()) {
    getIt.registerLazySingleton<GetNotificationsUseCase>(
      () => GetNotificationsUseCase(getIt<NotificationsRepository>()),
    );
  }

  if (!getIt.isRegistered<WatchNotificationsUseCase>()) {
    getIt.registerLazySingleton<WatchNotificationsUseCase>(
      () => WatchNotificationsUseCase(getIt<NotificationsRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkAsReadUseCase>()) {
    getIt.registerLazySingleton<MarkAsReadUseCase>(
      () => MarkAsReadUseCase(getIt<NotificationsRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkAllAsReadUseCase>()) {
    getIt.registerLazySingleton<MarkAllAsReadUseCase>(
      () => MarkAllAsReadUseCase(getIt<NotificationsRepository>()),
    );
  }

  if (!getIt.isRegistered<WatchUnreadCountUseCase>()) {
    getIt.registerLazySingleton<WatchUnreadCountUseCase>(
      () => WatchUnreadCountUseCase(getIt<NotificationsRepository>()),
    );
  }

  // Singleton badge cubit — always alive, drives the bell badge everywhere.
  if (!getIt.isRegistered<NotificationBadgeCubit>()) {
    getIt.registerLazySingleton<NotificationBadgeCubit>(
      () => NotificationBadgeCubit(getIt<WatchUnreadCountUseCase>()),
    );
  }

  if (!getIt.isRegistered<NotificationsCubit>()) {
    getIt.registerFactory<NotificationsCubit>(
      () => NotificationsCubit(
        watchNotifications: getIt<WatchNotificationsUseCase>(),
        markAsRead: getIt<MarkAsReadUseCase>(),
        markAllAsRead: getIt<MarkAllAsReadUseCase>(),
      ),
    );
  }
}
