import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.phone,
    super.fullName,
    super.email,
    super.gender,
    super.preferredPickupArea,
    super.isProfileComplete,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      preferredPickupArea: json['preferred_pickup_area'] as String?,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'email': email,
      'gender': gender,
      'preferred_pickup_area': preferredPickupArea,
      'is_profile_complete': isProfileComplete,
    };
  }
}
