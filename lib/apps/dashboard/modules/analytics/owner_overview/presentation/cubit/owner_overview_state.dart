import '../../domain/entities/owner_overview.dart';

sealed class OwnerOverviewState {
  const OwnerOverviewState();
}

class OwnerOverviewLoading extends OwnerOverviewState {
  const OwnerOverviewLoading();
}

class OwnerOverviewError extends OwnerOverviewState {
  final String message;
  const OwnerOverviewError(this.message);
}

class OwnerOverviewLoaded extends OwnerOverviewState {
  final OwnerOverview overview;
  const OwnerOverviewLoaded(this.overview);
}
