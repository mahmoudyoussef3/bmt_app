import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_activity.dart';
import '../../domain/entities/customer_filters.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/customer_subscription.dart';
import '../../domain/entities/customer_trip.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_datasource.dart';

/// Names each failure for the operator and keeps the datasource's reason.
///
/// The reason is appended rather than replaced, as everywhere else in the
/// console: the RPCs raise specific, actionable codes (`not_authorized` means
/// "wrong office", not "server down") and an operator who only sees
/// "تعذر تحميل ملف العميل" has nothing to act on.
///
/// There is no mapping step. The datasource already returns domain entities
/// because the RPCs return one document per surface rather than raw table rows,
/// and a second DTO layer over a shape that is already the screen's shape would
/// be ceremony — the same position `WalletRepositoryImpl` records.
class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersDatasource _datasource;

  const CustomersRepositoryImpl(this._datasource);

  @override
  Future<CustomersOverview> getOverview() async {
    try {
      return await _datasource.fetchOverview();
    } catch (error) {
      throw Exception('تعذر تحميل ملخص العملاء: ${_reason(error)}');
    }
  }

  @override
  Future<CustomerDirectoryPage> getDirectory({
    required CustomerFilters filters,
    required int limit,
    required int offset,
  }) async {
    try {
      return await _datasource.fetchDirectory(
        filters: filters,
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      throw Exception('تعذر تحميل قائمة العملاء: ${_reason(error)}');
    }
  }

  @override
  Future<CustomerProfile> getProfile(String clientId) async {
    try {
      return await _datasource.fetchProfile(clientId);
    } catch (error) {
      throw Exception('تعذر تحميل ملف العميل: ${_reason(error)}');
    }
  }

  @override
  Future<CustomerTripsPage> getTrips(
    String clientId, {
    required bool upcoming,
    required int limit,
    required int offset,
  }) async {
    try {
      return await _datasource.fetchTrips(
        clientId,
        upcoming: upcoming,
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      throw Exception('تعذر تحميل رحلات العميل: ${_reason(error)}');
    }
  }

  @override
  Future<List<CustomerSubscription>> getSubscriptions(String clientId) async {
    try {
      return await _datasource.fetchSubscriptions(clientId);
    } catch (error) {
      throw Exception('تعذر تحميل اشتراكات العميل: ${_reason(error)}');
    }
  }

  @override
  Future<CustomerPaymentsPage> getPayments(
    String clientId, {
    required int limit,
    required int offset,
  }) async {
    try {
      return await _datasource.fetchPayments(
        clientId,
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      throw Exception('تعذر تحميل مدفوعات العميل: ${_reason(error)}');
    }
  }

  @override
  Future<List<CustomerActivityEvent>> getActivity(String clientId) async {
    try {
      return await _datasource.fetchActivity(clientId);
    } catch (error) {
      throw Exception('تعذر تحميل نشاط العميل: ${_reason(error)}');
    }
  }

  String _reason(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
