/// The office's view of one passenger, as the directory lists them.
///
/// Every field here is aggregated server-side by `office_customer_directory`
/// over tables the office owns. There is no counter column on `clients` — the
/// identity table carries a name, a phone and nothing else — so these numbers
/// are computed per request rather than read, and none of them exists anywhere
/// to drift from.
class CustomerSummary {
  final String clientId;
  final String fullName;
  final String phone;
  final String? email;

  /// `clients.status`. The passenger's own account state, not a relationship
  /// state with this office — the office does not own it and cannot change it.
  final String status;

  /// When the passenger registered on the platform, which is **not** when they
  /// became this office's customer. [firstBookingAt] is that date.
  final DateTime joinedAt;

  final int bookingsTotal;
  final int bookingsCompleted;
  final int bookingsCancelled;

  /// First and most recent contact with *this* office.
  final DateTime? firstBookingAt;

  /// The newest of: a booking taken, a receipt submitted, a wallet movement.
  /// Null when the office holds none of the three, which is possible for a
  /// customer who only ever had a wallet opened for them.
  final DateTime? lastActivityAt;

  /// The soonest non-cancelled booking dated today or later.
  final DateTime? nextTripDate;

  final String? activePackageName;
  final DateTime? activePackageEndDate;
  final int? activePackageTripsCount;
  final int? activePackageTripsUsed;

  /// Sum of approved payments taken by this office.
  final double totalPaid;

  /// Null means no wallet row, which is not the same as a zero balance: the
  /// office has never opened one for this customer.
  final double? walletBalance;
  final String? walletStatus;

  const CustomerSummary({
    required this.clientId,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.joinedAt,
    this.email,
    this.bookingsTotal = 0,
    this.bookingsCompleted = 0,
    this.bookingsCancelled = 0,
    this.firstBookingAt,
    this.lastActivityAt,
    this.nextTripDate,
    this.activePackageName,
    this.activePackageEndDate,
    this.activePackageTripsCount,
    this.activePackageTripsUsed,
    this.totalPaid = 0,
    this.walletBalance,
    this.walletStatus,
  });

  bool get hasActiveSubscription => activePackageName != null;

  bool get hasUpcomingTrip => nextTripDate != null;

  /// Up to two letters for the avatar. Falls back to a person glyph's absence
  /// rather than to a random character when the name is empty.
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first._firstRunes(2);
    return '${parts[0]._firstRunes(1)}${parts[1]._firstRunes(1)}';
  }
}

extension on String {
  /// Rune-safe prefix. Arabic names are fine with code units, but an emoji in a
  /// name would otherwise render as a broken half-character in the avatar.
  String _firstRunes(int n) => String.fromCharCodes(runes.take(n));
}

/// One page of the directory, with the total the filter matched — not the total
/// returned. The table pages against [total]; showing `rows.length` would tell
/// the operator the office has 25 customers.
class CustomerDirectoryPage {
  final int total;
  final List<CustomerSummary> rows;

  const CustomerDirectoryPage({required this.total, required this.rows});

  const CustomerDirectoryPage.empty() : total = 0, rows = const [];
}

/// The five headline counts, measured over the whole customer base rather than
/// the filtered page — so they do not move when the operator narrows the list.
class CustomersOverview {
  final int totalCustomers;

  /// Booked at least once in the last 30 days.
  final int activeCustomers;

  final int withActiveSubscription;
  final int withUpcomingTrip;

  /// First booking with *this* office within the last 30 days. A passenger who
  /// registered two years ago and bought here yesterday is new to this office.
  final int newCustomers;

  const CustomersOverview({
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.withActiveSubscription = 0,
    this.withUpcomingTrip = 0,
    this.newCustomers = 0,
  });
}
