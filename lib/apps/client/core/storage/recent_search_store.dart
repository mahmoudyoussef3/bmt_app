import 'package:shared_preferences/shared_preferences.dart';

/// Persists a most-recently-used list of picked values per key, so search
/// pickers (pickup, destination, ...) can surface a "Recent" shortcut
/// instead of forcing the user to scroll/retype the same commute every time.
class RecentSearchStore {
  const RecentSearchStore();

  static const _maxEntries = 5;

  Future<List<String>> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const [];
  }

  Future<void> add(String key, String value) async {
    if (value.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(prefs.getStringList(key) ?? const []);
    current.remove(value);
    current.insert(0, value);
    if (current.length > _maxEntries) {
      current.removeRange(_maxEntries, current.length);
    }
    await prefs.setStringList(key, current);
  }
}
