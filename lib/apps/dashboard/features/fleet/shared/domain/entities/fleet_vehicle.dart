/// Fleet vehicle entity, status enum, and seat configuration.
library;

import 'package:bmt_app/core/vehicles/vehicles.dart';

import 'fleet_common.dart';

enum FleetVehicleStatus {
  active('نشطة'),
  maintenance('صيانة'),
  suspended('موقوفة'),
  archived('مؤرشفة');

  final String label;

  const FleetVehicleStatus(this.label);
}

class SeatLayoutItem {
  final String seatNumber;
  final String seatType; // driver, passenger, empty, vip, etc.
  final int row;
  final int column;

  const SeatLayoutItem({
    required this.seatNumber,
    required this.seatType,
    required this.row,
    required this.column,
  });

  Map<String, dynamic> toJson() => {
    'seat_number': seatNumber,
    'seat_type': seatType,
    'row': row,
    'column': column,
  };

  factory SeatLayoutItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['seat_type'] as String? ?? 'passenger';
    final seatType = switch (rawType) {
      'driver' => 'driver',
      'empty' => 'empty',
      _ => 'passenger',
    };
    return SeatLayoutItem(
      seatNumber: json['seat_number']?.toString() ?? '',
      seatType: seatType,
      row: (json['row'] as num?)?.toInt() ?? 0,
      column: (json['column'] as num?)?.toInt() ?? 0,
    );
  }
}

class SeatConfiguration {
  final int rows;
  final int columns;
  final List<SeatLayoutItem> seats;

  const SeatConfiguration({
    required this.rows,
    required this.columns,
    required this.seats,
  });

  Map<String, dynamic> toJson() => {
    'rows': rows,
    'columns': columns,
    'seats': seats.map((s) => s.toJson()).toList(),
  };

  /// Reads a stored `vehicles.seat_configuration`.
  ///
  /// Defensive on purpose: the column defaults to `'{}'`, so a row written by
  /// anything other than this form — a seed script, a backfill, a hand-fixed
  /// row — arrives with no `rows`/`columns` at all. Casting those straight to
  /// `int` threw, and because the fleet workspace is loaded in one pass, a single
  /// such row blanked the entire Fleet screen with a cast error rather than
  /// showing the vehicle as unconfigured.
  factory SeatConfiguration.fromJson(Map<String, dynamic> json) {
    final seats =
        (json['seats'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SeatLayoutItem.fromJson)
            .toList() ??
        const <SeatLayoutItem>[];

    // Fall back to the geometry the seats themselves describe, which is the only
    // honest answer when the stored envelope is missing or disagrees with them.
    final derivedRows = seats.fold<int>(0, (max, s) => s.row > max ? s.row : max);
    final derivedColumns = seats.fold<int>(
      0,
      (max, s) => s.column > max ? s.column : max,
    );

    return SeatConfiguration(
      rows: (json['rows'] as num?)?.toInt() ?? derivedRows,
      columns: (json['columns'] as num?)?.toInt() ?? derivedColumns,
      seats: seats,
    );
  }

  factory SeatConfiguration.empty() {
    return const SeatConfiguration(rows: 0, columns: 0, seats: []);
  }

  /// Builds the seat configuration for a vehicle type that has a predefined
  /// cabin (Hiace, Coaster), or null for a type whose capacity the operator
  /// enters by hand — those still go through [SeatConfiguration.generateDefault].
  ///
  /// The layout comes from `lib/core/vehicles`, the same blueprint the Client
  /// App draws the seat map from, so a vehicle can never be saved with a seat
  /// configuration that disagrees with the map a rider books from.
  static SeatConfiguration? forVehicleType(VehicleType type) {
    final blueprint = VehicleSeatLayouts.blueprintFor(type);
    if (blueprint == null) return null;

    return SeatConfiguration(
      rows: blueprint.rows.length,
      columns: blueprint.columns,
      seats: [
        for (final seat in blueprint.seatDefinitions())
          SeatLayoutItem(
            seatNumber: seat.label,
            seatType: seat.isDriver ? 'driver' : 'passenger',
            row: seat.row,
            column: seat.column,
          ),
      ],
    );
  }

  factory SeatConfiguration.generateDefault(int capacity) {
    final List<SeatLayoutItem> seats = [];
    seats.add(
      const SeatLayoutItem(
        seatNumber: 'D',
        seatType: 'driver',
        row: 1,
        column: 1,
      ),
    );

    int seatNum = 1;
    int curRow = 1;
    if (seatNum <= capacity) {
      seats.add(
        SeatLayoutItem(
          seatNumber: '$seatNum',
          seatType: 'passenger',
          row: 1,
          column: 3,
        ),
      );
      seatNum++;
    }

    curRow = 2;
    while (seatNum <= capacity) {
      for (int col = 1; col <= 3; col++) {
        if (seatNum > capacity) break;
        seats.add(
          SeatLayoutItem(
            seatNumber: '$seatNum',
            seatType: 'passenger',
            row: curRow,
            column: col,
          ),
        );
        seatNum++;
      }
      curRow++;
    }

    return SeatConfiguration(rows: curRow - 1, columns: 3, seats: seats);
  }
}

class FleetVehicle {
  final String id;
  final String vehicleCode;
  final String plateNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final int manufactureYear;
  final String color;
  final int capacity;
  final String seatLayoutType;
  final String imageUrl;
  final String notes;
  final FleetVehicleStatus status;
  final String currentDriverId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SeatConfiguration seatConfiguration;
  final String licenseExpiry;
  final String insuranceExpiry;
  final String inspectionExpiry;
  final List<FleetVehicleImage> images;
  final List<FleetHistoryItem> previousDrivers;
  final List<FleetHistoryItem> tripHistory;
  final List<FleetHistoryItem> timeline;

  const FleetVehicle({
    required this.id,
    required this.vehicleCode,
    required this.plateNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.manufactureYear,
    required this.color,
    required this.capacity,
    required this.seatLayoutType,
    required this.imageUrl,
    required this.notes,
    required this.status,
    this.currentDriverId = '',
    this.createdAt,
    this.updatedAt,
    required this.seatConfiguration,
    required this.licenseExpiry,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    this.images = const [],
    this.previousDrivers = const [],
    this.tripHistory = const [],
    this.timeline = const [],
  });

  // Legacy compatibility getters:
  String get vehicleNumber => vehicleCode;
  int get modelYear => manufactureYear;
  int get seatsCount => capacity;
  String get imageLabel => vehicleCode;
  String get type => vehicleType;

  bool _isExpired(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    return d != null && d.isBefore(DateTime.now());
  }

  bool _isExpiringSoon(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return false;
    final diff = d.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  bool get hasExpiredDocument =>
      _isExpired(licenseExpiry) ||
      _isExpired(insuranceExpiry) ||
      _isExpired(inspectionExpiry);
  bool get hasDocumentExpiringSoon =>
      _isExpiringSoon(licenseExpiry) ||
      _isExpiringSoon(insuranceExpiry) ||
      _isExpiringSoon(inspectionExpiry);

  FleetVehicle copyWith({
    String? id,
    String? vehicleCode,
    String? plateNumber,
    String? vehicleType,
    String? brand,
    String? model,
    int? manufactureYear,
    String? color,
    int? capacity,
    String? seatLayoutType,
    String? imageUrl,
    String? notes,
    FleetVehicleStatus? status,
    String? currentDriverId,
    bool clearCurrentDriver = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SeatConfiguration? seatConfiguration,
    String? licenseExpiry,
    String? insuranceExpiry,
    String? inspectionExpiry,
    List<FleetVehicleImage>? images,
    List<FleetHistoryItem>? previousDrivers,
    List<FleetHistoryItem>? tripHistory,
    List<FleetHistoryItem>? timeline,
  }) {
    return FleetVehicle(
      id: id ?? this.id,
      vehicleCode: vehicleCode ?? this.vehicleCode,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      manufactureYear: manufactureYear ?? this.manufactureYear,
      color: color ?? this.color,
      capacity: capacity ?? this.capacity,
      seatLayoutType: seatLayoutType ?? this.seatLayoutType,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      currentDriverId: clearCurrentDriver
          ? ''
          : currentDriverId ?? this.currentDriverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seatConfiguration: seatConfiguration ?? this.seatConfiguration,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      images: images ?? this.images,
      previousDrivers: previousDrivers ?? this.previousDrivers,
      tripHistory: tripHistory ?? this.tripHistory,
      timeline: timeline ?? this.timeline,
    );
  }
}
