import 'package:get_it/get_it.dart';
import 'dio_factory.dart';
import 'api_service.dart';

void registerNetworkDependencies(GetIt getIt) {
  if (!getIt.isRegistered<ApiService>()) {
    
    getIt.registerLazySingleton(() => DioFactory.getDio());

    getIt.registerLazySingleton(() => ApiService(getIt()));
  }
}
