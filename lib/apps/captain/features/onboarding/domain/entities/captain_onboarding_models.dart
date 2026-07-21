/// An office a captain may apply to, as listed by the public `public_offices`
/// directory. Carries no join code — that is issued by the office out of band
/// and never published.
class OnboardingOffice {
  final String id;
  final String name;
  final String? logoUrl;
  final String? description;

  const OnboardingOffice({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
  });

  factory OnboardingOffice.fromRow(Map<String, dynamic> row) {
    return OnboardingOffice(
      id: (row['id'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      logoUrl: row['logo_url'] as String?,
      description: row['description'] as String?,
    );
  }
}

/// Outcome of submitting a captain access request.
enum SubmitOutcome {
  /// Newly queued for operations review.
  submitted,

  /// A review for this phone is already in flight.
  pending,

  /// This phone already belongs to an active captain — just sign in.
  alreadyActive,
}

class SubmitResult {
  final SubmitOutcome outcome;
  final String phone;
  const SubmitResult({required this.outcome, required this.phone});
}

enum RequestStatus { pending, approved, rejected }

/// Snapshot of a request's review state, polled by the captain app.
class CaptainRequestStatusData {
  final RequestStatus status;
  final String fullName;
  final String phone;
  final String? rejectionReason;
  final String? driverId;
  final String employeeCode;

  const CaptainRequestStatusData({
    required this.status,
    required this.fullName,
    required this.phone,
    this.rejectionReason,
    this.driverId,
    this.employeeCode = '',
  });
}
