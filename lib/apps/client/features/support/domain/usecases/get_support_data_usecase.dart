import '../entities/support_data.dart';
import '../repositories/support_repository.dart';

class GetSupportDataUseCase {
  const GetSupportDataUseCase(this._repository);

  final SupportRepository _repository;

  Future<SupportData> call() {
    return _repository.getSupportData();
  }
}
