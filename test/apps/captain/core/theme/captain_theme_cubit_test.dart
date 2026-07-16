import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_repository.dart';

void main() {
  late CaptainThemeCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cubit = CaptainThemeCubit(const CaptainThemeRepository());
  });

  tearDown(() => cubit.close());

  test('starts as system before load() resolves', () {
    expect(cubit.state.themeMode, ThemeMode.system);
  });

  test('load() defaults to system when nothing was ever saved', () async {
    await cubit.load();

    expect(cubit.state.themeMode, ThemeMode.system);
    expect(cubit.state.isLoading, isFalse);
  });

  test(
    'setThemeMode() applies immediately and persists across a reload',
    () async {
      await cubit.load();

      await cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, ThemeMode.dark);

      // A fresh cubit reading the same (mocked) SharedPreferences instance
      // should see the persisted choice, not fall back to system.
      final reloaded = CaptainThemeCubit(const CaptainThemeRepository());
      await reloaded.load();
      expect(reloaded.state.themeMode, ThemeMode.dark);
      await reloaded.close();
    },
  );

  test('setThemeMode() to light persists correctly', () async {
    await cubit.setThemeMode(ThemeMode.light);

    final reloaded = CaptainThemeCubit(const CaptainThemeRepository());
    await reloaded.load();
    expect(reloaded.state.themeMode, ThemeMode.light);
    await reloaded.close();
  });
}
