/// A Dashboard-facing operational alert — the anonymous dashboard's inbound
/// notification. Populated by database triggers whenever an action needs
/// operations attention (new payment to review, captain request, ticket, …).
enum OperationalAlertType {
  paymentReview,
  captainRequest,
  supportTicket,
  refundRequest,
  tripCancelled,
  general;

  static OperationalAlertType fromString(String s) => switch (s) {
    'payment_review' => paymentReview,
    'captain_request' => captainRequest,
    'support_ticket' => supportTicket,
    'refund_request' => refundRequest,
    'trip_cancelled' => tripCancelled,
    _ => general,
  };

  String get label => switch (this) {
    OperationalAlertType.paymentReview => 'مراجعة دفع',
    OperationalAlertType.captainRequest => 'طلب كابتن',
    OperationalAlertType.supportTicket => 'شكوى',
    OperationalAlertType.refundRequest => 'استرداد',
    OperationalAlertType.tripCancelled => 'إلغاء رحلة',
    OperationalAlertType.general => 'عام',
  };
}

enum OperationalAlertPriority {
  low,
  normal,
  high,
  urgent;

  static OperationalAlertPriority fromString(String s) => values.firstWhere(
    (e) => e.name == s,
    orElse: () => OperationalAlertPriority.normal,
  );
}

class OperationalAlert {
  const OperationalAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.priority = OperationalAlertPriority.normal,
    this.actionUrl,
    this.data = const {},
  });

  final String id;
  final OperationalAlertType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final OperationalAlertPriority priority;
  final String? actionUrl;
  final Map<String, dynamic> data;

  OperationalAlert copyWith({bool? isRead}) => OperationalAlert(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    priority: priority,
    actionUrl: actionUrl,
    data: data,
  );
}
