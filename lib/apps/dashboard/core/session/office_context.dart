import '../permissions/dashboard_role.dart';

/// Who the signed-in operator is, and which office they administer.
///
/// Resolved once at sign-in from the `current_office_context` RPC and held for the
/// lifetime of the session. Every office-scoped query reads [officeId] from here —
/// it is never typed in, passed through a route, or inferred from a fetched row, so
/// there is no client-side value an operator could tamper with to reach another
/// office. The database enforces the same boundary independently via RLS.
class OfficeContext {
  const OfficeContext({
    required this.officeId,
    required this.officeName,
    required this.officeSlug,
    required this.role,
    required this.username,
    this.fullName = '',
    this.logoUrl,
  });

  final String officeId;
  final String officeName;
  final String officeSlug;
  final DashboardRole role;
  final String username;
  final String fullName;
  final String? logoUrl;

  /// The operator's display name, falling back to the login name when the account
  /// has no full name recorded.
  String get displayName => fullName.trim().isEmpty ? username : fullName.trim();

  factory OfficeContext.fromRpc(Map<String, dynamic> row) {
    return OfficeContext(
      officeId: row['office_id'] as String,
      officeName: (row['office_name'] as String?) ?? '',
      officeSlug: (row['office_slug'] as String?) ?? '',
      role: DashboardRole.fromDb((row['role'] as String?) ?? 'support_agent'),
      username: (row['username'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      logoUrl: row['logo_url'] as String?,
    );
  }
}
