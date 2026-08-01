import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_datasource.dart';

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  final SubscriptionsDatasource _datasource;

  const SubscriptionsRepositoryImpl(this._datasource);

  @override
  Future<UserSubscription> cancelSubscription(String id) async {
    try {
      return await _datasource.cancelSubscription(id);
    } catch (_) {
      throw Exception('تعذر إلغاء الاشتراك');
    }
  }

  @override
  Future<UserSubscription> createSubscription(
    UserSubscription subscription,
  ) async {
    try {
      return await _datasource.createSubscription(subscription);
    } catch (_) {
      throw Exception('تعذر إنشاء الاشتراك. تأكد من اكتمال البيانات والسعر');
    }
  }

  @override
  Future<SubscriptionCreationOptions> getCreationOptions() async {
    try {
      return await _datasource.fetchCreationOptions();
    } catch (_) {
      throw Exception('تعذر تحميل بيانات إنشاء الاشتراك');
    }
  }

  @override
  Future<UserSubscription> getSubscriptionDetails(String id) async {
    try {
      return await _datasource.fetchSubscriptionDetails(id);
    } catch (_) {
      throw Exception('تعذر تحميل تفاصيل الاشتراك');
    }
  }

  @override
  Future<List<UserSubscription>> getSubscriptions() async {
    try {
      return await _datasource.fetchSubscriptions();
    } catch (_) {
      throw Exception('تعذر تحميل الاشتراكات');
    }
  }

  @override
  Future<UserSubscription> markRideUsed(String id, {String? tripId}) async {
    try {
      return await _datasource.markRideUsed(id, tripId: tripId);
    } catch (error) {
      // The database refuses a second ride on the same trip (unique index on
      // subscription_ride_usage). Saying so beats a generic failure, because
      // the operator's next move is different: nothing needs doing.
      if (error.toString().contains('ride_already_recorded_for_trip')) {
        throw Exception('تم تسجيل رحلة لهذا المشترك على هذه الرحلة بالفعل');
      }
      throw Exception('تعذر تسجيل رحلة مستخدمة');
    }
  }

  @override
  Future<List<SubscriptionTrip>> getTrips() async {
    try {
      return await _datasource.fetchTrips();
    } catch (_) {
      throw Exception('تعذر تحميل رحلات المكتب');
    }
  }

  @override
  Future<List<SubscriptionRideUsage>> getRideUsage() async {
    try {
      return await _datasource.fetchRideUsage();
    } catch (_) {
      throw Exception('تعذر تحميل سجل الرحلات المستهلكة');
    }
  }

  @override
  Future<UserSubscription> renewSubscription(String id) async {
    try {
      return await _datasource.renewSubscription(id);
    } catch (_) {
      throw Exception('تعذر تجديد الاشتراك');
    }
  }

  @override
  Future<UserSubscription> confirmPayment(String id) async {
    try {
      return await _datasource.confirmPayment(id);
    } catch (_) {
      throw Exception('تعذر تأكيد الدفع');
    }
  }
}
