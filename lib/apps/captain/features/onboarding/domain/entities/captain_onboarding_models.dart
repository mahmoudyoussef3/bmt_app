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

enum SubmitOutcome { submitted, pending, alreadyActive }

class SubmitResult {
  final SubmitOutcome outcome;
  final String phone;
  const SubmitResult({required this.outcome, required this.phone});
}

enum RequestStatus { pending, approved, rejected }

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
