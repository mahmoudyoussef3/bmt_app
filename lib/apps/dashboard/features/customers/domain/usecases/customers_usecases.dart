import '../entities/customer.dart';
import '../entities/customer_activity.dart';
import '../entities/customer_filters.dart';
import '../entities/customer_payment.dart';
import '../entities/customer_profile.dart';
import '../entities/customer_subscription.dart';
import '../entities/customer_trip.dart';
import '../repositories/customers_repository.dart';

/// One class per read, so a composition-root cubit can pull a single feed
/// without depending on the whole repository — the shape الرئيسية and
/// نظرة تنفيذية already use.

class GetCustomersOverviewUseCase {
  final CustomersRepository _repository;

  const GetCustomersOverviewUseCase(this._repository);

  Future<CustomersOverview> call() => _repository.getOverview();
}

class GetCustomerDirectoryUseCase {
  final CustomersRepository _repository;

  const GetCustomerDirectoryUseCase(this._repository);

  Future<CustomerDirectoryPage> call({
    CustomerFilters filters = const CustomerFilters(),
    int limit = 25,
    int offset = 0,
  }) =>
      _repository.getDirectory(filters: filters, limit: limit, offset: offset);
}

class GetCustomerProfileUseCase {
  final CustomersRepository _repository;

  const GetCustomerProfileUseCase(this._repository);

  Future<CustomerProfile> call(String clientId) =>
      _repository.getProfile(clientId);
}

class GetCustomerTripsUseCase {
  final CustomersRepository _repository;

  const GetCustomerTripsUseCase(this._repository);

  Future<CustomerTripsPage> call(
    String clientId, {
    required bool upcoming,
    int limit = 20,
    int offset = 0,
  }) => _repository.getTrips(
    clientId,
    upcoming: upcoming,
    limit: limit,
    offset: offset,
  );
}

class GetCustomerSubscriptionsUseCase {
  final CustomersRepository _repository;

  const GetCustomerSubscriptionsUseCase(this._repository);

  Future<List<CustomerSubscription>> call(String clientId) =>
      _repository.getSubscriptions(clientId);
}

class GetCustomerPaymentsUseCase {
  final CustomersRepository _repository;

  const GetCustomerPaymentsUseCase(this._repository);

  Future<CustomerPaymentsPage> call(
    String clientId, {
    int limit = 20,
    int offset = 0,
  }) => _repository.getPayments(clientId, limit: limit, offset: offset);
}

class GetCustomerActivityUseCase {
  final CustomersRepository _repository;

  const GetCustomerActivityUseCase(this._repository);

  Future<List<CustomerActivityEvent>> call(String clientId) =>
      _repository.getActivity(clientId);
}
