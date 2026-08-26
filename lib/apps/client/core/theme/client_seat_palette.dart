import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

import 'client_palette.dart';

/// The shared seat renderer, toned in the rider palette.
///
/// [VehicleSeatPalette] defaults to the operational tones the dashboard and
/// captain apps share — a brighter blue than this app's `--primary`, which left
/// the seat map as the one screen still wearing the old brand. The renderer
/// takes a `palette` for exactly this reason, so the rider app hands it these
/// tones and the other two are untouched.
///
/// The five meanings are unchanged; only the pigment moves:
///
/// | state | reads as |
/// |---|---|
/// | available | quiet, inviting — the page's own `--surface-2` |
/// | selected | the loudest thing on screen — filled `--primary` |
/// | occupied | taken by someone else — neutral, low contrast |
/// | reserved | held, not yours — the `--warning` pair |
/// | disabled | not a seat at all — flat with the cabin floor |
abstract final class ClientSeatPalette {
  const ClientSeatPalette._();

  static VehicleSeatPalette of(BuildContext context) =>
      _from(ClientPalette.of(context));

  static VehicleSeatPalette _from(ClientPalette p) => VehicleSeatPalette(
    // Open seats are the page's own `--surface`, so an empty seat reads as
    // empty. Occupied sits a step down on `--surface-2` with the stronger
    // hairline and muted ink — the pair has to separate at a glance, because
    // "can I sit here" is the only question this map answers.
    available: SeatTones(fill: p.surface, border: p.border, foreground: p.text),
    selected: SeatTones(
      fill: p.primary,
      border: p.primaryStrong,
      foreground: p.onPrimary,
    ),
    // A step *darker* than the cabin floor, not the same `--surface-2` the
    // floor now uses — a taken seat has to be visible as a seat.
    occupied: SeatTones(
      fill: p.border,
      border: p.borderStrong,
      foreground: p.textMuted,
    ),
    reserved: SeatTones(
      fill: p.warningBg,
      border: p.warning,
      foreground: p.warning,
    ),
    disabled: SeatTones(
      fill: p.bg,
      border: p.border,
      foreground: p.textDisabled,
    ),
    // The floor is the muted step so the open seats standing on it are the
    // lightest thing in the cabin.
    cabinFill: p.surface2,
    cabinBorder: p.border,
    fixtureFill: p.bg,
    fixtureBorder: p.border,
    fixtureForeground: p.textMuted,
    aisle: p.border,
    caption: p.textMuted,
    shadow: p.shadow,
  );
}
