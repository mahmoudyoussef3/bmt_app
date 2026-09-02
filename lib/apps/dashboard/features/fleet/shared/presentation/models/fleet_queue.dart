/// إدارة الأسطول' queues — the one axis each tab strip owns, and the record
/// filter that cuts across all of them.
library;

import '../../domain/entities/driver_operations.dart';
import '../../domain/entities/fleet_workspace.dart';

/// The vehicle queues an operator works through.
///
/// Same contract as [CaptainRequestQueueTab] and [TicketQueueTab] elsewhere in
/// the console: a tab is a *predicate over the module's own filters*, never a
/// second copy of the list, and selection is derived rather than stored.
///
/// ## Why this strip owns only the operational axis
///
/// A bus has two independent readings — what it is *doing* (from
/// `operation_trips`) and what state its record is in (`vehicles.status`) — and
/// the two can legitimately disagree: a bus can be marked for maintenance while
/// it is halfway to Alexandria. The strip narrows the first; the «حالة السجل»
/// dropdown behind the filter fold narrows the second. Splitting one axis
/// across both controls is what would let them silently contradict each other.
enum FleetVehicleQueue {
  all('الكل'),
  available('متاحة الآن'),
  assignedToTrip('مُعيّنة لرحلة'),
  onTrip('في رحلة'),

  /// Active but with nobody behind the wheel — a bus that cannot be scheduled.
  withoutDriver('بدون سائق'),

  /// A licence, insurance or inspection date that has lapsed or is about to.
  documents('وثائق تحتاج متابعة');

  const FleetVehicleQueue(this.label);

  final String label;

  /// Queues that represent outstanding work, so the strip can keep them
  /// distinct even while the operator is looking at another tab.
  bool get isWorkQueue =>
      this == FleetVehicleQueue.withoutDriver ||
      this == FleetVehicleQueue.documents;

  bool matches(FleetVehicle vehicle, FleetWorkspace workspace) {
    final operational = workspace.operationalStatusOf(vehicle);
    return switch (this) {
      FleetVehicleQueue.all => true,
      FleetVehicleQueue.available =>
        operational == FleetOperationalStatus.available,
      FleetVehicleQueue.assignedToTrip =>
        operational == FleetOperationalStatus.assigned,
      FleetVehicleQueue.onTrip => operational == FleetOperationalStatus.onTrip,
      FleetVehicleQueue.withoutDriver => vehicle.currentDriverId.isEmpty,
      FleetVehicleQueue.documents =>
        vehicle.hasExpiredDocument || vehicle.hasDocumentExpiringSoon,
    };
  }

  int countIn(List<FleetVehicle> vehicles, FleetWorkspace workspace) =>
      vehicles.where((v) => matches(v, workspace)).length;
}

/// The driver queues, mirroring [FleetVehicleQueue] one tab over so the two
/// halves of الأسطول read as one module.
enum FleetDriverQueue {
  all('الكل'),
  available('متاح الآن'),
  assigned('معيّن لمركبة'),

  /// No active assignment — a driver who cannot be put on a trip as things
  /// stand.
  noVehicle('بدون مركبة'),

  /// A lapsed licence or an incomplete file: the roster's own backlog.
  needsAttention('يحتاج متابعة');

  const FleetDriverQueue(this.label);

  final String label;

  bool get isWorkQueue =>
      this == FleetDriverQueue.needsAttention ||
      this == FleetDriverQueue.noVehicle;

  bool matches(FleetDriver driver, FleetWorkspace workspace) {
    final snapshot = DriverOperations.snapshot(driver, workspace);
    return switch (this) {
      FleetDriverQueue.all => true,
      FleetDriverQueue.available => snapshot.canAssign,
      FleetDriverQueue.assigned =>
        snapshot.status == DriverOperationalStatus.assigned,
      FleetDriverQueue.noVehicle => snapshot.assignedVehicle == null,
      FleetDriverQueue.needsAttention => snapshot.requiresAttention,
    };
  }

  int countIn(List<FleetDriver> drivers, FleetWorkspace workspace) =>
      drivers.where((d) => matches(d, workspace)).length;
}

/// One "open this queue" request handed down from a KPI tile to the tab that
/// answers it.
///
/// Deliberately has no [==]/[hashCode] override, for the same reason
/// [FleetFocusRequest] has none: every request must be a distinct identity even
/// when it names the same queue twice, so a tab detecting it in
/// `didUpdateWidget` reads the second tap on «مركبات جاهزة» as a real change
/// rather than a value-equal no-op that is silently dropped.
class FleetVehicleQueueRequest {
  const FleetVehicleQueueRequest({this.queue, this.recordStatus});

  /// The queue to open, or null to leave the tab's current queue alone — used
  /// when a tile narrows only the record axis.
  final FleetVehicleQueue? queue;

  /// A `vehicles.status` to narrow to at the same time.
  final FleetVehicleStatus? recordStatus;
}

/// [FleetVehicleQueueRequest]'s driver-side twin. Same identity rule.
class FleetDriverQueueRequest {
  const FleetDriverQueueRequest({this.queue, this.recordStatus});

  final FleetDriverQueue? queue;
  final FleetDriverStatus? recordStatus;
}

/// Where one KPI tile sends the operator: which tab, and how that tab should
/// narrow once it gets there.
///
/// Every tile that carries a count must land on rows that add up to it — the
/// rule the whole console follows — so a tile with no queue that reproduces its
/// number exactly (مستندات تنتهي, which spans drivers *and* vehicles) carries
/// no jump at all rather than a near-miss one.
class FleetKpiJump {
  const FleetKpiJump({
    required this.tab,
    this.vehicleQueue,
    this.driverQueue,
    this.vehicleRecordStatus,
  });

  final FleetTab tab;
  final FleetVehicleQueue? vehicleQueue;
  final FleetDriverQueue? driverQueue;
  final FleetVehicleStatus? vehicleRecordStatus;
}
