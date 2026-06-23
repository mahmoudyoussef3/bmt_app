enum AppFlavor {
  client,
  captain,
  dashboard;

  static AppFlavor fromName(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'captain' || 'driver' => AppFlavor.captain,
      'dashboard' || 'admin' || 'ops' => AppFlavor.dashboard,
      _ => AppFlavor.client,
    };
  }
}

class AppFlavorConfig {
  const AppFlavorConfig({
    required this.flavor,
    required this.appName,
    required this.bundleId,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.firebaseOptionsFile,
  });

  final AppFlavor flavor;
  final String appName;
  final String bundleId;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String? firebaseOptionsFile;

  bool get isClient => flavor == AppFlavor.client;
  bool get isCaptain => flavor == AppFlavor.captain;
  bool get isDashboard => flavor == AppFlavor.dashboard;

  String get supabaseRestUrl => '$supabaseUrl/rest/v1';

  static const _defaultSupabaseUrl = 'https://nbwzourpbnmewwklewyr.supabase.co';
  static const _defaultSupabasePublishableKey =
      'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z';

  static AppFlavor? _activeFlavor;

  static void activate(AppFlavor flavor) {
    _activeFlavor = flavor;
  }

  static AppFlavorConfig get current =>
      forFlavor(_activeFlavor ?? AppFlavorEnvironment.current);

  static AppFlavorConfig forFlavor(AppFlavor flavor) {
    final appName = _stringForFlavor(
      flavor: flavor,
      client: 'EasyWay',
      captain: 'EasyWay Captain',
      dashboard: 'BMT Dashboard',
      clientKey: 'CLIENT_APP_NAME',
      captainKey: 'CAPTAIN_APP_NAME',
      dashboardKey: 'DASHBOARD_APP_NAME',
    );

    final bundleId = _stringForFlavor(
      flavor: flavor,
      client: 'com.bmt.client',
      captain: 'com.bmt.captain',
      dashboard: 'com.bmt.dashboard',
      clientKey: 'CLIENT_BUNDLE_ID',
      captainKey: 'CAPTAIN_BUNDLE_ID',
      dashboardKey: 'DASHBOARD_BUNDLE_ID',
    );

    return AppFlavorConfig(
      flavor: flavor,
      appName: appName,
      bundleId: bundleId,
      supabaseUrl: _stringForFlavor(
        flavor: flavor,
        client: _defaultSupabaseUrl,
        captain: _defaultSupabaseUrl,
        dashboard: _defaultSupabaseUrl,
        clientKey: 'CLIENT_SUPABASE_URL',
        captainKey: 'CAPTAIN_SUPABASE_URL',
        dashboardKey: 'DASHBOARD_SUPABASE_URL',
        fallbackKey: 'SUPABASE_URL',
      ),
      supabasePublishableKey: _stringForFlavor(
        flavor: flavor,
        client: _defaultSupabasePublishableKey,
        captain: _defaultSupabasePublishableKey,
        dashboard: _defaultSupabasePublishableKey,
        clientKey: 'CLIENT_SUPABASE_PUBLISHABLE_KEY',
        captainKey: 'CAPTAIN_SUPABASE_PUBLISHABLE_KEY',
        dashboardKey: 'DASHBOARD_SUPABASE_PUBLISHABLE_KEY',
        fallbackKey: 'SUPABASE_PUBLISHABLE_KEY',
      ),
      firebaseOptionsFile: _nullableStringForFlavor(
        flavor: flavor,
        clientKey: 'CLIENT_FIREBASE_OPTIONS',
        captainKey: 'CAPTAIN_FIREBASE_OPTIONS',
        dashboardKey: 'DASHBOARD_FIREBASE_OPTIONS',
      ),
    );
  }

  static String _stringForFlavor({
    required AppFlavor flavor,
    required String client,
    required String captain,
    required String dashboard,
    required String clientKey,
    required String captainKey,
    required String dashboardKey,
    String? fallbackKey,
  }) {
    final value = switch (flavor) {
      AppFlavor.client => _env(clientKey),
      AppFlavor.captain => _env(captainKey),
      AppFlavor.dashboard => _env(dashboardKey),
    };
    if (value.isNotEmpty) return value;

    if (fallbackKey != null) {
      final fallback = _env(fallbackKey);
      if (fallback.isNotEmpty) return fallback;
    }

    return switch (flavor) {
      AppFlavor.client => client,
      AppFlavor.captain => captain,
      AppFlavor.dashboard => dashboard,
    };
  }

  static String? _nullableStringForFlavor({
    required AppFlavor flavor,
    required String clientKey,
    required String captainKey,
    required String dashboardKey,
  }) {
    final value = switch (flavor) {
      AppFlavor.client => _env(clientKey),
      AppFlavor.captain => _env(captainKey),
      AppFlavor.dashboard => _env(dashboardKey),
    };
    return value.isEmpty ? null : value;
  }

  static String _env(String key) {
    return switch (key) {
      'APP_FLAVOR' => const String.fromEnvironment('APP_FLAVOR'),
      'FLUTTER_APP_FLAVOR' => const String.fromEnvironment(
        'FLUTTER_APP_FLAVOR',
      ),
      'SUPABASE_URL' => const String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_PUBLISHABLE_KEY' => const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
      'CLIENT_APP_NAME' => const String.fromEnvironment('CLIENT_APP_NAME'),
      'CAPTAIN_APP_NAME' => const String.fromEnvironment('CAPTAIN_APP_NAME'),
      'DASHBOARD_APP_NAME' => const String.fromEnvironment(
        'DASHBOARD_APP_NAME',
      ),
      'CLIENT_BUNDLE_ID' => const String.fromEnvironment('CLIENT_BUNDLE_ID'),
      'CAPTAIN_BUNDLE_ID' => const String.fromEnvironment('CAPTAIN_BUNDLE_ID'),
      'DASHBOARD_BUNDLE_ID' => const String.fromEnvironment(
        'DASHBOARD_BUNDLE_ID',
      ),
      'CLIENT_SUPABASE_URL' => const String.fromEnvironment(
        'CLIENT_SUPABASE_URL',
      ),
      'CAPTAIN_SUPABASE_URL' => const String.fromEnvironment(
        'CAPTAIN_SUPABASE_URL',
      ),
      'DASHBOARD_SUPABASE_URL' => const String.fromEnvironment(
        'DASHBOARD_SUPABASE_URL',
      ),
      'CLIENT_SUPABASE_PUBLISHABLE_KEY' => const String.fromEnvironment(
        'CLIENT_SUPABASE_PUBLISHABLE_KEY',
      ),
      'CAPTAIN_SUPABASE_PUBLISHABLE_KEY' => const String.fromEnvironment(
        'CAPTAIN_SUPABASE_PUBLISHABLE_KEY',
      ),
      'DASHBOARD_SUPABASE_PUBLISHABLE_KEY' => const String.fromEnvironment(
        'DASHBOARD_SUPABASE_PUBLISHABLE_KEY',
      ),
      'CLIENT_FIREBASE_OPTIONS' => const String.fromEnvironment(
        'CLIENT_FIREBASE_OPTIONS',
      ),
      'CAPTAIN_FIREBASE_OPTIONS' => const String.fromEnvironment(
        'CAPTAIN_FIREBASE_OPTIONS',
      ),
      'DASHBOARD_FIREBASE_OPTIONS' => const String.fromEnvironment(
        'DASHBOARD_FIREBASE_OPTIONS',
      ),
      _ => '',
    };
  }
}

class AppFlavorEnvironment {
  const AppFlavorEnvironment._();

  static AppFlavor get current {
    const flutterFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
    const appFlavor = String.fromEnvironment('APP_FLAVOR');
    final flavorName = flutterFlavor.isNotEmpty ? flutterFlavor : appFlavor;
    return AppFlavor.fromName(flavorName);
  }
}
