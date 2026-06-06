class ClientRegistration {
  const ClientRegistration({
    required this.fullName,
    required this.email,
    required this.phone,
    this.viaSocial,
  });

  final String fullName;
  final String email;
  final String phone;
  final String? viaSocial;
}
