class DashboardHomeData {
  final List<OperationsActionItem> actionItems;
  final List<TodayTripSummary> todayTrips;
  final List<PaymentReviewItem> paymentReviews;
  final List<ComplaintTicket> openComplaints;
  final List<SubscriptionReviewItem> subscriptions;
  final List<OperationsAlert> alerts;

  const DashboardHomeData({
    required this.actionItems,
    required this.todayTrips,
    required this.paymentReviews,
    required this.openComplaints,
    required this.subscriptions,
    required this.alerts,
  });
}

class OperationsActionItem {
  final String title;
  final String count;
  final String description;
  final String targetModule;
  final OperationsPriority priority;

  const OperationsActionItem({
    required this.title,
    required this.count,
    required this.description,
    required this.targetModule,
    required this.priority,
  });
}

enum OperationsPriority { urgent, high, normal }

class TodayTripSummary {
  final String name;
  final String route;
  final String driver;
  final String vehicle;
  final String departureTime;
  final int capacity;
  final int bookedSeats;
  final String status;

  const TodayTripSummary({
    required this.name,
    required this.route,
    required this.driver,
    required this.vehicle,
    required this.departureTime,
    required this.capacity,
    required this.bookedSeats,
    required this.status,
  });

  int get availableSeats => capacity - bookedSeats;

  double get occupancyRate {
    if (capacity == 0) return 0;
    return bookedSeats / capacity;
  }
}

class PaymentReviewItem {
  final String customerName;
  final String tripName;
  final String method;
  final String amount;
  final String receiptTitle;
  final String receiptMeta;

  const PaymentReviewItem({
    required this.customerName,
    required this.tripName,
    required this.method,
    required this.amount,
    required this.receiptTitle,
    required this.receiptMeta,
  });
}

class ComplaintTicket {
  final String customerName;
  final String type;
  final String tripName;
  final String lastUpdate;
  final String owner;
  final String status;

  const ComplaintTicket({
    required this.customerName,
    required this.type,
    required this.tripName,
    required this.lastUpdate,
    required this.owner,
    required this.status,
  });
}

class SubscriptionReviewItem {
  final String customerName;
  final String packageName;
  final String route;
  final String startDate;
  final String endDate;
  final int remainingTrips;
  final String status;

  const SubscriptionReviewItem({
    required this.customerName,
    required this.packageName,
    required this.route,
    required this.startDate,
    required this.endDate,
    required this.remainingTrips,
    required this.status,
  });
}

class OperationsAlert {
  final String title;
  final String details;
  final String targetModule;
  final OperationsPriority priority;

  const OperationsAlert({
    required this.title,
    required this.details,
    required this.targetModule,
    required this.priority,
  });
}
