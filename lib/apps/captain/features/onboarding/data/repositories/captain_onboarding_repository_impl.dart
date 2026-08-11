import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/captain_onboarding_models.dart';
import '../../domain/repositories/captain_onboarding_repository.dart';
import '../datasources/captain_onboarding_datasource.dart';

class CaptainOnboardingRepositoryImpl implements CaptainOnboardingRepository {
  final CaptainOnboardingDatasource _datasource;
  const CaptainOnboardingRepositoryImpl(this._datasource);

  @override
  Future<List<OnboardingOffice>> fetchActiveOffices() async {
    try {
      return await _datasource.fetchActiveOffices();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<SubmitResult> submit({
    required String fullName,
    required String phone,
    String? officeId,
    String? officeCode,
  }) async {
    try {
      return await _datasource.submit(
        fullName: fullName,
        phone: phone,
        officeId: officeId,
        officeCode: officeCode,
      );
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
      return null;
    }
  }

  String _message(PostgrestException e) {
    if (e.code == '22023') return e.message;

    final raw = e.message;
    if (raw.contains('office_code_required')) {
      return 'أدخل كود المكتب الذي تنضم إليه.';
    }
    if (raw.contains('invalid_office_code')) {
      return 'كود المكتب غير صحيح. تواصل مع المكتب للحصول على الكود.';
    }
    if (raw.contains('office_code_mismatch')) {
      return 'الكود لا يخص المكتب المختار.';
    }
    if (raw.contains('office_inactive')) {
      return 'هذا المكتب لا يستقبل طلبات حالياً.';
    }
    return 'تعذر إرسال الطلب. حاول مجدداً.';
  }
}
