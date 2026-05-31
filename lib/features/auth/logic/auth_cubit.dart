import 'package:flutter/foundation.dart';
import 'package:bmt_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:bmt_app/core/security/secure_storage.dart';

class AuthCubit extends ChangeNotifier {
  final IAuthRepository _repo;
  final SecureStorage _secureStorage;

  String? _token;
  bool get isAuthenticated => _token != null;
  String? get token => _token;

  static const _kTokenKey = 'driver_auth_token';

  AuthCubit(this._repo, this._secureStorage);

  Future<void> tryAutoLogin() async {
    final t = await _secureStorage.read(_kTokenKey);
    if (t != null && await _repo.validateToken(t)) {
      _token = t;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    final t = await _repo.login(username, password);
    _token = t;
    await _secureStorage.write(_kTokenKey, t);
    notifyListeners();
  }

  Future<void> logout() async {
    final t = _token;
    if (t != null) {
      await _repo.logout(t);
    }
    _token = null;
    await _secureStorage.delete(_kTokenKey);
    notifyListeners();
  }
}
