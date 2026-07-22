import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/usecases/platform_admin_usecases.dart';
import 'platform_admin_state.dart';

class PlatformAdminCubit extends Cubit<PlatformAdminState> {
  PlatformAdminCubit({
    required GetPlatformOfficesUseCase getOffices,
    required OnboardOfficeUseCase onboardOffice,
    required SetOfficeListingUseCase setListing,
    required SetOfficeStatusUseCase setStatus,
  }) : _getOffices = getOffices,
       _onboardOffice = onboardOffice,
       _setListing = setListing,
       _setStatus = setStatus,
       super(const PlatformAdminInitial());

  final GetPlatformOfficesUseCase _getOffices;
  final OnboardOfficeUseCase _onboardOffice;
  final SetOfficeListingUseCase _setListing;
  final SetOfficeStatusUseCase _setStatus;

  Future<void> load() async {
    emit(const PlatformAdminLoading());
    try {
      emit(PlatformAdminLoaded(await _getOffices()));
    } catch (error) {
      emit(PlatformAdminError(_message(error)));
    }
  }

  Future<void> onboard(OfficeOnboardingRequest request) async {
    final offices = _offices();
    if (offices == null) return;

    emit(PlatformAdminLoaded(offices, isSubmitting: true));
    try {
      final result = await _onboardOffice(request);
      // Reload before revealing: the new office has to be in the list the
      // operator returns to once they dismiss the credentials. A failed reload
      // must not swallow the reveal, so it degrades to the list we already had.
      List<PlatformOffice> refreshed;
      try {
        refreshed = await _getOffices();
      } catch (_) {
        refreshed = offices;
      }
      emit(PlatformAdminOnboarded(result, refreshed));
    } on OfficeOnboardingValidationException catch (e) {
      emit(
        PlatformAdminActionFailure(
          e.errors.values.first,
          offices,
          fieldErrors: e.errors,
        ),
      );
      emit(PlatformAdminLoaded(offices, fieldErrors: e.errors));
    } catch (error) {
      emit(PlatformAdminActionFailure(_message(error), offices));
      emit(PlatformAdminLoaded(offices));
    }
  }

  /// Dismisses the credentials panel and returns to the list. There is no way
  /// back: the password exists only in that state object.
  void dismissOnboardingResult() {
    final current = state;
    if (current is PlatformAdminOnboarded) {
      emit(PlatformAdminLoaded(current.offices));
    }
  }

  Future<void> setListing(String officeId, String listingStatus) => _act(
    () => _setListing(officeId, listingStatus),
    switch (listingStatus) {
      'listed' => 'تم عرض المكتب في سوق العملاء',
      'unlisted' => 'تم سحب المكتب من سوق العملاء',
      _ => 'تم تحديث حالة العرض',
    },
  );

  Future<void> setStatus(String officeId, String status) => _act(
    () => _setStatus(officeId, status),
    switch (status) {
      'active' => 'تم تفعيل المكتب',
      'suspended' => 'تم إيقاف المكتب',
      'paused' => 'تم إيقاف المكتب مؤقتاً',
      _ => 'تم تحديث حالة المكتب',
    },
  );

  /// Every small action follows the same arc: optimistic "busy", run, reload,
  /// announce. Written once so publish, withdraw and suspend cannot drift.
  Future<void> _act(Future<void> Function() action, String successMessage) async {
    final offices = _offices();
    if (offices == null) return;

    emit(PlatformAdminLoaded(offices, isSubmitting: true));
    try {
      await action();
      final refreshed = await _getOffices();
      emit(PlatformAdminActionSuccess(successMessage, refreshed));
      emit(PlatformAdminLoaded(refreshed));
    } catch (error) {
      emit(PlatformAdminActionFailure(_message(error), offices));
      emit(PlatformAdminLoaded(offices));
    }
  }

  List<PlatformOffice>? _offices() {
    final current = state;
    return switch (current) {
      PlatformAdminLoaded() => current.offices,
      PlatformAdminOnboarded() => current.offices,
      PlatformAdminActionSuccess() => current.offices,
      PlatformAdminActionFailure() => current.offices,
      _ => null,
    };
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
