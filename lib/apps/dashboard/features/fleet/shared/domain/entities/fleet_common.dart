/// Common types shared across all fleet modules.
library;

/// Represents a historical event in a fleet entity's timeline.
class FleetHistoryItem {
  final String title;
  final String date;
  final String description;

  const FleetHistoryItem({
    required this.title,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date,
    'description': description,
  };

  factory FleetHistoryItem.fromJson(Map<String, dynamic> json) {
    return FleetHistoryItem(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Image metadata for a vehicle.
class FleetVehicleImage {
  final String url;
  final String label;
  final String description;

  const FleetVehicleImage({
    required this.url,
    this.label = '',
    this.description = '',
  });
}

/// Tabs for fleet overview navigation.
enum FleetTab {
  drivers('السائقون'),
  vehicles('المركبات');

  final String label;

  const FleetTab(this.label);
}

/// Sort fields for fleet tables.
enum FleetSortField {
  name,
  status,
  licenseExpiry,
  seats,
  modelYear,
  assignedAt,
}

/// A single "open this driver/vehicle" request, e.g. from a "Needs Attention"
/// row.
///
/// Deliberately has no [==]/[hashCode] override, so every request is a
/// distinct identity even when [id] repeats. The drivers/vehicles screens
/// detect a new request by `widget.request != oldWidget.request` in
/// `didUpdateWidget`; with a plain `String? id` prop, asking for the same
/// driver twice in a row (open it, close it, tap the same row again) compares
/// equal to Dart's value-equal strings and the second tap is silently
/// dropped. Wrapping the id in a fresh, identity-only object each time makes
/// every tap — same id or not — a real, detectable change.
class FleetFocusRequest {
  const FleetFocusRequest(this.id);
  final String id;
}
