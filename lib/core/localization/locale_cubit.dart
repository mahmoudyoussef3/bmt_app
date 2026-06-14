import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _storageKey = 'app_language';
  final FlutterSecureStorage _storage;

  LocaleCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const Locale('en'));

  Future<void> load() async {
    try {
      final savedCode = await _storage.read(key: _storageKey);
      if (savedCode != null) {
        Intl.defaultLocale = savedCode;
        emit(Locale(savedCode));
      } else {
        Intl.defaultLocale = 'en';
        emit(const Locale('en'));
      }
    } catch (_) {
      Intl.defaultLocale = 'en';
      emit(const Locale('en'));
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
