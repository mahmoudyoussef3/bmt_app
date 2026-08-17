/// Fleet document entity and related enums.
library;

enum FleetDocumentStatus {
  expired('منتهي'),
  expiringSoon('ينتهي قريباً'),
  valid('سليم');

  final String label;

  const FleetDocumentStatus(this.label);
}

enum FleetDocumentType {
  driverLicense('رخصة سائق', 'driver_license'),
  nationalIdFront('الرقم القومي (أمام)', 'national_id_front'),
  nationalIdBack('الرقم القومي (خلف)', 'national_id_back'),
  criminalRecord('الفيش والتشبيه', 'criminal_record'),
  employmentContract('عقد العمل', 'employment_contract'),
  vehicleLicense('رخصة مركبة', 'vehicle_license'),
  insurance('التأمين', 'insurance'),
  inspection('الفحص الفني', 'inspection'),
  other('وثائق أخرى', 'other');

  /// What an operator reads.
  final String label;

  /// What everything outside Dart calls this type — the `type` column and the
  /// storage folder both use it.
  ///
  /// Part of the domain vocabulary rather than a data-layer mapping because the
  /// upload forms compose the storage path themselves; when the mapping lived in
  /// `data/models/`, two presentation files reached across the layer boundary to
  /// import it, and a third copy of the same switch was one edit away.
  final String wireName;

  const FleetDocumentType(this.label, this.wireName);
}

class FleetDocument {
  final String id;
  final FleetDocumentType type;
  final String ownerId;
  final String ownerName;
  final String referenceNumber;
  final String expiryDate;
  final FleetDocumentStatus status;
  final String fileUrl;

  const FleetDocument({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.referenceNumber,
    required this.expiryDate,
    required this.status,
    this.fileUrl = '',
  });

  factory FleetDocument.empty() {
    return const FleetDocument(
      id: '',
      type: FleetDocumentType.other,
      ownerId: '',
      ownerName: '',
      referenceNumber: '',
      expiryDate: '',
      status: FleetDocumentStatus.valid,
      fileUrl: '',
    );
  }
}
