import '../../domain/entities/check_in_result.dart';

sealed class CheckInState {
  const CheckInState();
}

class CheckInReady extends CheckInState {
  const CheckInReady({this.result});

  final CheckInResult? result;
}

class CheckInLoading extends CheckInState {
  const CheckInLoading();
}

class CheckInError extends CheckInState {
  const CheckInError(this.message);

  final String message;
}
