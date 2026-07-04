enum PlanStatus {
  active('نشطة'),
  paused('متوقفة'),
  archived('مؤرشفة');

  final String label;
  const PlanStatus(this.label);

  static PlanStatus fromDb(String? value) => switch (value) {
    'paused' => PlanStatus.paused,
    'archived' => PlanStatus.archived,
    _ => PlanStatus.active,
  };

  String get db => name;
}

/// A transport package, backed by `transport_packages`.
class SubscriptionPlan {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final int days;
  final int tripsCount;
  final int discountPercent;
  final double savingsAmount;
  final String description;
  final PlanStatus status;
  final String packageType;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.days,
    required this.tripsCount,
    required this.discountPercent,
    required this.savingsAmount,
    required this.description,
    required this.status,
    this.packageType = '',
  });

  Map<String, dynamic> toTransportPackage() => {
    'name_ar': title,
    'name_en': subtitle,
    'package_type': packageType.isEmpty
        ? 'custom_${title.hashCode.abs()}'
        : packageType,
    'price': price,
    'duration_days': days,
    'ride_count': tripsCount,
    'active': status == PlanStatus.active,
  };
}
