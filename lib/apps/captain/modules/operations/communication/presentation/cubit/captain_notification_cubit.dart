import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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
  StreamSubscription<String>? _subscription;
  String? _lastSeen;

  void startListening() {
    _subscription?.cancel();
    _subscription = _repository.watchIncomingOpsMessages().listen((body) {
      if (body != _lastSeen && body.isNotEmpty) {
        _lastSeen = body;
        emit(CaptainNotificationReceived(body));
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
