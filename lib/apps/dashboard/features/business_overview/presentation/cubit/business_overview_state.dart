import '../../domain/entities/business_overview.dart';

sealed class BusinessOverviewState {
  const BusinessOverviewState();
}

class BusinessOverviewLoading extends BusinessOverviewState {
  const BusinessOverviewLoading();
}

class BusinessOverviewLoaded extends BusinessOverviewState {
  final BusinessOverview overview;

  /// True while a refresh is in flight over an already-loaded page.
  ///
  /// The owner keeps the numbers they were reading and gets a progress line
  /// instead of a spinner over an empty screen — the same reason the modules
  /// keep their loaded state through a failed action.
  final bool isRefreshing;

  const BusinessOverviewLoaded(this.overview, {this.isRefreshing = false});
}

/// Only reached when **every** feed failed — a signed-out session, a dead
/// network. A single module failing degrades its section instead, and is
/// reported through [BusinessOverview.unavailable].
class BusinessOverviewError extends BusinessOverviewState {
  final String message;

  const BusinessOverviewError(this.message);
}
