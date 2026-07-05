import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _storageKey = 'app_language';
  final FlutterSecureStorage _storage;
  final String _defaultLanguageCode;

  LocaleCubit({
    FlutterSecureStorage? storage,
    String defaultLanguageCode = 'en',
  }) : _defaultLanguageCode = defaultLanguageCode,
       _storage = storage ?? const FlutterSecureStorage(),
       super(Locale(defaultLanguageCode));

  Future<void> load() async {
    try {
      // Force English as requested
      Intl.defaultLocale = _defaultLanguageCode;
      emit(Locale(_defaultLanguageCode));
      await _storage.write(key: _storageKey, value: _defaultLanguageCode);
    } catch (_) {
      Intl.defaultLocale = _defaultLanguageCode;
      emit(Locale(_defaultLanguageCode));
    }
  }

  Future<void> changeLocale(String languageCode) async {
    final newLocale = Locale(languageCode);
    Intl.defaultLocale = languageCode;
    emit(newLocale);
    try {
      await _storage.write(key: _storageKey, value: languageCode);
    } catch (_) {}
  }
}
