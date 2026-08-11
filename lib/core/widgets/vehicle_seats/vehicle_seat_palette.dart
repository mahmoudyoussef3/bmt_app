import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/vehicles/seat_view_state.dart';

/// One seat's colours: fill, edge, and the ink that has to stay readable on it.
@immutable
class SeatTones {
  const SeatTones({
    required this.fill,
    required this.border,
    required this.foreground,
  });

  final Color fill;
  final Color border;
  final Color foreground;
}

/// The one seat palette in the EWT ecosystem.
///
/// A seat looks like an EWT seat whichever app draws it, so the tones resolve
/// here from the shared brand tokens rather than from each app's own
/// `ColorScheme`. That is deliberate: routing seat colour through three
/// different themes is exactly how the dashboard's seats drifted from the
/// client's, and this system exists to end that drift.
///
/// The hues carry meaning and are not interchangeable:
/// * **available** — the soft end of the brand blue. An invitation.
/// * **selected** — brand blue at full strength. The only loud tile on the map.
/// * **occupied** — neutral slate. Present, inert, not for sale.
/// * **reserved** — amber. A hold that has not settled and can still lapse.
/// * **disabled** — flat neutral at low contrast. Withdrawn, not broken.
///
/// Colour is never the only cue: every state except `available` also carries a
/// glyph, so the map still reads without colour vision.
@immutable
class VehicleSeatPalette {
  const VehicleSeatPalette({
    required this.available,
    required this.selected,
    required this.occupied,
    required this.reserved,
    required this.disabled,
    required this.cabinFill,
    required this.cabinBorder,
    required this.fixtureFill,
    required this.fixtureBorder,
    required this.fixtureForeground,
    required this.aisle,
    required this.caption,
    required this.shadow,
  });

  final SeatTones available;
  final SeatTones selected;
  final SeatTones occupied;
  final SeatTones reserved;
  final SeatTones disabled;

  /// The cabin floor and the body wall around it.
  final Color cabinFill;
  final Color cabinBorder;

  /// The driver bench and the door — cabin furniture, never bookable, so they
  /// sit apart from the seat states entirely.
  final Color fixtureFill;
  final Color fixtureBorder;
  final Color fixtureForeground;

  /// The walkway channel drawn between seat banks.
  final Color aisle;

  /// FRONT / REAR / PASSENGER AREA markers.
  final Color caption;

  final Color shadow;

  SeatTones tonesFor(SeatViewState state) => switch (state) {
    SeatViewState.available => available,
    SeatViewState.selected => selected,
    SeatViewState.occupied => occupied,
    SeatViewState.reserved => reserved,
    SeatViewState.disabled => disabled,
  };

  /// The palette for the ambient theme.
  static VehicleSeatPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Light mode. `available` is Blue 50 on Blue 200 with Blue 700 ink — the
  /// tones the Client App's seat map has always used, kept exactly, so the
  /// rider's map does not change colour under a refactor.
  static const VehicleSeatPalette light = VehicleSeatPalette(
    available: SeatTones(
      fill: Color(0xFFEFF6FF), 
      border: Color(0xFFBFDBFE), 
      foreground: Color(0xFF1D4ED8), 
    ),
    selected: SeatTones(
      fill: AppLightColors.primary,
      border: AppLightColors.primaryAccent,
      foreground: AppLightColors.onPrimary,
    ),
    occupied: SeatTones(
      fill: AppLightColors.neutralContainer,
      border: AppLightColors.borderStrong,
      foreground: AppLightColors.onSurfaceMuted,
    ),
    reserved: SeatTones(
      fill: AppLightColors.warningContainer,
      border: AppLightColors.warning,
      foreground: AppLightColors.onWarningContainer,
    ),
    
    disabled: SeatTones(
      fill: AppLightColors.surfaceLow,
      border: AppLightColors.border,
      foreground: AppLightColors.onSurfaceFaint,
    ),
    cabinFill: AppLightColors.surfaceLow,
    cabinBorder: AppLightColors.borderStrong,
    fixtureFill: AppLightColors.surfaceHighest,
    fixtureBorder: AppLightColors.border,
    fixtureForeground: AppLightColors.onSurfaceMuted,
    aisle: AppLightColors.border,
    caption: AppLightColors.onSurfaceFaint,
    shadow: AppLightColors.shadow,
  );

  /// Dark mode. The same five meanings, re-toned so brand blue still reads as
  /// the loud state against a slate page.
  static const VehicleSeatPalette dark = VehicleSeatPalette(
    available: SeatTones(
      fill: Color(0xFF172554), 
      border: AppDarkColors.primaryContainer,
      foreground: AppDarkColors.primaryAccent,
    ),
    selected: SeatTones(
      fill: AppDarkColors.primary,
      border: AppDarkColors.primaryAccent,
      foreground: AppDarkColors.onPrimary,
    ),
    occupied: SeatTones(
      fill: AppDarkColors.neutralContainer,
      border: AppDarkColors.borderStrong,
      foreground: AppDarkColors.onSurfaceMuted,
    ),
    reserved: SeatTones(
      fill: AppDarkColors.warningContainer,
      border: AppDarkColors.warningInk,
      foreground: AppDarkColors.onWarningContainer,
    ),
    disabled: SeatTones(
      fill: AppDarkColors.canvas,
      border: AppDarkColors.border,
      foreground: AppDarkColors.onSurfaceFaint,
    ),
    cabinFill: AppDarkColors.surfaceLow,
    cabinBorder: AppDarkColors.borderStrong,
    fixtureFill: AppDarkColors.surfaceRaised,
    fixtureBorder: AppDarkColors.border,
    fixtureForeground: AppDarkColors.onSurfaceMuted,
    aisle: AppDarkColors.border,
    caption: AppDarkColors.onSurfaceFaint,
    shadow: Color(0xFF000000),
  );
}
