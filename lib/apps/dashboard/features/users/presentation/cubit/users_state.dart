import '../../domain/entities/app_user.dart';
import '../../domain/entities/staff_account.dart';

sealed class UsersState {
  const UsersState();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  const UsersLoaded(
    this.users, {
    this.isSubmitting = false,
    this.fieldErrors = const {},
  });

  final List<AppUser> users;

  /// An account is being created or a password reset. The form disables itself and the
  /// list stays exactly where it was.
  final bool isSubmitting;

  /// Per-field validation errors from the last rejected submission, keyed the way
  /// [StaffAccountRequest.validate] keys them, so the form can mark the offending input
  /// rather than show one message with no anchor.
  final Map<String, String> fieldErrors;

  UsersLoaded copyWith({
    List<AppUser>? users,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
  }) => UsersLoaded(
    users ?? this.users,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    fieldErrors: fieldErrors ?? this.fieldErrors,
  );
}

/// The screen has no data — a failed load, not a failed action.
class UsersError extends UsersState {
  const UsersError(this.message);

  final String message;
}

/// A one-time credential reveal: a new account, or a reset password.
///
/// A distinct state rather than a flag on [UsersLoaded] because the screen has to
/// *hold* this until the owner dismisses it. The password exists in no log and no
/// table, so losing it to a rebuild would lose the only copy — the same reason
/// platform onboarding models its reveal this way.
class UsersCredentialsIssued extends UsersState {
  const UsersCredentialsIssued(this.credentials, this.users);

  final StaffCredentials credentials;
  final List<AppUser> users;
}

/// A one-frame success notice for the smaller actions (role change, disable, enable),
/// immediately followed by [UsersLoaded] — the same shape the platform_admin and
/// office_profile modules use, so listeners behave identically.
class UsersActionSuccess extends UsersState {
  const UsersActionSuccess(this.message, this.users);

  final String message;
  final List<AppUser> users;
}

/// A failed action that keeps the list — and whatever is typed into the form — on
/// screen. A refused role change must not blank out the directory behind it.
class UsersActionFailure extends UsersState {
  const UsersActionFailure(
    this.message,
    this.users, {
    this.fieldErrors = const {},
  });

  final String message;
  final List<AppUser> users;
  final Map<String, String> fieldErrors;
}
