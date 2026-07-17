// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/features/communication/data/datasources/supabase_communication_datasource.dart';
import 'package:bmt_app/apps/client/features/communication/data/repositories/communication_repository_impl.dart';
import 'package:bmt_app/apps/client/features/communication/domain/repositories/communication_repository.dart';
import 'package:bmt_app/apps/client/features/communication/domain/usecases/add_conversation_message_usecase.dart';
import 'package:bmt_app/apps/client/features/communication/domain/usecases/get_conversations_usecase.dart';
import 'package:bmt_app/apps/client/features/communication/domain/usecases/send_conversation_message_usecase.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_cubit.dart';

/// Registers the communication feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerCommunicationDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SupabaseCommunicationDatasource>()) {
    getIt.registerLazySingleton<SupabaseCommunicationDatasource>(
      () => SupabaseCommunicationDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<CommunicationRepository>()) {
    getIt.registerLazySingleton<CommunicationRepository>(
      () => CommunicationRepositoryImpl(
        getIt<SupabaseCommunicationDatasource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetConversationsUseCase>()) {
    getIt.registerLazySingleton<GetConversationsUseCase>(
      () => GetConversationsUseCase(getIt<CommunicationRepository>()),
    );
  }

  if (!getIt.isRegistered<AddConversationMessageUseCase>()) {
    getIt.registerLazySingleton<AddConversationMessageUseCase>(
      () => const AddConversationMessageUseCase(),
    );
  }

  if (!getIt.isRegistered<SendConversationMessageUseCase>()) {
    getIt.registerLazySingleton<SendConversationMessageUseCase>(
      () => SendConversationMessageUseCase(
        getIt<CommunicationRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<CommunicationCubit>()) {
    getIt.registerFactory<CommunicationCubit>(
      () => CommunicationCubit(
        getConversations: getIt<GetConversationsUseCase>(),
        addMessage: getIt<AddConversationMessageUseCase>(),
        sendMessage: getIt<SendConversationMessageUseCase>(),
      ),
    );
  }
}
