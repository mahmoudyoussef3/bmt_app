import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _storageKey = 'app_language';

  /// The languages the app actually ships ARB files for. A stored value outside
  /// this set (a stale key, a hand-edited store) falls back to the default
  /// rather than booting into a locale with no translations.
  static const supportedLanguageCodes = <String>{'en', 'ar'};

  final FlutterSecureStorage _storage;
  final String _defaultLanguageCode;

  LocaleCubit({
    FlutterSecureStorage? storage,
    String defaultLanguageCode = 'en',
  }) : _defaultLanguageCode = defaultLanguageCode,
       _storage = storage ?? const FlutterSecureStorage(),
       super(Locale(defaultLanguageCode));

  /// Restores the language the user last chose. Startup must honour that
  /// choice — previously this overwrote it with the default on every launch,
  /// which made the language picker look broken after a restart.
  Future<void> load() async {
    String code = _defaultLanguageCode;
    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored != null && supportedLanguageCodes.contains(stored)) {
        code = stored;
      }
    } catch (_) {
      // Unreadable store — fall through to the default.
    }
    Intl.defaultLocale = code;
    emit(Locale(code));
  }

  Future<void> changeLocale(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode)) return;
    if (languageCode == state.languageCode) return;

    Intl.defaultLocale = languageCode;
    emit(Locale(languageCode));
    try {
      await _storage.write(key: _storageKey, value: languageCode);
    } catch (_) {
      // The switch already applied in-session; it just won't survive a restart.
    }
  }
}
