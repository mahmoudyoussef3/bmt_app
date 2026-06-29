/// Value object describing a client's request to activate a package
/// subscription. Carries only what the `subscriptions` table needs; the
/// authenticated client id and customer contact are resolved in the data layer.
class SubscriptionRequest {
  const SubscriptionRequest({
    required this.packageId,
    required this.packageName,
    required this.routeName,
    required this.days,
    required this.tripsCount,
    required this.totalPrice,
  });

  final String packageId;
  final String packageName;
  final String routeName;
  final int days;
  final int tripsCount;
  final int totalPrice;
}
