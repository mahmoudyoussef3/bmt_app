import '../repositories/support_repository.dart';
import '../entities/support_office_option.dart';

class GetSupportOfficeOptionsUseCase {
  final SupportRepository _repository;

  const GetSupportOfficeOptionsUseCase(this._repository);

  Future<List<SupportOfficeOption>> call() {
    return _repository.getOfficeOptions();
  }
}
