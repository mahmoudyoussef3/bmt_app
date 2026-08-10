import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmt_app/core/vehicles/seat_view_state.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_data.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_palette.dart';

/// The one seat tile in the EWT ecosystem.
///
/// Drawn as a seat seen from above — armrests either side, a headrest across
/// the top of the backrest, the number on the cushion — rather than as a
/// rounded card with a digit in it. That shape is the whole point: it is what
/// makes a block of these read as the inside of a vehicle at a glance.
///
/// It knows nothing about trips, bookings or availability rules. It is given a
/// [VehicleSeatData] and reports taps; the parent decides everything else.
class VehicleSeat extends StatelessWidget {
  const VehicleSeat({
    super.key,
    required this.seat,
    required this.size,
    this.palette,
    this.onTap,
  });

  final VehicleSeatData seat;
  final double size;
  final VehicleSeatPalette? palette;

  /// Null when the parent is not accepting taps. A seat with no handler is
  /// still fully drawn — read-only is a presentation mode, not a broken seat.
  final VoidCallback? onTap;

  /// Below this the headrest strip stops being legible and starts being noise,
  /// so compact maps drop it and keep the silhouette.
  static const double _detailThreshold = 34;

  @override
  Widget build(BuildContext context) {
    final tones = (palette ?? VehicleSeatPalette.of(context)).tonesFor(
      seat.state,
    );
    final accent = seat.accent;
    final isSelected = seat.state == SeatViewState.selected;
    // Only `disabled` fades. An occupied seat is real inventory and stays at
    // full strength — fading it would say "not there" when it means "taken".
    final isDimmed = seat.state == SeatViewState.disabled;

    final border = accent ?? tones.border;
    final glyph = seat.icon ?? _glyphFor(seat.state);
    final showDetail = size >= _detailThreshold;

    // Armrests eat into the cushion's width, so the number stays centred on the
    // seat rather than on the tile.
    final armrest = size * 0.12;
    final fontSize = (size * 0.32).clamp(9.0, 18.0);
    final glyphSize = (size * 0.22).clamp(8.0, 15.0);

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      child: Stack(
        children: [
          // Armrests sit behind the cushion so they read as side rails.
          Positioned(
            left: 0,
            top: size * 0.32,
            child: _Armrest(width: armrest, height: size * 0.46, color: border),
          ),
          Positioned(
            right: 0,
            top: size * 0.32,
            child: _Armrest(width: armrest, height: size * 0.46, color: border),
          ),
          Positioned.fill(
            left: armrest * 0.6,
            right: armrest * 0.6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tones.fill,
                // A backrest is rounder than the cushion in front of it. The
                // asymmetry is what gives the tile a front and a back.
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.30),
                  topRight: Radius.circular(size * 0.30),
                  bottomLeft: Radius.circular(size * 0.14),
                  bottomRight: Radius.circular(size * 0.14),
                ),
                border: Border.all(color: border, width: isSelected ? 2 : 1),
              ),
              child: Stack(
                children: [
                  if (showDetail)
                    Positioned(
                      top: size * 0.08,
                      left: size * 0.22,
                      right: size * 0.22,
                      child: Container(
                        height: size * 0.07,
                        decoration: BoxDecoration(
                          color: border.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(size),
                        ),
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: showDetail ? size * 0.10 : 0,
                        bottom: glyph == null ? 0 : size * 0.12,
                      ),
                      child: Text(
                        seat.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tones.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: fontSize.toDouble(),
                          height: 1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  // The second cue. Every state but `available` carries one, so
                  // the map does not depend on telling five fills apart.
                  if (glyph != null)
                    Positioned(
                      bottom: size * 0.07,
                      left: 0,
                      right: 0,
                      child: Icon(
                        glyph,
                        size: glyphSize.toDouble(),
                        color: tones.foreground.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final lifted = isSelected
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.24),
              boxShadow: [
                BoxShadow(
                  color: tones.fill.withValues(alpha: 0.38),
                  blurRadius: size * 0.30,
                  offset: Offset(0, size * 0.10),
                ),
              ],
            ),
            child: tile,
          )
        : tile;

    final body = isDimmed ? Opacity(opacity: 0.85, child: lifted) : lifted;

    final semantic = Semantics(
      button: onTap != null,
      enabled: onTap != null,
      selected: isSelected,
      label: seat.tooltip ?? seat.label,
      child: body,
    );

    if (onTap == null) {
      return seat.tooltip == null
          ? semantic
          : Tooltip(message: seat.tooltip!, child: semantic);
    }

    return Tooltip(
      message: seat.tooltip ?? seat.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size * 0.24),
          child: semantic,
        ),
      ),
    );
  }

  /// The glyph a state carries in addition to its fill.
  ///
  /// `available` deliberately has none: an empty seat should read as empty, and
  /// leaving it bare is what makes the four occupied states pop out of the map.
  static IconData? _glyphFor(SeatViewState state) => switch (state) {
    SeatViewState.available => null,
    SeatViewState.selected => Icons.check_rounded,
    SeatViewState.occupied => Icons.person_rounded,
    SeatViewState.reserved => Icons.schedule_rounded,
    SeatViewState.disabled => Icons.block_rounded,
  };
}

class _Armrest extends StatelessWidget {
  const _Armrest({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

/// What a non-bookable cabin fixture is.
enum VehicleFixtureKind {
  /// The seat with the steering wheel in front of it.
  driver,

  /// The rest of the driver bench — a crew seat, never sold.
  coDriver,

  /// The passenger entrance.
  door,
}

/// The driver bench and the door, drawn as cabin furniture rather than as
/// seats.
///
/// They are visually a different class of object on purpose: flat neutral fill,
/// no armrests, no headrest, no number. A rider scanning the map should never
/// have to work out whether the front-left tile is for sale.
class VehicleSeatFixture extends StatelessWidget {
  const VehicleSeatFixture({
    super.key,
    required this.kind,
    required this.size,
    required this.label,
    this.palette,
  });

  final VehicleFixtureKind kind;
  final double size;
  final String label;
  final VehicleSeatPalette? palette;

  @override
  Widget build(BuildContext context) {
    final colors = palette ?? VehicleSeatPalette.of(context);
    final showLabel = size >= 38;
    final glyphSize = (size * 0.34).clamp(12.0, 26.0);

    return Tooltip(
      message: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.fixtureFill,
          borderRadius: BorderRadius.circular(size * 0.20),
          border: Border.all(color: colors.fixtureBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (kind == VehicleFixtureKind.driver)
              // A steering wheel is the one glyph nobody has to decode. Material
              // has no such icon, so it is painted — twenty lines that remove
              // every "is that a seat or the driver?" question from the map.
              CustomPaint(
                size: Size.square(glyphSize.toDouble()),
                painter: _SteeringWheelPainter(colors.fixtureForeground),
              )
            else
              Icon(
                kind == VehicleFixtureKind.door
                    ? Icons.sensor_door_outlined
                    : Icons.airline_seat_recline_normal_rounded,
                size: glyphSize.toDouble(),
                color: colors.fixtureForeground,
              ),
            if (showLabel) ...[
              SizedBox(height: size * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.06),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (size * 0.19).clamp(8.0, 11.0).toDouble(),
                    fontWeight: FontWeight.w700,
                    color: colors.fixtureForeground,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SteeringWheelPainter extends CustomPainter {
  const _SteeringWheelPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = math.max(1.2, size.width * 0.11);

    final rim = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius - stroke / 2, rim);

    // Hub.
    canvas.drawCircle(center, radius * 0.22, Paint()..color = color);

    // Three spokes: two lateral, one down. The arrangement everyone reads as a
    // steering wheel rather than as a target.
    final spoke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius * 0.2, center.dy),
      Offset(center.dx - radius + stroke, center.dy),
      spoke,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.2, center.dy),
      Offset(center.dx + radius - stroke, center.dy),
      spoke,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + radius * 0.2),
      Offset(center.dx, center.dy + radius - stroke),
      spoke,
    );
  }

  @override
  bool shouldRepaint(_SteeringWheelPainter oldDelegate) =>
      oldDelegate.color != color;
}
