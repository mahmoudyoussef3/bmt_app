import 'package:bmt_app/apps/client/core/storage/remember_me_store.dart';

import '../../domain/entities/remembered_credentials.dart';
import '../../domain/repositories/remember_me_repository.dart';

class RememberMeRepositoryImpl implements RememberMeRepository {
  const RememberMeRepositoryImpl(this._store);

  final RememberMeStore _store;

  @override
  Future<void> save({required String email, required String password}) {
    return _store.save(email: email, password: password);
  }

  @override
  Future<RememberedCredentials?> read() async {
    final stored = await _store.read();
    if (stored == null) return null;
    final (email, password) = stored;
    return RememberedCredentials(email: email, password: password);
  }

  @override
  Future<void> clear() => _store.clear();
}
