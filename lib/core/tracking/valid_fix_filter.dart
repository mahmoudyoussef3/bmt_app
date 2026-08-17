import 'dart:async';

import 'fix_validator.dart';
import 'tracking_config.dart';
import 'vehicle_fix.dart';

/// Drops GPS fixes that are not worth passing on, carrying the last accepted fix
/// as the comparison point.
///
/// [FixValidator] already knows every rule — junk (0,0) and non-finite
/// coordinates, accuracy worse than the configured ceiling, timestamps that do
/// not advance (which is also how a duplicate fix is caught), and displacements
/// implying an impossible ground speed. What it does not do is remember
/// anything, because it is a pure predicate over `(previous, next)`. This is the
/// stateful half.
///
/// It sits **before** the throttle in the publishing pipeline, so the value the
/// throttle is holding to flush is always one that a consumer would accept. The
/// alternative — throttle first, validate second — can spend a whole window
/// holding a fix that then turns out to be junk, and publish nothing at all.
class ValidFixFilter extends StreamTransformerBase<VehicleFix, VehicleFix> {
  ValidFixFilter({
    TrackingConfig config = const TrackingConfig(),
    this.onRejected,
  }) : _validator = FixValidator(config);

  final FixValidator _validator;

  /// Called with the reason each dropped fix was dropped. Useful for surfacing
  /// "your GPS accuracy is too poor to report" rather than going quiet.
  final void Function(FixRejection rejection)? onRejected;

  @override
  Stream<VehicleFix> bind(Stream<VehicleFix> source) {
    // Per-subscription, not per-transformer: binding the same filter twice must
    // not let one stream's history judge the other's fixes.
    VehicleFix? previous;

    return source.where((fix) {
      final rejection = _validator.validate(previous, fix);
      if (rejection != null) {
        onRejected?.call(rejection);
        return false;
      }
      previous = fix;
      return true;
    });
  }
}
