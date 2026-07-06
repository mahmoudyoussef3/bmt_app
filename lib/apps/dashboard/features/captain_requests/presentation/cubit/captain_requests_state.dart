import '../../domain/entities/captain_request.dart';

sealed class CaptainRequestsState {
  const CaptainRequestsState();
}

class CaptainRequestsLoading extends CaptainRequestsState {
  const CaptainRequestsLoading();
}

class CaptainRequestsError extends CaptainRequestsState {
  final String message;
  const CaptainRequestsError(this.message);
}

class CaptainRequestsLoaded extends CaptainRequestsState {
  final List<CaptainRequest> requests;

  /// Non-fatal action feedback (e.g. approve/reject failure) surfaced without
  /// blanking the list.
  final String? actionError;

  const CaptainRequestsLoaded({required this.requests, this.actionError});

  List<CaptainRequest> get pending =>
      requests.where((r) => r.isPending).toList();
  int get pendingCount => pending.length;

  CaptainRequestsLoaded copyWith({
    List<CaptainRequest>? requests,
    String? actionError,
  }) {
    return CaptainRequestsLoaded(
      requests: requests ?? this.requests,
      actionError: actionError,
    );
  }
}
