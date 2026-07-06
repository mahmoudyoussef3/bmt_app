import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/captain_onboarding_models.dart';

/// Talks to the anon-callable onboarding RPCs. The captain has no auth session
/// at this stage, so identity is carried entirely by the phone number.
class CaptainOnboardingDatasource {
  final SupabaseClient _client;
  const CaptainOnboardingDatasource(this._client);

  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
  }) async {
    final res = await _client.rpc(
      'submit_captain_request',
      params: {'p_full_name': fullName, 'p_phone': phone},
    );
    final map = Map<String, dynamic>.from(res as Map);
    final outcome = switch (map['outcome'] as String?) {
      'already_active' => SubmitOutcome.alreadyActive,
      'pending' => SubmitOutcome.pending,
      _ => SubmitOutcome.submitted,
    };
    return SubmitResult(
      outcome: outcome,
      phone: map['phone'] as String? ?? phone,
    );
  }

  Future<CaptainRequestStatusData?> getStatus(String phone) async {
    final res = await _client.rpc(
      'get_captain_request_status',
      params: {'p_phone': phone},
    );
    if (res == null) return null;
    final map = Map<String, dynamic>.from(res as Map);
    return CaptainRequestStatusData(
      status: switch (map['status'] as String?) {
        'approved' => RequestStatus.approved,
        'rejected' => RequestStatus.rejected,
        _ => RequestStatus.pending,
      },
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? phone,
      rejectionReason: map['rejection_reason'] as String?,
      driverId: map['driver_id'] as String?,
      employeeCode: map['employee_code'] as String? ?? '',
    );
  }
}
