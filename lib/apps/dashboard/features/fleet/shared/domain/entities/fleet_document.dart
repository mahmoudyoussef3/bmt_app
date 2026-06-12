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
  driverLicense('رخصة سائق'),
  nationalIdFront('الرقم القومي (أمام)'),
  nationalIdBack('الرقم القومي (خلف)'),
  criminalRecord('الفيش والتشبيه'),
  employmentContract('عقد العمل'),
  vehicleLicense('رخصة مركبة'),
  insurance('التأمين'),
  inspection('الفحص الفني'),
  other('وثائق أخرى');

  final String label;

  const FleetDocumentType(this.label);
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
