import 'package:bmt_app/core/tracking/fix_validator.dart';
import 'package:bmt_app/core/tracking/latest_value_throttle.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';
import 'package:bmt_app/core/tracking/valid_fix_filter.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../repositories/location_repository.dart';

/// The captain's publishing pipeline, assembled in one place:
///
/// ```
/// GPS stream ─▶ validate ─▶ throttle (trailing, latest wins) ─▶ out
/// ```
///
/// This is domain policy, not plumbing. "Which fixes deserve a database write,
/// and how often" is a business rule about what the platform promises a
/// passenger and what it costs a captain's battery — so it lives here, where it
/// can be read and tested without a device, rather than being spread between a
/// datasource and a cubit.
///
/// Order is deliberate. Validation runs **before** the throttle so the value
/// waiting to be flushed is always publishable; throttling first would let a
/// whole window be spent holding a junk fix that is then discarded, publishing
/// nothing at all for that interval.
class WatchPublishableLocationUseCase {
  WatchPublishableLocationUseCase(
    this._repository, {
    LiveTrackingConfig config = kLiveTrackingConfig,
  }) : _config = config;

  final LocationRepository _repository;
  final LiveTrackingConfig _config;

  /// [onRejected] reports why a fix was dropped, so a captain whose GPS is too
  /// coarse to report can be told that rather than left wondering.
  Stream<VehicleFix> call({void Function(FixRejection)? onRejected}) {
    return _repository
        .watchDevicePosition()
        .transform(ValidFixFilter(onRejected: onRejected))
        .transform(LatestValueThrottle<VehicleFix>(_config.publishInterval));
  }
}
