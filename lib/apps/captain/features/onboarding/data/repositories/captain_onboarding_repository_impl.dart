import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/captain_onboarding_models.dart';
import '../../domain/repositories/captain_onboarding_repository.dart';
import '../datasources/captain_onboarding_datasource.dart';

class CaptainOnboardingRepositoryImpl implements CaptainOnboardingRepository {
  final CaptainOnboardingDatasource _datasource;
  const CaptainOnboardingRepositoryImpl(this._datasource);

  @override
  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
  }) async {
    try {
      return await _datasource.submit(fullName: fullName, phone: phone);
    } on PostgrestException catch (e) {
      throw Exception(_message(e));
    } catch (_) {
      throw Exception('تعذر إرسال الطلب. تحقق من اتصالك وحاول مجدداً.');
    }
  }

  @override
  Future<CaptainRequestStatusData?> getStatus(String phone) async {
    try {
      return await _datasource.getStatus(phone);
    } catch (_) {
      // Polling is best-effort; a transient failure shouldn't surface an error.
      return null;
    }
  }

  String _message(PostgrestException e) {
    // RPC validation raises errcode 22023 with an Arabic, user-facing message.
    if (e.code == '22023') return e.message;
    return 'تعذر إرسال الطلب. حاول مجدداً.';
  }
}
