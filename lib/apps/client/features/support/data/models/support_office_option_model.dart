import '../../domain/entities/support_office_option.dart';

class SupportOfficeOptionModel extends SupportOfficeOption {
  const SupportOfficeOptionModel({required super.id, required super.name});

  factory SupportOfficeOptionModel.fromJson(Map<String, dynamic> json) {
    return SupportOfficeOptionModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
    );
  }
}
