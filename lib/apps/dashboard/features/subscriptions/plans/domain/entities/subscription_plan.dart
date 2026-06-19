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

/// A subscription plan, backed by the real `packages` table.
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
  });

  Map<String, dynamic> toInsert() => {
        'title': title,
        'subtitle': subtitle,
        'price': price,
        'days': days,
        'trips_count': tripsCount,
        'discount_percent': discountPercent,
        'savings_amount': savingsAmount,
        'description': description,
        'status': status.db,
      };
}
