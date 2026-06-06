import '../../domain/entities/otp_request.dart';

class OtpRequestModel {
  const OtpRequestModel({required this.formattedPhone});

  final String formattedPhone;

  OtpRequest toEntity() {
    return OtpRequest(formattedPhone: formattedPhone);
  }
}
