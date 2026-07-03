import '../../domain/repositories/captain_auth_repository.dart';
import '../datasources/captain_auth_datasource.dart';

class CaptainAuthRepositoryImpl implements CaptainAuthRepository {
  const CaptainAuthRepositoryImpl(this._datasource);

  final CaptainAuthDatasource _datasource;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _datasource.signIn(email: email, password: password);
    if (!await _datasource.isActiveDriver()) {
      await _datasource.signOut();
      throw Exception(
        'هذا الحساب غير مرتبط بسائق نشط. تواصل مع مسؤول التشغيل.',
      );
    }
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}
