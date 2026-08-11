import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/captain_session_store.dart';
import '../../domain/entities/captain_onboarding_models.dart';
import '../../domain/usecases/onboarding_usecases.dart';
import 'captain_onboarding_state.dart';

class CaptainOnboardingCubit extends Cubit<CaptainOnboardingState> {
  final SubmitCaptainRequestUseCase _submit;
  final GetCaptainRequestStatusUseCase _getStatus;
  final GetActiveOfficesUseCase _getOffices;
  final CaptainSessionStore _store;

  Timer? _poll;
  static const _pollInterval = Duration(seconds: 4);

  CaptainOnboardingCubit({
    required SubmitCaptainRequestUseCase submit,
    required GetCaptainRequestStatusUseCase getStatus,
    required GetActiveOfficesUseCase getOffices,
    required CaptainSessionStore store,
  }) : _submit = submit,
       _getStatus = getStatus,
       _getOffices = getOffices,
       _store = store,
       super(const OnboardingForm());

  void init(String? pendingPhone) {
    if (pendingPhone != null && pendingPhone.isNotEmpty) {
      _beginPolling(pendingPhone);
    } else {
      emit(const OnboardingForm(loadingOffices: true));
      _loadOffices();
    }
  }

  Future<void> _loadOffices() async {
    final offices = await _getOffices();
    if (isClosed || state is! OnboardingForm) return;
    final current = state as OnboardingForm;
    emit(OnboardingForm(error: current.error, offices: offices));
  }

  Future<void> submit({
    required String fullName,
    required String phone,
    String? officeId,
    String? officeCode,
  }) async {
    final offices = state is OnboardingForm
        ? (state as OnboardingForm).offices
        : const <OnboardingOffice>[];

    emit(const OnboardingSubmitting());
    try {
      final result = await _submit(
        fullName: fullName,
        phone: phone,
        officeId: officeId,
        officeCode: officeCode,
      );
      switch (result.outcome) {
        case SubmitOutcome.alreadyActive:
          emit(const OnboardingAlreadyActive());
        case SubmitOutcome.submitted:
        case SubmitOutcome.pending:
          await _store.savePendingPhone(result.phone);
          _beginPolling(result.phone);
      }
    } catch (e) {
      emit(
        OnboardingForm(
          error: e.toString().replaceFirst('Exception: ', ''),
          offices: offices,
        ),
      );
    }
  }

  void _beginPolling(String phone) {
    emit(OnboardingPending(phone));
    _poll?.cancel();
    _check(phone);
    _poll = Timer.periodic(_pollInterval, (_) => _check(phone));
  }

  Future<void> refreshNow() async {
    final s = state;
    if (s is OnboardingPending) await _check(s.phone);
  }

  Future<void> _check(String phone) async {
    final data = await _getStatus(phone);
    if (isClosed || data == null) return;
    switch (data.status) {
      case RequestStatus.approved:
        _poll?.cancel();
        emit(
          OnboardingApproved(
            name: data.fullName,
            phone: data.phone,
            driverId: data.driverId ?? '',
            employeeCode: data.employeeCode,
          ),
        );
      case RequestStatus.rejected:
        _poll?.cancel();
        emit(OnboardingRejected(data.rejectionReason ?? 'لم يتم قبول طلبك.'));
      case RequestStatus.pending:
        break;
    }
  }

  Future<CaptainLocalSession> establishSession(OnboardingApproved a) async {
    final session = CaptainLocalSession(
      driverId: a.driverId,
      name: a.name,
      phone: a.phone,
      employeeCode: a.employeeCode,
    );
    await _store.saveSession(session);
    return session;
  }

  Future<void> discard() async {
    _poll?.cancel();
    await _store.clearPending();
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
