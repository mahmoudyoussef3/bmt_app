import 'package:get_it/get_it.dart';
import 'dio_factory.dart';
import 'api_service.dart';

void registerNetworkDependencies(GetIt getIt) {
  if (!getIt.isRegistered<ApiService>()) {
    // 1. Register Dio instance
    getIt.registerLazySingleton(() => DioFactory.getDio());

    // 2. Register ApiService using the registered Dio instance
    getIt.registerLazySingleton(() => ApiService(getIt()));
  }
}
