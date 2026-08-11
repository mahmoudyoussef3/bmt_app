import 'package:bmt_app/core/security/secure_storage.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

/// Call this at app start to register shared auth services used by legacy entrypoints.
void setupLocator() {
  
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
}
