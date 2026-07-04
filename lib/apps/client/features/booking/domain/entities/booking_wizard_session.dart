import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

class BookingWizardSession {
  const BookingWizardSession({
    required this.route,
    this.pickupStop,
    this.dropoffStop,
    this.selectedTrip,
    this.selectedSeatId,
    this.selectedSeatLabel,
    this.selectedPackage,
    this.packageStartDate,
    this.paymentMethod,
    this.receiptUrl,
    this.paymentReference,
    this.payerPhone,
  });

  final RouteOptionData route;
  final RoutePointData? pickupStop;
  final RoutePointData? dropoffStop;
  final RouteTripOptionData? selectedTrip;
  final String? selectedSeatId;
  final String? selectedSeatLabel;
  final PackagePlan? selectedPackage;
  final DateTime? packageStartDate;
  final String? paymentMethod;
  final String? receiptUrl;
  final String? paymentReference;
  final String? payerPhone;

  bool get stopsValid =>
      pickupStop != null &&
      dropoffStop != null &&
      dropoffStop!.order > pickupStop!.order;

  bool get tripValid => selectedTrip != null;
  bool get seatValid => selectedSeatId != null;
  bool get packageValid => selectedPackage != null && packageStartDate != null;
  bool get isCardPayment => paymentMethod == 'credit_card';
  bool get paymentValid =>
      paymentMethod != null && (isCardPayment || receiptUrl != null);

  double get tripPrice => double.tryParse(selectedTrip?.price ?? '0') ?? 0;

  double get totalPrice {
    if (selectedPackage != null) return selectedPackage!.price;
    return tripPrice;
  }

  String get priceSummary {
    if (!packageValid) return 'EGP ${tripPrice.toStringAsFixed(0)} / ride';
    return 'EGP ${totalPrice.toStringAsFixed(0)} total';
  }

  BookingWizardSession copyWith({
    RoutePointData? pickupStop,
    bool clearDropoff = false,
    RoutePointData? dropoffStop,
    RouteTripOptionData? selectedTrip,
    String? selectedSeatId,
    String? selectedSeatLabel,
    PackagePlan? selectedPackage,
    DateTime? packageStartDate,
    String? paymentMethod,
    String? receiptUrl,
    String? paymentReference,
    String? payerPhone,
  }) {
    return BookingWizardSession(
      route: route,
      pickupStop: pickupStop ?? this.pickupStop,
      dropoffStop: clearDropoff ? null : (dropoffStop ?? this.dropoffStop),
      selectedTrip: selectedTrip ?? this.selectedTrip,
      selectedSeatId: selectedSeatId ?? this.selectedSeatId,
      selectedSeatLabel: selectedSeatLabel ?? this.selectedSeatLabel,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      packageStartDate: packageStartDate ?? this.packageStartDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      payerPhone: payerPhone ?? this.payerPhone,
    );
  }
}
