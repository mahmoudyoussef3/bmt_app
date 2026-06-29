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
  Future<UserSubscription> markRideUsed(String id) async {
    try {
      return await _datasource.markRideUsed(id);
    } catch (_) {
      throw Exception('تعذر تسجيل رحلة مستخدمة');
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
