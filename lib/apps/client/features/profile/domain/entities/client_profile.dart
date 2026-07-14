/// The rider's account as the profile hub needs it: who they are, plus the few
/// operational facts that make the hub worth opening (trips taken, whether a
/// package is running).
///
/// The menu itself is not modelled here — what the hub offers and what it is
/// called is a presentation concern, so it never travels through the data layer.
class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.memberSince,
    this.completedTrips = 0,
    this.upcomingTrips = 0,
    this.activePackage,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? memberSince;

  /// Trips the rider actually travelled — the number they would recognise as
  /// "trips I have taken".
  final int completedTrips;

  /// Seats held on departures that have not run yet.
  final int upcomingTrips;

  /// The package the rider currently pays for, or `null` when they ride
  /// pay-as-you-go.
  final ActivePackage? activePackage;

  bool get hasActivePackage => activePackage != null;

  /// Contact details the rider still owes us. Drives the "complete your
  /// profile" prompt on the hub.
  List<ProfileField> get missingFields => [
    if (name.trim().isEmpty) ProfileField.name,
    if (phone.trim().isEmpty) ProfileField.phone,
    if (email.trim().isEmpty) ProfileField.email,
  ];

  bool get isComplete => missingFields.isEmpty;

  /// Up to two letters for the avatar; falls back to the email's first letter
  /// so a nameless account never renders an empty circle.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);
    if (parts.isEmpty) {
      final source = email.trim().isNotEmpty ? email.trim() : '?';
      return source[0].toUpperCase();
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  ClientProfile copyWith({String? name, String? email, String? phone}) {
    return ClientProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberSince: memberSince,
      completedTrips: completedTrips,
      upcomingTrips: upcomingTrips,
      activePackage: activePackage,
    );
  }
}

enum ProfileField { name, phone, email }

/// A subscription the rider is currently riding on.
class ActivePackage {
  const ActivePackage({
    required this.name,
    required this.routeName,
    this.endDate,
  });

  final String name;
  final String routeName;
  final DateTime? endDate;

  /// Whole days left before the package lapses; `null` when it never expires.
  /// Clamped at zero so an already-lapsed row never renders a negative count.
  int? get daysRemaining {
    final end = endDate;
    if (end == null) return null;
    final now = DateTime.now();
    final days = DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return days < 0 ? 0 : days;
  }

  /// Close enough to expiry that the rider should be nudged to renew.
  bool get isExpiringSoon {
    final days = daysRemaining;
    return days != null && days <= 7;
  }
}
