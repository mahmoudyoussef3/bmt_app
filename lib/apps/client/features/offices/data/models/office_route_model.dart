import '../../domain/entities/office_route.dart';

class OfficeRouteModel extends OfficeRoute {
  const OfficeRouteModel({
    required super.id,
    required super.name,
    required super.startCity,
    required super.endCity,
  });

  factory OfficeRouteModel.fromJson(Map<String, dynamic> json) {
    return OfficeRouteModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      startCity: (json['start_city'] as String?) ?? '',
      endCity: (json['end_city'] as String?) ?? '',
    );
  }
}
