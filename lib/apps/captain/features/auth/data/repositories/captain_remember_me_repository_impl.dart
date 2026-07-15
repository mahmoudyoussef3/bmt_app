import '../../../../core/storage/remember_me_store.dart';
import '../../domain/repositories/captain_remember_me_repository.dart';

class CaptainRememberMeRepositoryImpl implements CaptainRememberMeRepository {
  const CaptainRememberMeRepositoryImpl(this._store);

  final CaptainRememberMeStore _store;

  @override
  Future<void> save(String phone) => _store.save(phone);

  @override
  Future<String?> read() => _store.read();

  @override
  Future<void> clear() => _store.clear();
}
