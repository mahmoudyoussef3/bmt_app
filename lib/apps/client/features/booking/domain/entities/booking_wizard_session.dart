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

  bool get stopsValid =>
      pickupStop != null &&
      dropoffStop != null &&
      dropoffStop!.order > pickupStop!.order;

  bool get tripValid => selectedTrip != null;
  bool get seatValid => selectedSeatId != null;
  bool get packageValid => selectedPackage != null && packageStartDate != null;

  double get tripPrice => double.tryParse(selectedTrip?.price ?? '0') ?? 0;

  double get totalPrice {
    final base = tripPrice;
    final count = selectedPackage?.tripsCount ?? 1;
    final discount = selectedPackage?.discountPercent ?? 0;
    return base * count * (1 - discount / 100);
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
    );
  }
}
