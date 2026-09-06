/// Registers the real Cairo faces the landing page renders in.
///
/// `google_fonts` fetches Cairo over HTTP at runtime, which a test cannot do
/// (`allowRuntimeFetching = false`), so without this every landing test runs
/// on whatever fallback face the host offers. That is not a cosmetic
/// difference: **Cairo's line box is 1.874x its size** (typo ascent 1303,
/// descent -571, `USE_TYPO_METRICS` set), far taller than a Latin UI face, and
/// it is what decides the height of every card, tile and phone mockup on the
/// page. A harness on the fallback under-reports the page's vertical rhythm by
/// roughly a third and photographs a layout nobody will ever see — which is
/// exactly how a page-wide line-height regression survived a full pass of
/// visual review.
///
/// The faces live in `test/landing/fonts/`, straight from Google Fonts
/// (`fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900`). They
/// are test fixtures: the app itself still resolves Cairo through
/// `google_fonts`, so nothing here reaches a build.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:google_fonts/google_fonts.dart';

/// `google_fonts` resolves a family per *variant* — `Cairo_700`, `Cairo_900` —
/// and names the bare family only as a fallback, so every weight the page uses
/// has to be registered by name or it silently lands on the fallback face.
const _variants = <String, String>{
  'Cairo': '400',
  'Cairo_regular': '400',
  'Cairo_500': '600',
  'Cairo_600': '600',
  'Cairo_700': '700',
  'Cairo_800': '800',
  'Cairo_900': '900',
};

Future<void> loadLandingFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final entry in _variants.entries) {
    final file = File('test/landing/fonts/Cairo-${entry.value}.ttf');
    if (!file.existsSync()) continue;
    final bytes = ByteData.sublistView(file.readAsBytesSync());
    await (FontLoader(entry.key)..addFont(Future.value(bytes))).load();
  }
}
