import '../../domain/entities/client_profile.dart';

/// Maps the rows the profile hub reads — a `clients` row, the rider's active
/// `subscriptions` row, and their booking counts — onto [ClientProfile].
class ClientProfileModel {
  const ClientProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.memberSince,
    this.completedTrips = 0,
    this.upcomingTrips = 0,
    this.activePackage,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? memberSince;
  final int completedTrips;
  final int upcomingTrips;
  final ActivePackageModel? activePackage;

  /// [fallbackEmail] is the session's email: a `clients` row written by the
  /// backend trigger can carry a null email, and showing the rider nothing is
  /// worse than showing the address they signed in with.
  factory ClientProfileModel.fromRow(
    Map<String, dynamic>? row, {
    required String userId,
    String? fallbackEmail,
    Map<String, dynamic>? packageRow,
    int completedTrips = 0,
    int upcomingTrips = 0,
  }) {
    return ClientProfileModel(
      id: userId,
      name: row?['full_name']?.toString().trim() ?? '',
      email: row?['email']?.toString().trim() ?? fallbackEmail?.trim() ?? '',
      phone: row?['phone']?.toString().trim() ?? '',
      memberSince: DateTime.tryParse(row?['created_at']?.toString() ?? ''),
      completedTrips: completedTrips,
      upcomingTrips: upcomingTrips,
      activePackage: packageRow == null
          ? null
          : ActivePackageModel.fromRow(packageRow),
    );
  }

  ClientProfile toEntity() {
    return ClientProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      memberSince: memberSince,
      completedTrips: completedTrips,
      upcomingTrips: upcomingTrips,
      activePackage: activePackage?.toEntity(),
    );
  }
}

class ActivePackageModel {
  const ActivePackageModel({
    required this.name,
    required this.routeName,
    this.endDate,
  });

  final String name;
  final String routeName;
  final DateTime? endDate;

  factory ActivePackageModel.fromRow(Map<String, dynamic> row) {
    return ActivePackageModel(
      name: row['package_name']?.toString() ?? '',
      routeName: row['route_name']?.toString() ?? '',
      endDate: DateTime.tryParse(row['end_date']?.toString() ?? ''),
    );
  }

  ActivePackage toEntity() {
    return ActivePackage(name: name, routeName: routeName, endDate: endDate);
  }
}
