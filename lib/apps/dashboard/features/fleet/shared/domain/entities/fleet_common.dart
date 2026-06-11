/// Common types shared across all fleet modules.

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
      title: json['title'] as String,
      date: json['date'] as String,
      description: json['description'] as String,
    );
  }
}

/// Image metadata for a vehicle.
class FleetVehicleImage {
  final String label;
  final String description;

  const FleetVehicleImage({required this.label, required this.description});
}

/// Tabs for fleet overview navigation.
enum FleetTab {
  drivers('السائقون'),
  vehicles('المركبات'),
  assignments('التعيينات'),
  documents('الوثائق');

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
