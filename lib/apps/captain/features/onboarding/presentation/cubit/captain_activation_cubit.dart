import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/exceptions/captain_auth_exceptions.dart';
import '../../../auth/domain/usecases/sign_in_captain_usecase.dart';
import 'captain_activation_state.dart';

class CaptainActivationCubit extends Cubit<CaptainActivationState> {
  CaptainActivationCubit({required SignInCaptainUseCase signIn})
    : _signIn = signIn,
      super(const CaptainActivationChecking());

  final SignInCaptainUseCase _signIn;

  static const _pollInterval = Duration(seconds: 20);

  Timer? _poll;
  bool _inFlight = false;

  void start(String phone) {
    check(phone);
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => check(phone, silent: true));
  }

  Future<void> check(String phone, {bool silent = false}) async {
    if (_inFlight || isClosed) return;
    _inFlight = true;
    if (!silent) emit(const CaptainActivationChecking());
    try {
      await _signIn(phone: phone);
      _poll?.cancel();
      if (!isClosed) emit(const CaptainActivationActivated());
    } on CaptainPhoneNotRegisteredException {
      if (!isClosed) emit(const CaptainActivationAwaiting());
    } catch (error) {
      if (!isClosed) {
        emit(
          CaptainActivationFailed(
            error.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
          ),
        );
      }
    } finally {
      _inFlight = false;
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
