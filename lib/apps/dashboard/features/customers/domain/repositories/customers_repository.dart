import '../entities/customer.dart';
import '../entities/customer_activity.dart';
import '../entities/customer_filters.dart';
import '../entities/customer_payment.dart';
import '../entities/customer_profile.dart';
import '../entities/customer_subscription.dart';
import '../entities/customer_trip.dart';

/// The العملاء read surface.
///
/// Every method is a read. The module aggregates data the office already owns
/// and changes none of it: the actions a customer record implies — approving a
/// payment, adjusting a wallet, deciding a refund — already have audited homes
/// in الحجوزات and محفظة العملاء, and a second write path into the same rows
/// would be a second set of guards to keep in step.
abstract class CustomersRepository {
  /// The five headline counts, over the whole base rather than the current page.
  Future<CustomersOverview> getOverview();

  /// One page of the directory. Filtering, sorting and paging all happen
  /// server-side; [CustomerDirectoryPage.total] is what the filter matched, not
  /// what was returned.
  Future<CustomerDirectoryPage> getDirectory({
    required CustomerFilters filters,
    required int limit,
    required int offset,
  });

  /// Identity, counters, the current subscription and preferred routes, in one
  /// round trip — the Customer 360 header and نظرة عامة.
  Future<CustomerProfile> getProfile(String clientId);

  /// [upcoming] false returns السابقة. A cancelled booking is always past.
  Future<CustomerTripsPage> getTrips(
    String clientId, {
    required bool upcoming,
    required int limit,
    required int offset,
  });

  /// Every subscription this customer holds with this office, current first.
  Future<List<CustomerSubscription>> getSubscriptions(String clientId);

  /// A page of payments, plus the wallet position and its recent movements.
  Future<CustomerPaymentsPage> getPayments(
    String clientId, {
    required int limit,
    required int offset,
  });

  /// The chronological feed, newest first.
  Future<List<CustomerActivityEvent>> getActivity(String clientId);
}
