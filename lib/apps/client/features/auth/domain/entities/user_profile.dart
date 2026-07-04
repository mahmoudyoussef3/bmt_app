import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String phone;
  final String? fullName;
  final String? email;
  final String? gender;
  final String? preferredPickupArea;
  final bool isProfileComplete;

  const UserProfile({
    required this.id,
    required this.phone,
    this.fullName,
    this.email,
    this.gender,
    this.preferredPickupArea,
    this.isProfileComplete = false,
  });

  @override
  List<Object?> get props => [
        id,
        phone,
        fullName,
        email,
        gender,
        preferredPickupArea,
        isProfileComplete,
      ];
}
