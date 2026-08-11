import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../../domain/entities/station_action_failure.dart';

/// One state class rather than a union: the board is the screen, and it is
/// present for every state the screen can be in. Loading and submitting are
/// things happening *to* the board, not alternatives to it — modelling them as
/// separate states would mean either losing the stations while an action is in
/// flight or carrying a copy of them in every branch.
class StationProgressState {
  const StationProgressState({
    this.board = const StationBoard.empty(),
    this.isLoading = true,
    this.isSubmitting = false,
    this.failure,
  });

  final StationBoard board;

  /// The first read has not landed. Distinct from an empty board, which is a
  /// real answer: this trip has no stations.
  final bool isLoading;

  /// A transition is in flight. The primary action locks, the board stays.
  final bool isSubmitting;

  /// The last refused transition, held until the captain acts again. Kept as the
  /// typed refusal rather than a rendered string so the widget layer decides how
  /// to word it.
  final StationActionException? failure;

  bool get hasBoard => board.isNotEmpty;

  StationProgressState copyWith({
    StationBoard? board,
    bool? isLoading,
    bool? isSubmitting,
    StationActionException? failure,
    bool clearFailure = false,
  }) {
    return StationProgressState(
      board: board ?? this.board,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
