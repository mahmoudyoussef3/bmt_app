/// OpenRouteService (ORS) configuration.
///
/// ORS is free and requires only an email signup (no credit card) for an API
/// key with a 2,000 requests/day quota. Create a key at openrouteservice.org,
/// then either:
///   1. paste it into [_orsApiKeyFallback] below, or
///   2. pass it at build/run time: `--dart-define=ORS_API_KEY=your_key`.
///
/// Until a real key is present, [geoEnabled] is false and the routes form
/// falls back to manual entry (no autocomplete / no auto-calculation).
class OrsConfig {
  const OrsConfig._();

  static const String baseUrl = 'https://api.openrouteservice.org';

  /// Bias geocoding toward Egypt (Cairo metro is the primary operating area).
  static const String countryCode = 'EG';

  /// Paste your ORS key here if you don't use --dart-define.
  static const String _orsApiKeyPlaceholder = 'PASTE_ORS_API_KEY_HERE';
  static const String _orsApiKeyFallback =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImQ3YjQ1NmQxNjc1NTRhNDFiODZkNjU1YzBlZjI4M2JmIiwiaCI6Im11cm11cjY0In0=';

  static const String apiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue: _orsApiKeyFallback,
  );

  /// True only when a real key has been supplied.
  static bool get geoEnabled =>
      apiKey.isNotEmpty && apiKey != _orsApiKeyPlaceholder;
}
