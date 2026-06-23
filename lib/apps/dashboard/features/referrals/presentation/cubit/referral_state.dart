import '../../domain/entities/referral_dashboard_data.dart';

sealed class ReferralState {
  const ReferralState();
}

class ReferralInitial extends ReferralState {
  const ReferralInitial();
}

class ReferralLoading extends ReferralState {
  const ReferralLoading();
}

class ReferralError extends ReferralState {
  const ReferralError(this.message);
  final String message;
}

class ReferralLoaded extends ReferralState {
  const ReferralLoaded(this.data, {this.isSaving = false});
  final ReferralDashboardData data;
  final bool isSaving;

  ReferralLoaded copyWith({ReferralDashboardData? data, bool? isSaving}) =>
      ReferralLoaded(data ?? this.data, isSaving: isSaving ?? this.isSaving);
}

class ReferralActionSuccess extends ReferralState {
  const ReferralActionSuccess(this.message, this.data);
  final String message;
  final ReferralDashboardData data;
}
