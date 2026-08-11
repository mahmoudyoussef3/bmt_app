import 'package:shared_preferences/shared_preferences.dart';

class CaptainRememberMeStore {
  const CaptainRememberMeStore();

  static const _phoneKey = 'captain_remember_me_phone';

  Future<void> save(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
  }
}
