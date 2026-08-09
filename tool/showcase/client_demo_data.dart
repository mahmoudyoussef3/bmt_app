// Demo data for the Client app screenshots. Invented riders, invented trips.

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/transport_office.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/loyalty_data.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/loyalty_tier.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/points_transaction.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/redeemable_reward.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_route.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_trip.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/wallet/domain/entities/client_wallet.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';

final DateTime now = DateTime.now();
final DateTime _midnight = DateTime(now.year, now.month, now.day);

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

final String _today = _date(now);
final String _tomorrow = _date(_midnight.add(const Duration(days: 1)));

const String riderName = 'منى عبد الرحمن';

// ── Offices ─────────────────────────────────────────────────────────────────

const OfficeSummary nileOffice = OfficeSummary(
  id: 'office-1',
  name: 'مكتب النيل للنقل',
  description:
      'رحلات يومية مجدولة بين المحافظات بأسطول مكيّف وكباتن معتمدين منذ 2016.',
  rating: 4.7,
  ratingsCount: 1284,
  serviceAreas: ['القاهرة', 'الجيزة', 'الإسكندرية', 'الغردقة'],
);

const List<OfficeSummary> offices = [
  nileOffice,
  OfficeSummary(
    id: 'office-2',
    name: 'شركة الدلتا للرحلات',
    description: 'خطوط الوجه البحري — المنصورة، طنطا، دمياط والمحلة.',
    rating: 4.5,
    ratingsCount: 862,
    serviceAreas: ['الدقهلية', 'الغربية', 'دمياط'],
  ),
  OfficeSummary(
    id: 'office-3',
    name: 'الصعيد الحديث للنقل',
    description: 'رحلات الوجه القبلي — أسيوط، سوهاج، المنيا وقنا.',
    rating: 4.4,
    ratingsCount: 517,
    serviceAreas: ['أسيوط', 'سوهاج', 'المنيا', 'قنا'],
  ),
  OfficeSummary(
    id: 'office-4',
    name: 'سيناء إكسبريس',
    description: 'خطوط البحر الأحمر وجنوب سيناء — الغردقة، شرم الشيخ ودهب.',
    rating: 4.6,
    ratingsCount: 394,
    serviceAreas: ['البحر الأحمر', 'جنوب سيناء'],
  ),
];

const List<OfficeRoute> officeRoutes = [
  OfficeRoute(
    id: 'route-1',
    name: 'القاهرة — الإسكندرية',
    startCity: 'القاهرة',
    endCity: 'الإسكندرية',
  ),
  OfficeRoute(
    id: 'route-2',
    name: 'القاهرة — الغردقة',
    startCity: 'القاهرة',
    endCity: 'الغردقة',
  ),
  OfficeRoute(
    id: 'route-3',
    name: 'القاهرة — أسيوط',
    startCity: 'القاهرة',
    endCity: 'أسيوط',
  ),
  OfficeRoute(
    id: 'route-4',
    name: 'المنصورة — القاهرة',
    startCity: 'المنصورة',
    endCity: 'القاهرة',
  ),
];

final List<OfficeTrip> officeTrips = [
  OfficeTrip(
    id: 'T-2423',
    routeId: 'route-1',
    routeName: 'القاهرة — الإسكندرية',
    pickup: 'موقف عبود',
    destination: 'موقف سيدي جابر',
    tripDate: _today,
    departureTime: '13:00:00',
    duration: '3 س 15 د',
    price: 'EGP 180',
    seatsLeft: 8,
  ),
  OfficeTrip(
    id: 'T-2425',
    routeId: 'route-3',
    routeName: 'القاهرة — أسيوط',
    pickup: 'موقف الملز',
    destination: 'موقف أسيوط',
    tripDate: _today,
    departureTime: '18:00:00',
    duration: '5 س 45 د',
    price: 'EGP 260',
    seatsLeft: 9,
  ),
  OfficeTrip(
    id: 'T-2427',
    routeId: 'route-1',
    routeName: 'القاهرة — الإسكندرية',
    pickup: 'موقف عبود',
    destination: 'موقف سيدي جابر',
    tripDate: _tomorrow,
    departureTime: '06:00:00',
    duration: '3 س 15 د',
    price: 'EGP 180',
    seatsLeft: 9,
  ),
  OfficeTrip(
    id: 'T-2426',
    routeId: 'route-2',
    routeName: 'القاهرة — الغردقة',
    pickup: 'موقف التجمع الخامس',
    destination: 'موقف الغردقة الرئيسي',
    tripDate: _tomorrow,
    departureTime: '07:00:00',
    duration: '6 س 30 د',
    price: 'EGP 420',
    seatsLeft: 11,
  ),
];

const List<PackagePlan> packages = [
  PackagePlan(
    id: 'pkg-1',
    nameAr: 'باقة شهرية — 20 رحلة',
    nameEn: 'Monthly 20 rides',
    packageType: 'monthly',
    durationDays: 30,
    rideCount: 20,
    price: 2800,
    officeId: 'office-1',
    officeName: 'مكتب النيل للنقل',
    officeRating: 4.7,
    officeRatingsCount: 1284,
  ),
  PackagePlan(
    id: 'pkg-2',
    nameAr: 'باقة ١٠ أيام',
    nameEn: '10 days',
    packageType: 'ten_days',
    durationDays: 30,
    rideCount: 10,
    price: 1500,
    officeId: 'office-1',
    officeName: 'مكتب النيل للنقل',
    officeRating: 4.7,
    officeRatingsCount: 1284,
  ),
  PackagePlan(
    id: 'pkg-3',
    nameAr: 'باقة ٥ أيام',
    nameEn: '5 days',
    packageType: 'five_days',
    durationDays: 15,
    rideCount: 5,
    price: 800,
    officeId: 'office-1',
    officeName: 'مكتب النيل للنقل',
    officeRating: 4.7,
    officeRatingsCount: 1284,
  ),
];

/// The plan the demo rider is riding on, matching the package Home advertises
/// as active — the two screens are photographed as one rider's session.
final MySubscription mySubscription = MySubscription(
  id: 'sub-1',
  packageName: 'باقة شهرية — 20 رحلة',
  routeName: 'القاهرة — الإسكندرية',
  status: 'active',
  tripsTotal: 20,
  tripsUsed: 7,
  startDate: _midnight.subtract(const Duration(days: 12)),
  endDate: _midnight.add(const Duration(days: 18)),
);

// ── Home ────────────────────────────────────────────────────────────────────

final HomeData homeData = HomeData(
  userName: riderName,
  upcomingTrips: [
    UpcomingTripData(
      tripId: 'T-2423',
      routeId: 'route-1',
      routeName: 'القاهرة — الإسكندرية',
      pickup: 'موقف عبود',
      destination: 'موقف سيدي جابر',
      tripDate: _today,
      departureTime: '13:00:00',
      duration: '3 س 15 د',
      price: 'EGP 180',
      seatsLeft: 8,
      isLive: false,
      officeId: 'office-1',
      officeName: 'مكتب النيل للنقل',
    ),
    UpcomingTripData(
      tripId: 'T-2425',
      routeId: 'route-3',
      routeName: 'القاهرة — أسيوط',
      pickup: 'موقف الملز',
      destination: 'موقف أسيوط',
      tripDate: _today,
      departureTime: '18:00:00',
      duration: '5 س 45 د',
      price: 'EGP 260',
      seatsLeft: 9,
      isLive: false,
      officeId: 'office-1',
      officeName: 'مكتب النيل للنقل',
    ),
    UpcomingTripData(
      tripId: 'T-2427',
      routeId: 'route-1',
      routeName: 'القاهرة — الإسكندرية',
      pickup: 'موقف عبود',
      destination: 'موقف سيدي جابر',
      tripDate: _tomorrow,
      departureTime: '06:00:00',
      duration: '3 س 15 د',
      price: 'EGP 180',
      seatsLeft: 9,
      isLive: false,
      officeId: 'office-1',
      officeName: 'مكتب النيل للنقل',
    ),
    UpcomingTripData(
      tripId: 'T-2426',
      routeId: 'route-2',
      routeName: 'القاهرة — الغردقة',
      pickup: 'موقف التجمع الخامس',
      destination: 'موقف الغردقة الرئيسي',
      tripDate: _tomorrow,
      departureTime: '07:00:00',
      duration: '6 س 30 د',
      price: 'EGP 420',
      seatsLeft: 11,
      isLive: false,
      officeId: 'office-4',
      officeName: 'سيناء إكسبريس',
    ),
  ],
  pickupSuggestions: const ['موقف عبود', 'موقف التجمع الخامس', 'موقف الملز'],
  destinationSuggestions: const [
    'موقف سيدي جابر',
    'موقف الغردقة الرئيسي',
    'موقف أسيوط',
  ],
  timeSuggestions: const ['06:00', '09:30', '13:00', '18:00'],
  bookings: [
    HomeBookingData(
      id: 'b-1',
      tripId: 'T-2423',
      bookingNumber: '10428',
      status: HomeBookingStatus.confirmed,
      pickup: 'موقف عبود',
      destination: 'موقف سيدي جابر',
      tripDate: _today,
      departureTime: '13:00:00',
      seatLabel: 'A3',
      fare: 'EGP 180',
    ),
  ],
  activePackage: HomeActivePackageData(
    title: 'باقة شهرية — 20 رحلة',
    routeLabel: 'القاهرة — الإسكندرية',
    startDate: _midnight.subtract(const Duration(days: 12)),
    endDate: _midnight.add(const Duration(days: 18)),
  ),
);

// ── Trips ───────────────────────────────────────────────────────────────────

List<TripSeat> _seatMap({required List<int> mine, required List<int> taken}) {
  return [
    for (var i = 1; i <= 14; i++)
      TripSeat(
        label: '${String.fromCharCode(65 + (i - 1) ~/ 4)}${(i - 1) % 4 + 1}',
        number: i,
        row: (i - 1) ~/ 4,
        column: (i - 1) % 4,
        state: mine.contains(i)
            ? TripSeatState.mine
            : taken.contains(i)
            ? TripSeatState.occupied
            : TripSeatState.available,
      ),
  ];
}

final TripData confirmedTrip = TripData(
  id: 'b-1',
  reference: '10428',
  status: TripStatus.upcoming,
  bookingState: BookingState.confirmed,
  pickup: 'موقف عبود',
  destination: 'موقف سيدي جابر',
  dateLabel: 'اليوم',
  timeLabel: '13:00',
  driverName: 'أحمد علي حسن',
  driverPhone: '01000000001',
  driverInitials: 'أح',
  driverRating: 4.8,
  driverRatingCount: 213,
  vehicleName: 'تويوتا هايس',
  vehicleType: 'ميكروباص مكيّف',
  vehicleId: 'ن ص ٤٢٧',
  seats: const ['A3'],
  seatMap: _seatMap(mine: const [3], taken: const [1, 2, 5, 6, 9, 12]),
  paymentStatus: PaymentStatus.paid,
  fare: 'EGP 180',
  tripId: 'T-2423',
  officeName: 'مكتب النيل للنقل',
);

final List<TripData> trips = [
  confirmedTrip,
  TripData(
    id: 'b-2',
    reference: '10426',
    status: TripStatus.upcoming,
    bookingState: BookingState.reserved,
    pickup: 'موقف الملز',
    destination: 'موقف أسيوط',
    dateLabel: 'اليوم',
    timeLabel: '18:00',
    driverName: 'خالد إبراهيم فؤاد',
    driverPhone: '01000000002',
    driverInitials: 'خإ',
    driverRating: 4.6,
    driverRatingCount: 148,
    vehicleName: 'هيونداي H1',
    vehicleType: 'ميكروباص مكيّف',
    vehicleId: 'ق ر ٦٥٨',
    seats: const ['B2'],
    seatMap: _seatMap(mine: const [6], taken: const [1, 4, 8]),
    paymentStatus: PaymentStatus.pending,
    fare: 'EGP 260',
    tripId: 'T-2425',
    officeName: 'مكتب النيل للنقل',
  ),
  TripData(
    id: 'b-3',
    reference: '10419',
    status: TripStatus.completed,
    bookingState: BookingState.completed,
    pickup: 'موقف عبود',
    destination: 'موقف سيدي جابر',
    dateLabel: _date(_midnight.subtract(const Duration(days: 4))),
    timeLabel: '06:00',
    driverName: 'عمرو شعبان زكي',
    driverPhone: '01000000003',
    driverInitials: 'عش',
    driverRating: 4.9,
    driverRatingCount: 302,
    vehicleName: 'مرسيدس سبرنتر',
    vehicleType: 'ميكروباص مكيّف',
    vehicleId: 'س ع ٨٧٤',
    seats: const ['C1'],
    seatMap: const [],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 180',
    tripId: 'T-2418',
    officeName: 'مكتب النيل للنقل',
    completedAt: _date(_midnight.subtract(const Duration(days: 4))),
    isReviewed: true,
  ),
  TripData(
    id: 'b-4',
    reference: '10402',
    status: TripStatus.completed,
    bookingState: BookingState.completed,
    pickup: 'موقف المنصورة',
    destination: 'موقف رمسيس',
    dateLabel: _date(_midnight.subtract(const Duration(days: 11))),
    timeLabel: '06:15',
    driverName: 'مصطفى كامل رشدي',
    driverPhone: '01000000004',
    driverInitials: 'مك',
    driverRating: 4.7,
    driverRatingCount: 96,
    vehicleName: 'تويوتا هايس',
    vehicleType: 'ميكروباص مكيّف',
    vehicleId: 'د ل ٣٠٢',
    seats: const ['A2'],
    seatMap: const [],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 120',
    tripId: 'T-2390',
    officeName: 'شركة الدلتا للرحلات',
  ),
];

// ── Seat selection ──────────────────────────────────────────────────────────

final SeatSelectionData seatSelection = SeatSelectionData(
  tripId: 'T-2423',
  seats: [
    for (var i = 1; i <= 14; i++)
      SeatOption(
        id: 'seat-$i',
        seatNumber: i,
        seatLabel:
            '${String.fromCharCode(65 + (i - 1) ~/ 4)}${(i - 1) % 4 + 1}',
        row: (i - 1) ~/ 4,
        column: (i - 1) % 4,
        availability: const [1, 2, 5, 6, 9, 12].contains(i)
            ? SeatAvailability.reserved
            : SeatAvailability.available,
      ),
  ],
  pricePerSeat: 180,
  pickupPoint: 'موقف عبود',
  destination: 'موقف سيدي جابر',
  vehicleNumber: 'ن ص ٤٢٧',
  vehicleName: 'تويوتا هايس',
  vehicleType: 'ميكروباص مكيّف',
  vehicleModel: '2021',
  vehicleImageUrl: '',
  tripDate: _today,
  departureTime: '13:00',
  arrivalTime: '16:15',
  driverName: 'أحمد علي حسن',
  driverRating: 4.8,
  driverImageUrl: '',
);

// ── Payment ─────────────────────────────────────────────────────────────────

const PaymentCheckoutData checkout = PaymentCheckoutData(
  tripId: 'T-2423',
  pickupPoint: 'موقف عبود',
  destination: 'موقف سيدي جابر',
  vehicleNumber: 'ن ص ٤٢٧',
  vehicleName: 'تويوتا هايس',
  tripDate: 'اليوم',
  departureTime: '13:00',
  arrivalTime: '16:15',
  selectedSeatId: 'seat-3',
  selectedSeat: 'A3',
  driverName: 'أحمد علي حسن',
  driverRating: 4.8,
  baseFare: 180,
  serviceFee: 10,
  tax: 0,
  walletBalanceLabel: 'رصيد المحفظة',
  walletBalance: 420,
);

const List<PaymentMethodData> paymentMethods = [
  PaymentMethodData(
    type: PaymentMethodType.walletBalance,
    title: 'رصيد المحفظة',
    subtitle: 'EGP 420 متاح',
    recommended: true,
  ),
  PaymentMethodData(
    type: PaymentMethodType.creditCard,
    title: 'بطاقة بنكية',
    subtitle: 'فيزا أو ماستركارد',
  ),
  PaymentMethodData(
    type: PaymentMethodType.instapay,
    title: 'انستا باي',
    subtitle: 'تحويل فوري ثم رفع الإيصال',
    transferAccount: 'nile.transport@instapay',
    accountHolder: 'مكتب النيل للنقل',
  ),
  PaymentMethodData(
    type: PaymentMethodType.vodafoneCash,
    title: 'فودافون كاش',
    subtitle: 'تحويل من المحفظة ثم رفع الإيصال',
    transferAccount: '01000000001',
    accountHolder: 'مكتب النيل للنقل',
  ),
];

// ── Wallet ──────────────────────────────────────────────────────────────────

final ClientWalletSummary wallet = ClientWalletSummary(
  totalBalance: 645,
  generatedAt: now,
  wallets: [
    ClientWallet(
      walletId: 'w-1',
      officeId: 'office-1',
      officeName: 'مكتب النيل للنقل',
      balance: 420,
      availableBalance: 420,
      status: 'active',
      entryCount: 6,
      updatedAt: now.subtract(const Duration(hours: 5)),
      entries: [
        ClientWalletEntry(
          id: 'e-1',
          seq: 6,
          kind: ClientWalletEntryKind.refund,
          category: 'refund',
          amount: 260,
          balanceAfter: 420,
          status: 'posted',
          reason: 'استرداد قيمة حجز ملغى ٠١٠٤٢١',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        ClientWalletEntry(
          id: 'e-2',
          seq: 5,
          kind: ClientWalletEntryKind.cashback,
          category: 'cashback',
          amount: 140,
          balanceAfter: 160,
          status: 'posted',
          reason: 'كاش باك شراء باقة شهرية',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        ClientWalletEntry(
          id: 'e-3',
          seq: 4,
          kind: ClientWalletEntryKind.walletSpend,
          category: 'booking',
          amount: -180,
          balanceAfter: 20,
          status: 'posted',
          reason: 'دفع حجز ١٠٤١٩ — القاهرة/الإسكندرية',
          createdAt: now.subtract(const Duration(days: 6)),
        ),
        ClientWalletEntry(
          id: 'e-4',
          seq: 3,
          kind: ClientWalletEntryKind.refund,
          category: 'refund',
          amount: 200,
          balanceAfter: 200,
          status: 'posted',
          reason: 'تعويض تأخير رحلة',
          createdAt: now.subtract(const Duration(days: 9)),
        ),
      ],
    ),
    ClientWallet(
      walletId: 'w-2',
      officeId: 'office-2',
      officeName: 'شركة الدلتا للرحلات',
      balance: 225,
      availableBalance: 225,
      status: 'active',
      entryCount: 2,
      updatedAt: now.subtract(const Duration(days: 11)),
      entries: [
        ClientWalletEntry(
          id: 'e-5',
          seq: 2,
          kind: ClientWalletEntryKind.refund,
          category: 'refund',
          amount: 225,
          balanceAfter: 225,
          status: 'posted',
          reason: 'استرداد رحلة ملغاة من المكتب',
          createdAt: now.subtract(const Duration(days: 11)),
        ),
      ],
    ),
  ],
);

// ── Loyalty ─────────────────────────────────────────────────────────────────

const List<LoyaltyTier> _tiers = [
  LoyaltyTier(
    name: 'برونزي',
    pointsRequiredLabel: '0 نقطة',
    perks: ['خصم 5% على الباقات', 'أولوية في قائمة الانتظار'],
    gradientColors: [0xFF8D6E63, 0xFF5D4037],
    iconKey: 'bronze',
  ),
  LoyaltyTier(
    name: 'فضي',
    pointsRequiredLabel: '500 نقطة',
    perks: ['خصم 10% على الباقات', 'تغيير مجاني للموعد مرة شهريًا'],
    gradientColors: [0xFF90A4AE, 0xFF546E7A],
    iconKey: 'silver',
  ),
  LoyaltyTier(
    name: 'ذهبي',
    pointsRequiredLabel: '1500 نقطة',
    perks: ['خصم 15% على الباقات', 'اختيار المقعد مجانًا', 'دعم أولوية'],
    gradientColors: [0xFFFFB300, 0xFFF57C00],
    iconKey: 'gold',
  ),
  LoyaltyTier(
    name: 'بلاتيني',
    pointsRequiredLabel: '3000 نقطة',
    perks: ['خصم 20% على الباقات', 'إلغاء مجاني', 'رحلة مجانية كل 20 رحلة'],
    gradientColors: [0xFF7986CB, 0xFF3949AB],
    iconKey: 'platinum',
  ),
];

final LoyaltyData loyalty = LoyaltyData(
  currentPoints: 1840,
  currentTierName: 'ذهبي',
  tiers: _tiers,
  transactions: [
    PointsTransaction(
      title: 'رحلة القاهرة — الإسكندرية',
      date: _date(_midnight.subtract(const Duration(days: 4))),
      points: 180,
      isEarned: true,
    ),
    PointsTransaction(
      title: 'شراء باقة شهرية',
      date: _date(_midnight.subtract(const Duration(days: 12))),
      points: 560,
      isEarned: true,
    ),
    PointsTransaction(
      title: 'استبدال قسيمة خصم 50 ج.م',
      date: _date(_midnight.subtract(const Duration(days: 18))),
      points: 400,
      isEarned: false,
    ),
    PointsTransaction(
      title: 'رحلة المنصورة — القاهرة',
      date: _date(_midnight.subtract(const Duration(days: 22))),
      points: 120,
      isEarned: true,
    ),
    PointsTransaction(
      title: 'دعوة صديق',
      date: _date(_midnight.subtract(const Duration(days: 30))),
      points: 250,
      isEarned: true,
    ),
  ],
  rewards: const [
    RedeemableReward(
      id: 'rw-1',
      title: 'خصم 50 ج.م',
      description: 'على أي رحلة بين المحافظات',
      pointsCost: 400,
      valueLabel: 'EGP 50',
      category: 'خصم',
      couponCode: 'NILE50',
    ),
    RedeemableReward(
      id: 'rw-2',
      title: 'رحلة مجانية',
      description: 'مقعد واحد على خط القاهرة — الإسكندرية',
      pointsCost: 1500,
      valueLabel: 'EGP 180',
      category: 'رحلة',
      couponCode: 'NILEFREE',
    ),
    RedeemableReward(
      id: 'rw-3',
      title: 'ترقية مقعد',
      description: 'اختيار المقعد الأمامي مجانًا',
      pointsCost: 250,
      valueLabel: 'مجاني',
      category: 'ترقية',
      couponCode: 'NILESEAT',
    ),
    RedeemableReward(
      id: 'rw-4',
      title: 'خصم 20% على الباقات',
      description: 'يُطبق على الباقة الشهرية القادمة',
      pointsCost: 900,
      valueLabel: 'حتى EGP 560',
      category: 'باقة',
      couponCode: 'NILEPKG20',
    ),
  ],
);

// ── Booking wizard ──────────────────────────────────────────────────────────
//
// The live booking funnel is the wizard, not the retired standalone seat →
// checkout pair. It is seeded from one `RouteOptionData`, so the whole session
// (stops, trip, seat, package, payment) unfolds from the object below.

const TransportOffice _nileOperator = TransportOffice(
  id: 'office-1',
  name: 'مكتب النيل للنقل',
  description:
      'رحلات يومية مجدولة بين المحافظات بأسطول مكيّف وكباتن معتمدين منذ 2016.',
  rating: 4.7,
  ratingsCount: 1284,
  serviceAreas: ['القاهرة', 'الجيزة', 'الإسكندرية', 'الغردقة'],
);

const List<RoutePointData> _cairoAlexStops = [
  RoutePointData(
    id: 'stop-1',
    name: 'موقف عبود',
    order: 1,
    dropoffAllowed: false,
    latitude: 30.0958,
    longitude: 31.2497,
  ),
  RoutePointData(
    id: 'stop-2',
    name: 'موقف المظلات',
    order: 2,
    latitude: 30.1216,
    longitude: 31.2436,
  ),
  RoutePointData(
    id: 'stop-3',
    name: 'كايرو فيستيفال سيتي',
    order: 3,
    latitude: 30.0289,
    longitude: 31.4089,
  ),
  RoutePointData(
    id: 'stop-4',
    name: 'موقف سموحة',
    order: 4,
    pickupAllowed: false,
    latitude: 31.2156,
    longitude: 29.9553,
  ),
  RoutePointData(
    id: 'stop-5',
    name: 'موقف سيدي جابر',
    order: 5,
    pickupAllowed: false,
    latitude: 31.2189,
    longitude: 29.9436,
  ),
];

/// One fare per stop pair, expanded from the trip's single ticket price —
/// packages are flat multiples of it, never rides × fare.
List<TripStopPairPrice> _pairPrices(double fare) => [
  for (final from in _cairoAlexStops)
    for (final to in _cairoAlexStops)
      if (to.order > from.order)
        TripStopPairPrice(
          fromPointId: from.id,
          toPointId: to.id,
          oneTimePrice: fare,
          fiveDaysPrice: fare * 3.5,
          tenDaysPrice: fare * 3.75,
          monthlyPrice: fare * 4,
          threeMonthsPrice: fare * 4.5,
        ),
];

const TripVehicleProfile _hiaceProfile = TripVehicleProfile(
  brand: 'تويوتا',
  model: 'هايس',
  plateNumber: 'ن ص ٤٢٧',
  vehicleType: 'ميكروباص مكيّف',
  color: 'أبيض',
  manufactureYear: 2021,
  capacity: 14,
  seatLayoutType: '2-2',
  features: ['تكييف', 'واي فاي', 'شاحن USB', 'مقاعد مريحة'],
  vehicleRating: 4.7,
  vehicleRatingCount: 168,
  driverName: 'أحمد علي حسن',
  driverRating: 4.8,
  driverRatingCount: 213,
);

const TripVehicleProfile _sprinterProfile = TripVehicleProfile(
  brand: 'مرسيدس',
  model: 'سبرنتر',
  plateNumber: 'س ع ٨٧٤',
  vehicleType: 'ميكروباص مكيّف',
  color: 'فضي',
  manufactureYear: 2022,
  capacity: 16,
  seatLayoutType: '2-2',
  features: ['تكييف', 'شاحن USB', 'مساحة أمتعة'],
  vehicleRating: 4.9,
  vehicleRatingCount: 244,
  driverName: 'عمرو شعبان زكي',
  driverRating: 4.9,
  driverRatingCount: 302,
);

final RouteTripOptionData middayTrip = RouteTripOptionData(
  id: 'T-2423',
  tripDate: _today,
  departureTime: '13:00',
  arrivalTime: '16:15',
  availableSeats: 8,
  vehicleType: 'ميكروباص مكيّف',
  price: 'EGP 180',
  stopPricing: _pairPrices(180),
  vehicle: _hiaceProfile,
);

final RouteOptionData bookingRoute = RouteOptionData(
  id: 'route-1',
  routeName: 'القاهرة — الإسكندرية',
  pickup: 'موقف عبود',
  destination: 'موقف سيدي جابر',
  distance: '286 كم',
  duration: '3 س 15 د',
  availableSeats: 8,
  startingPrice: 'EGP 180',
  priceRange: 'EGP 180 — 210',
  isFastest: true,
  office: _nileOperator,
  points: _cairoAlexStops,
  availableTrips: [
    middayTrip,
    RouteTripOptionData(
      id: 'T-2427',
      tripDate: _today,
      departureTime: '17:30',
      arrivalTime: '20:45',
      availableSeats: 11,
      vehicleType: 'ميكروباص مكيّف',
      price: 'EGP 180',
      stopPricing: _pairPrices(180),
      vehicle: _sprinterProfile,
    ),
    RouteTripOptionData(
      id: 'T-2431',
      tripDate: _tomorrow,
      departureTime: '06:00',
      arrivalTime: '09:15',
      availableSeats: 14,
      vehicleType: 'ميكروباص مكيّف',
      price: 'EGP 180',
      stopPricing: _pairPrices(180),
      vehicle: _hiaceProfile,
    ),
  ],
);

/// The second operator on the same corridor — results must read as a
/// marketplace, not one office's timetable.
final RouteOptionData deltaRoute = RouteOptionData(
  id: 'route-9',
  routeName: 'القاهرة — الإسكندرية',
  pickup: 'موقف رمسيس',
  destination: 'موقف المنشية',
  distance: '228 كم',
  duration: '3 س 40 د',
  availableSeats: 6,
  startingPrice: 'EGP 165',
  priceRange: 'EGP 165 — 195',
  matchQuality: RouteMatchQuality.partial,
  office: const TransportOffice(
    id: 'office-2',
    name: 'شركة الدلتا للرحلات',
    rating: 4.5,
    ratingsCount: 862,
  ),
  points: const [
    RoutePointData(id: 'd-1', name: 'موقف رمسيس', order: 1),
    RoutePointData(id: 'd-2', name: 'موقف المنشية', order: 2),
  ],
  availableTrips: [
    RouteTripOptionData(
      id: 'T-3120',
      tripDate: _today,
      departureTime: '14:30',
      arrivalTime: '18:10',
      availableSeats: 6,
      vehicleType: 'ميكروباص مكيّف',
      price: 'EGP 165',
      vehicle: _sprinterProfile,
    ),
  ],
);

final List<RouteOptionData> routeResults = [bookingRoute, deltaRoute];

const BookingSearchQuery searchQuery = BookingSearchQuery(
  pickup: 'القاهرة',
  destination: 'الإسكندرية',
);
