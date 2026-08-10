import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/vehicles/seat_view_state.dart';

/// One seat handed to [VehicleSeatLayout] to draw.
///
/// This is the whole contract between an app and the renderer: an identity, a
/// number to print, a state to colour, and whether the parent will accept a tap
/// on it. Everything else — who booked it, what it costs, whether it may be
/// released — stays outside, which is what keeps one renderer honest across
/// three apps.
///
/// Seats are supplied in **cabin reading order**: the seat at index `i` is
/// drawn in the blueprint slot whose `seatNumber` is `i + 1`. That is the same
/// order `(row, column)`-sorted seat data already arrives in everywhere in this
/// codebase, and [VehicleSeatLayout] spills anything past the blueprint's
/// capacity into its overflow section rather than dropping it.
@immutable
class VehicleSeatData {
  const VehicleSeatData({
    required this.id,
    required this.label,
    required this.state,
    this.enabled = true,
    this.icon,
    this.accent,
    this.tooltip,
  });

  /// Stable identity — a `trip_seats` row id, typically. Used for widget keys
  /// and handed back on tap; never displayed.
  final String id;

  /// The seat number as the rider and the manifest will read it: `'01'`, `'7'`,
  /// `'B3'`. Always supplied by the caller — the renderer never invents one, so
  /// what is drawn is always what is stored.
  final String label;

  final SeatViewState state;

  /// Whether the parent will accept a tap on this seat. The renderer only
  /// reports the tap; it does not decide what is tappable, because that is a
  /// booking rule and booking rules live outside this widget.
  final bool enabled;

  /// Replaces the state's default glyph. For distinguishing shades of one state
  /// that a generic enum cannot carry — a subscription seat and a paid seat are
  /// both [SeatViewState.occupied] to the renderer, but an operator needs to
  /// tell them apart.
  final IconData? icon;

  /// Replaces the state's accent hue, for the same reason as [icon]. The tile's
  /// structure, contrast and legibility come from the state regardless, so an
  /// accent can only re-tint — it cannot make a seat unreadable.
  final Color? accent;

  /// Long-press / hover description. Worth setting wherever the state carries
  /// more meaning than its colour.
  final String? tooltip;

  VehicleSeatData copyWith({
    String? id,
    String? label,
    SeatViewState? state,
    bool? enabled,
    IconData? icon,
    Color? accent,
    String? tooltip,
  }) {
    return VehicleSeatData(
      id: id ?? this.id,
      label: label ?? this.label,
      state: state ?? this.state,
      enabled: enabled ?? this.enabled,
      icon: icon ?? this.icon,
      accent: accent ?? this.accent,
      tooltip: tooltip ?? this.tooltip,
    );
  }
}

/// The words the cabin needs, so the renderer can live in `core/` without
/// reaching for `AppLocalizations`.
///
/// Two of the three apps are Arabic-only and one is bilingual; requiring a
/// localization delegate in `core/` would have made the seat map unusable in a
/// plain widget test and forced new keys on the dashboard for strings it
/// already hardcodes. So the defaults are Arabic, and the Client App passes
/// [VehicleSeatLabels] built from its own `l10n` instead.
@immutable
class VehicleSeatLabels {
  const VehicleSeatLabels({
    this.front = 'مقدمة المركبة',
    this.rear = 'مؤخرة المركبة',
    this.passengerArea = 'منطقة الركاب',
    // Short on purpose: these have to fit inside a seat-sized tile at compact
    // density without ellipsising.
    this.driver = 'سائق',
    this.coDriver = 'مرافق',
    this.door = 'باب',
    this.available = 'متاح',
    this.selected = 'مختار',
    this.occupied = 'محجوز',
    this.reserved = 'قيد الحجز',
    this.disabled = 'غير متاح',
    this.overflow = 'مقاعد إضافية خارج تخطيط المركبة',
  });

  final String front;
  final String rear;
  final String passengerArea;
  final String driver;
  final String coDriver;
  final String door;
  final String available;
  final String selected;
  final String occupied;
  final String reserved;
  final String disabled;
  final String overflow;

  String forState(SeatViewState state) => switch (state) {
    SeatViewState.available => available,
    SeatViewState.selected => selected,
    SeatViewState.occupied => occupied,
    SeatViewState.reserved => reserved,
    SeatViewState.disabled => disabled,
  };
}
