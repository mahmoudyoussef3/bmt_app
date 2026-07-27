import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/repositories/communication_repository.dart';

sealed class CaptainNotificationState {
  const CaptainNotificationState();
}

class CaptainNotificationIdle extends CaptainNotificationState {
  const CaptainNotificationIdle();
}

class CaptainNotificationReceived extends CaptainNotificationState {
  final String message;
  const CaptainNotificationReceived(this.message);
}

class CaptainNotificationCubit extends Cubit<CaptainNotificationState> {
  CaptainNotificationCubit(this._repository)
    : super(const CaptainNotificationIdle());

  final CommunicationRepository _repository;
  StreamSubscription<OpsBroadcast>? _subscription;

  /// The id of the last broadcast this captain was shown.
  ///
  /// Identity, not text. Comparing bodies meant an operator sending the same
  /// instruction a second time — which usually means the first one was not
  /// acted on — was silently swallowed as a duplicate.
  String? _lastSeenId;

  /// The backing Supabase stream replays the newest matching row the moment it
  /// subscribes, before any live change arrives. Surfacing that first emission
  /// popped an operations broadcast at the captain on every single app launch —
  /// including one they had already read days earlier. The first emission is
  /// therefore taken as the baseline of "already seen" and only genuinely new
  /// traffic after it is announced.
  bool _primed = false;

  void startListening() {
    _subscription?.cancel();
    _primed = false;
    _subscription = _repository.watchIncomingOpsMessages().listen((broadcast) {
      if (broadcast.body.isEmpty) return;
      if (!_primed) {
        _primed = true;
        _lastSeenId = broadcast.id;
        return;
      }
      if (broadcast.id != _lastSeenId) {
        _lastSeenId = broadcast.id;
        emit(CaptainNotificationReceived(broadcast.body));
      }
    });
  }

  void clearNotification() => emit(const CaptainNotificationIdle());

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
