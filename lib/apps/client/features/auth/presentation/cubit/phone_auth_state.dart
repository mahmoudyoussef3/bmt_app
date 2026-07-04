import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

abstract class PhoneAuthState extends Equatable {
  const PhoneAuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends PhoneAuthState {}

class AuthLoading extends PhoneAuthState {}

class AuthPhoneSubmitted extends PhoneAuthState {
  final String phone;
  const AuthPhoneSubmitted(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends PhoneAuthState {
  final UserProfile user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthProfileIncomplete extends PhoneAuthState {
  final String phone;
  const AuthProfileIncomplete(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthError extends PhoneAuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
