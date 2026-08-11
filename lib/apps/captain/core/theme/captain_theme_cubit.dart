import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'captain_theme_repository.dart';

class CaptainThemeState {
  const CaptainThemeState({required this.themeMode, this.isLoading = false});

  final ThemeMode themeMode;
  final bool isLoading;
}

class CaptainThemeCubit extends Cubit<CaptainThemeState> {
  CaptainThemeCubit(this._repository)
    : super(const CaptainThemeState(themeMode: ThemeMode.system));

  final CaptainThemeRepository _repository;

  Future<void> load() async {
    emit(const CaptainThemeState(themeMode: ThemeMode.system, isLoading: true));
    try {
      final mode = await _repository.loadThemeMode();
      emit(CaptainThemeState(themeMode: mode));
    } catch (_) {
      emit(const CaptainThemeState(themeMode: ThemeMode.system));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(CaptainThemeState(themeMode: mode));
    try {
      await _repository.saveThemeMode(mode);
    } catch (_) {}
  }
}
