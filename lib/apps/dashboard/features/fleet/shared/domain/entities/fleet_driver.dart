/// Fleet driver entity and status enum.
library;

import 'fleet_common.dart';
import 'fleet_document.dart';

enum FleetDriverStatus {
  active('نشط'),
  suspended('موقوف'),
  archived('مؤرشف');

  final String label;

  const FleetDriverStatus(this.label);
}

class FleetDriver {
  final String id;
  final String employeeCode;
  final String fullName;
  final String phone;
  final String emergencyPhone;
  final String address;
  final String nationalId;
  final String profileImageUrl;
  final String licenseNumber;
  final String licenseExpiryDate;
  final String hireDate;
  final String notes;
  final FleetDriverStatus status;
  final String currentVehicleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<FleetHistoryItem> tripHistory;
  final List<FleetHistoryItem> violations;
  final List<FleetDocument> documents;
  final List<FleetHistoryItem> activityTimeline;

  const FleetDriver({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.phone,
    required this.emergencyPhone,
    required this.address,
    required this.nationalId,
    required this.profileImageUrl,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.hireDate,
    required this.notes,
    required this.status,
    this.currentVehicleId = '',
    this.createdAt,
    this.updatedAt,
    this.tripHistory = const [],
    this.violations = const [],
    this.documents = const [],
    this.activityTimeline = const [],
  });

  // Legacy compatibility getters:
  String get name => fullName;
  String get emergencyContact => emergencyPhone;
  String get licenseExpiry => licenseExpiryDate;
  String get imageLabel => fullName.isNotEmpty ? fullName.substring(0, 1) : '';
  String get avatarInitials => fullName.isNotEmpty ? fullName.substring(0, 1) : '';
  String get currentVehicle => currentVehicleId;
  String get currentRoute => '';

  FleetDriver copyWith({
    String? id,
    String? employeeCode,
    String? fullName,
    String? phone,
    String? emergencyPhone,
    String? address,
    String? nationalId,
    String? profileImageUrl,
    String? licenseNumber,
    String? licenseExpiryDate,
    String? hireDate,
    String? notes,
    FleetDriverStatus? status,
    String? currentVehicleId,
    bool clearCurrentVehicle = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FleetHistoryItem>? tripHistory,
    List<FleetHistoryItem>? violations,
    List<FleetDocument>? documents,
    List<FleetHistoryItem>? activityTimeline,
  }) {
    return FleetDriver(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      hireDate: hireDate ?? this.hireDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      currentVehicleId: clearCurrentVehicle
          ? ''
          : currentVehicleId ?? this.currentVehicleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tripHistory: tripHistory ?? this.tripHistory,
      violations: violations ?? this.violations,
      documents: documents ?? this.documents,
      activityTimeline: activityTimeline ?? this.activityTimeline,
    );
  }
}
