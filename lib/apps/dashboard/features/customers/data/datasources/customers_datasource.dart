import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_activity.dart';
import '../../domain/entities/customer_filters.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/customer_subscription.dart';
import '../../domain/entities/customer_trip.dart';

/// What the العملاء module needs from a backend, stated without one — so a test
/// can satisfy it with a fake and the repository never learns what Supabase is.
abstract class CustomersDatasource {
  Future<CustomersOverview> fetchOverview();

  Future<CustomerDirectoryPage> fetchDirectory({
    required CustomerFilters filters,
    required int limit,
    required int offset,
  });

  Future<CustomerProfile> fetchProfile(String clientId);

  Future<CustomerTripsPage> fetchTrips(
    String clientId, {
    required bool upcoming,
    required int limit,
    required int offset,
  });

  Future<List<CustomerSubscription>> fetchSubscriptions(String clientId);

  Future<CustomerPaymentsPage> fetchPayments(
    String clientId, {
    required int limit,
    required int offset,
  });

  Future<List<CustomerActivityEvent>> fetchActivity(String clientId);
}
