import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_theme_repository.dart';

class DashboardThemeState {
  final ThemeMode themeMode;
  final bool isLoading;
  final String? errorMessage;

  const DashboardThemeState({
    required this.themeMode,
    this.isLoading = false,
    this.errorMessage,
  });
}

class DashboardThemeCubit extends Cubit<DashboardThemeState> {
  final DashboardThemeRepository _repository;

  DashboardThemeCubit(this._repository)
    : super(const DashboardThemeState(themeMode: ThemeMode.system));

  Future<void> load() async {
    emit(
      const DashboardThemeState(themeMode: ThemeMode.system, isLoading: true),
    );
    try {
      final mode = await _repository.loadThemeMode();
      emit(DashboardThemeState(themeMode: mode));
    } catch (error) {
      emit(
        DashboardThemeState(
          themeMode: ThemeMode.system,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(DashboardThemeState(themeMode: mode));
    try {
      await _repository.saveThemeMode(mode);
    } catch (error) {
      emit(
        DashboardThemeState(themeMode: mode, errorMessage: error.toString()),
      );
    }
  }
}
