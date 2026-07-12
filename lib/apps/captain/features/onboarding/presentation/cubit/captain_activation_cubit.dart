import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/exceptions/captain_auth_exceptions.dart';
import '../../../auth/domain/usecases/sign_in_captain_usecase.dart';
import 'captain_activation_state.dart';

/// Upgrades a self-service captain from their device-local session to a real
/// operational session.
///
/// After approval the captain only holds a local session, so no driver is bound
/// to an auth user and no assigned trips can ever load — previously the captain
/// had to sign out and sign back in once operations assigned them a trip. Here
/// we re-attempt the phone sign-in on open, on refresh and on a slow poll: the
/// moment their driver record is active, the session is established and the
/// auth gate swaps them into the operational shell.
class CaptainActivationCubit extends Cubit<CaptainActivationState> {
  CaptainActivationCubit({required SignInCaptainUseCase signIn})
    : _signIn = signIn,
      super(const CaptainActivationChecking());

  final SignInCaptainUseCase _signIn;

  static const _pollInterval = Duration(seconds: 20);

  Timer? _poll;
  bool _inFlight = false;

  /// Checks immediately, then keeps checking quietly in the background.
  void start(String phone) {
    check(phone);
    _poll?.cancel();
    _poll = Timer.periodic(
      _pollInterval,
      (_) => check(phone, silent: true),
    );
  }

  /// [silent] keeps the current state on screen while re-checking, so the
  /// background poll never flashes a loading state at the captain.
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
