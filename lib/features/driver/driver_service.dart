import 'package:bmt_app/features/driver/logic/driver_cubit.dart';
import 'package:bmt_app/features/driver/domain/repositories/driver_repository_interface.dart';
import 'package:bmt_app/core/di/di.dart' as di;

class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;
  DriverService._internal() {
    // Prefer cubit from DI if available, otherwise fall back to a mock repo
    if (di.getIt.isRegistered<DriverCubit>()) {
      cubit = di.getIt<DriverCubit>();
    } else {
      cubit = DriverCubit(di.getIt<IDriverRepository>());
    }
  }

  late final DriverCubit cubit;

  static DriverCubit get cubitInstance => _instance.cubit;
}
