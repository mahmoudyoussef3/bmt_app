import '../../domain/entities/user_subscription.dart';
import '../models/user_subscription_model.dart';

abstract class SubscriptionsDatasource {
  Future<List<UserSubscription>> fetchSubscriptions();

  Future<UserSubscription> fetchSubscriptionDetails(String id);

  Future<UserSubscription> createSubscription(UserSubscription subscription);

  Future<UserSubscription> cancelSubscription(String id);

  Future<UserSubscription> renewSubscription(String id);

  Future<UserSubscription> markRideUsed(String id);

  Future<SubscriptionCreationOptions> fetchCreationOptions();
}

class MockSubscriptionsDatasource implements SubscriptionsDatasource {
  final List<UserSubscription> _subscriptions = [
    UserSubscriptionModel(
      id: 'sub-1001',
      userId: 'usr-1001',
      userName: 'أحمد محمد',
      userPhone: '01012345678',
      tripId: 'trip-2201',
      routeId: 'route-banha-tagamoa',
      routeName: 'بنها → التجمع الخامس',
      fromPointId: 'banha',
      fromPointName: 'بنها',
      toPointId: 'ramses',
      toPointName: 'رمسيس',
      type: SubscriptionType.fiveDays,
      price: 280,
      currency: 'ج.م',
      totalRides: 5,
      usedRides: 2,
      remainingRides: 3,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 5),
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 5, 31, 11, 10),
      updatedAt: DateTime(2026, 6, 3, 8, 20),
    ),
    UserSubscriptionModel(
      id: 'sub-1002',
      userId: 'usr-1002',
      userName: 'منة خالد',
      userPhone: '01099887766',
      tripId: 'trip-2202',
      routeId: 'route-mansoura-newcairo',
      routeName: 'المنصورة → القاهرة الجديدة',
      fromPointId: 'mansoura',
      fromPointName: 'المنصورة',
      toPointId: 'rehab',
      toPointName: 'الرحاب',
      type: SubscriptionType.monthly,
      price: 1650,
      currency: 'ج.م',
      totalRides: 22,
      usedRides: 7,
      remainingRides: 15,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      status: SubscriptionStatus.pendingPayment,
      createdAt: DateTime(2026, 6, 1, 10),
      updatedAt: DateTime(2026, 6, 1, 10),
    ),
    UserSubscriptionModel(
      id: 'sub-1003',
      userId: 'usr-1003',
      userName: 'كريم عادل',
      userPhone: '01122334455',
      tripId: 'trip-2203',
      routeId: 'route-nasr-smart',
      routeName: 'مدينة نصر → القرية الذكية',
      fromPointId: 'abbas',
      fromPointName: 'عباس العقاد',
      toPointId: 'smart-village',
      toPointName: 'القرية الذكية',
      type: SubscriptionType.threeMonths,
      price: 4300,
      currency: 'ج.م',
      totalRides: 66,
      usedRides: 66,
      remainingRides: 0,
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 5, 31),
      status: SubscriptionStatus.expired,
      createdAt: DateTime(2026, 2, 28, 12, 30),
      updatedAt: DateTime(2026, 5, 31, 23, 59),
    ),
    UserSubscriptionModel(
      id: 'sub-1004',
      userId: 'usr-1004',
      userName: 'سارة ياسر',
      userPhone: '01255667788',
      tripId: 'trip-2204',
      routeId: 'route-maadi-capital',
      routeName: 'المعادي → العاصمة الإدارية',
      fromPointId: 'maadi',
      fromPointName: 'المعادي',
      toPointId: 'tagamoa-third',
      toPointName: 'التجمع الثالث',
      type: SubscriptionType.tenDaysMonthly,
      price: 820,
      currency: 'ج.م',
      totalRides: 10,
      usedRides: 1,
      remainingRides: 9,
      startDate: DateTime(2026, 6, 4),
      endDate: DateTime(2026, 6, 30),
      status: SubscriptionStatus.cancelled,
      createdAt: DateTime(2026, 6, 3, 14, 45),
      updatedAt: DateTime(2026, 6, 5, 9, 15),
    ),
    UserSubscriptionModel(
      id: 'sub-1005',
      userId: 'usr-1005',
      userName: 'نهى جمال',
      userPhone: '01044556677',
      tripId: 'trip-2205',
      routeId: 'route-shorouk-tagamoa',
      routeName: 'الشروق → التجمع الخامس',
      fromPointId: 'shorouk',
      fromPointName: 'الشروق',
      toPointId: 'festival',
      toPointName: 'كايرو فيستيفال',
      type: SubscriptionType.oneTime,
      price: 95,
      currency: 'ج.م',
      totalRides: 1,
      usedRides: 0,
      remainingRides: 1,
      startDate: DateTime(2026, 6, 9),
      endDate: DateTime(2026, 6, 9),
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 6, 8, 17, 35),
      updatedAt: DateTime(2026, 6, 8, 17, 35),
    ),
  ];

  static const _users = [
    SubscriptionUserOption(
      id: 'usr-1001',
      name: 'أحمد محمد',
      phone: '01012345678',
    ),
    SubscriptionUserOption(
      id: 'usr-1002',
      name: 'منة خالد',
      phone: '01099887766',
    ),
    SubscriptionUserOption(
      id: 'usr-1006',
      name: 'داليا شوقي',
      phone: '01177889900',
    ),
    SubscriptionUserOption(
      id: 'usr-1007',
      name: 'خالد محمود',
      phone: '01233445566',
    ),
  ];

  static const _trips = [
    SubscriptionTripOption(
      id: 'trip-2201',
      routeId: 'route-banha-tagamoa',
      routeName: 'بنها → التجمع الخامس',
      points: [
        SubscriptionPointOption(id: 'banha', name: 'بنها', order: 1),
        SubscriptionPointOption(id: 'shobra', name: 'شبرا', order: 2),
        SubscriptionPointOption(id: 'ramses', name: 'رمسيس', order: 3),
        SubscriptionPointOption(id: 'tagamoa', name: 'التجمع الخامس', order: 4),
      ],
      pricing: [
        SubscriptionPricingOption(
          fromPointId: 'banha',
          toPointId: 'ramses',
          type: SubscriptionType.oneTime,
          price: 70,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'banha',
          toPointId: 'ramses',
          type: SubscriptionType.fiveDays,
          price: 280,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'banha',
          toPointId: 'ramses',
          type: SubscriptionType.tenDaysMonthly,
          price: 540,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'banha',
          toPointId: 'ramses',
          type: SubscriptionType.monthly,
          price: 1150,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'banha',
          toPointId: 'ramses',
          type: SubscriptionType.threeMonths,
          price: 3100,
          currency: 'ج.م',
        ),
      ],
    ),
    SubscriptionTripOption(
      id: 'trip-2204',
      routeId: 'route-maadi-capital',
      routeName: 'المعادي → العاصمة الإدارية',
      points: [
        SubscriptionPointOption(id: 'maadi', name: 'المعادي', order: 1),
        SubscriptionPointOption(id: 'zahraa', name: 'زهراء المعادي', order: 2),
        SubscriptionPointOption(
          id: 'tagamoa-third',
          name: 'التجمع الثالث',
          order: 3,
        ),
        SubscriptionPointOption(
          id: 'capital',
          name: 'العاصمة الإدارية',
          order: 4,
        ),
      ],
      pricing: [
        SubscriptionPricingOption(
          fromPointId: 'maadi',
          toPointId: 'tagamoa-third',
          type: SubscriptionType.oneTime,
          price: 90,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'maadi',
          toPointId: 'tagamoa-third',
          type: SubscriptionType.fiveDays,
          price: 360,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'maadi',
          toPointId: 'tagamoa-third',
          type: SubscriptionType.tenDaysMonthly,
          price: 820,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'maadi',
          toPointId: 'tagamoa-third',
          type: SubscriptionType.monthly,
          price: 1550,
          currency: 'ج.م',
        ),
        SubscriptionPricingOption(
          fromPointId: 'maadi',
          toPointId: 'tagamoa-third',
          type: SubscriptionType.threeMonths,
          price: 4200,
          currency: 'ج.م',
        ),
      ],
    ),
  ];

  @override
  Future<List<UserSubscription>> fetchSubscriptions() async {
    return List.unmodifiable(_subscriptions);
  }

  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) async {
    return _find(id);
  }

  @override
  Future<UserSubscription> createSubscription(
    UserSubscription subscription,
  ) async {
    final model = UserSubscriptionModel.fromEntity(subscription);
    _subscriptions.insert(0, model);
    return model;
  }

  @override
  Future<UserSubscription> cancelSubscription(String id) async {
    final subscription = _find(id);
    final updated = UserSubscriptionModel.fromEntity(
      subscription.copyWith(
        status: SubscriptionStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<UserSubscription> renewSubscription(String id) async {
    final subscription = _find(id);
    final startDate = DateTime.now();
    final updated = UserSubscriptionModel.fromEntity(
      subscription.copyWith(
        totalRides: _ridesFor(subscription.type),
        usedRides: 0,
        remainingRides: _ridesFor(subscription.type),
        startDate: startDate,
        endDate: _endDateFor(subscription.type, startDate),
        status: SubscriptionStatus.pendingPayment,
        updatedAt: startDate,
      ),
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<UserSubscription> markRideUsed(String id) async {
    final subscription = _find(id);
    if (subscription.remainingRides <= 0) {
      throw StateError('No rides remaining');
    }
    final remaining = subscription.remainingRides - 1;
    final updated = UserSubscriptionModel.fromEntity(
      subscription.copyWith(
        usedRides: subscription.usedRides + 1,
        remainingRides: remaining,
        status: remaining == 0
            ? SubscriptionStatus.expired
            : subscription.status,
        updatedAt: DateTime.now(),
      ),
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() async {
    return const SubscriptionCreationOptions(users: _users, trips: _trips);
  }

  UserSubscription _find(String id) {
    return _subscriptions.firstWhere(
      (subscription) => subscription.id == id,
      orElse: () => throw StateError('Subscription not found'),
    );
  }

  void _replace(UserSubscription subscription) {
    final index = _subscriptions.indexWhere(
      (item) => item.id == subscription.id,
    );
    if (index == -1) {
      throw StateError('Subscription not found');
    }
    _subscriptions[index] = subscription;
  }

  static int _ridesFor(SubscriptionType type) {
    return switch (type) {
      SubscriptionType.oneTime => 1,
      SubscriptionType.fiveDays => 5,
      SubscriptionType.tenDaysMonthly => 10,
      SubscriptionType.monthly => 22,
      SubscriptionType.threeMonths => 66,
    };
  }

  static DateTime _endDateFor(SubscriptionType type, DateTime startDate) {
    return switch (type) {
      SubscriptionType.oneTime => startDate,
      SubscriptionType.fiveDays => startDate.add(const Duration(days: 4)),
      SubscriptionType.tenDaysMonthly => DateTime(
        startDate.year,
        startDate.month + 1,
        0,
      ),
      SubscriptionType.monthly => DateTime(
        startDate.year,
        startDate.month + 1,
        startDate.day - 1,
      ),
      SubscriptionType.threeMonths => DateTime(
        startDate.year,
        startDate.month + 3,
        startDate.day - 1,
      ),
    };
  }
}
