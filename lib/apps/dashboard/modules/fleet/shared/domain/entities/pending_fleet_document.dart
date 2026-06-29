import 'fleet_document.dart';

/// A document collected in-memory while creating/editing a driver or vehicle,
/// before it is uploaded to storage and persisted.
///
/// The owning entity may not exist yet (no id), so these are queued in the form
/// and uploaded by the screen after the entity is saved and its id is known.
class PendingFleetDocument {
  final FleetDocumentType type;
  final String expiryDate;
  final List<int> bytes;
  final String fileName;

  const PendingFleetDocument({
    required this.type,
    required this.expiryDate,
    required this.bytes,
    required this.fileName,
  });

  PendingFleetDocument copyWith({
    FleetDocumentType? type,
    String? expiryDate,
    List<int>? bytes,
    String? fileName,
  }) {
    return PendingFleetDocument(
      type: type ?? this.type,
      expiryDate: expiryDate ?? this.expiryDate,
      bytes: bytes ?? this.bytes,
      fileName: fileName ?? this.fileName,
    );
  }
}
