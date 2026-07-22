/// Everything needed to stand up a new office and its first administrator.
///
/// Deliberately holds no `officeId`, no `role`, no `status` and no join code:
/// all four are decided by `platform_create_office`, never sent. A request
/// object that *could* carry them would be a request object someone eventually
/// populates.
class OfficeOnboardingRequest {
  const OfficeOnboardingRequest({
    required this.name,
    required this.adminUsername,
    this.slug = '',
    this.description = '',
    this.logoUrl = '',
    this.phone = '',
    this.email = '',
    this.serviceAreas = const [],
    this.adminFullName = '',
    this.adminPassword = '',
  });

  /// Trade name shown to clients in the marketplace directory.
  final String name;

  /// Latin public identifier, unique platform-wide. Optional: the RPC mints an
  /// opaque one when it is blank, because an Arabic office name cannot be
  /// transliterated into a slug we would want to be permanent.
  final String slug;

  final String description;
  final String logoUrl;
  final String phone;
  final String email;
  final List<String> serviceAreas;

  /// The first operator's dashboard login name — what they type into the
  /// existing Name + Password screen. Their synthetic login address is derived
  /// from it server-side; there is no separate email to choose.
  final String adminUsername;
  final String adminFullName;

  /// Blank means "generate one", and the generated value comes back exactly once
  /// in the response. Never stored, never logged, never retrievable later.
  final String adminPassword;

  static final _slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
  static final _usernamePattern = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$');

  /// Field-keyed validation errors, empty when the request is sendable.
  ///
  /// The same rules run again in the Edge Function and a third time inside the
  /// RPC. That is not redundancy for its own sake: the RPC is directly callable
  /// by any platform admin, so it cannot trust either layer above it, and this
  /// copy exists so the form can mark the offending field rather than show a
  /// server error with no anchor.
  Map<String, String> validate() {
    final errors = <String, String>{};

    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      errors['name'] = 'اسم المكتب مطلوب (3 أحرف على الأقل)';
    } else if (trimmedName.length > 120) {
      errors['name'] = 'اسم المكتب طويل جداً';
    }

    final trimmedSlug = slug.trim().toLowerCase();
    if (trimmedSlug.isNotEmpty &&
        (!_slugPattern.hasMatch(trimmedSlug) ||
            trimmedSlug.length < 3 ||
            trimmedSlug.length > 48)) {
      errors['slug'] = 'حروف إنجليزية صغيرة وأرقام وشرطات فقط';
    }

    if (description.trim().length > 500) {
      errors['description'] = 'الوصف طويل جداً (500 حرف كحد أقصى)';
    }

    final trimmedLogo = logoUrl.trim();
    if (trimmedLogo.isNotEmpty &&
        !trimmedLogo.toLowerCase().startsWith('https://')) {
      errors['logoUrl'] = 'يجب أن يبدأ الرابط بـ https://';
    }

    final trimmedPhone = phone.trim();
    if (trimmedPhone.isNotEmpty &&
        (trimmedPhone.length < 7 || trimmedPhone.length > 20)) {
      errors['phone'] = 'رقم هاتف غير صالح';
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty && !_emailPattern.hasMatch(trimmedEmail)) {
      errors['email'] = 'بريد إلكتروني غير صالح';
    }

    if (serviceAreas.length > 30) {
      errors['serviceAreas'] = 'عدد مناطق الخدمة كبير جداً';
    }

    final trimmedUsername = adminUsername.trim().toLowerCase();
    if (trimmedUsername.length < 3 || trimmedUsername.length > 32) {
      errors['adminUsername'] = 'اسم الدخول مطلوب (3 إلى 32 حرفاً)';
    } else if (!_usernamePattern.hasMatch(trimmedUsername)) {
      errors['adminUsername'] = 'حروف إنجليزية صغيرة وأرقام و . _ - فقط';
    }

    if (adminFullName.trim().length > 120) {
      errors['adminFullName'] = 'الاسم طويل جداً';
    }

    if (adminPassword.isNotEmpty && adminPassword.length < 10) {
      errors['adminPassword'] = 'كلمة المرور 10 أحرف على الأقل';
    }

    return errors;
  }

  /// The wire payload. Blank optionals are omitted rather than sent as empty
  /// strings so the server's "not provided" and "provided as empty" branches
  /// stay distinguishable.
  Map<String, dynamic> toPayload() {
    final areas = [
      for (final area in serviceAreas)
        if (area.trim().isNotEmpty) area.trim(),
    ];
    return {
      'name': name.trim(),
      'admin_username': adminUsername.trim().toLowerCase(),
      if (slug.trim().isNotEmpty) 'slug': slug.trim().toLowerCase(),
      if (description.trim().isNotEmpty) 'description': description.trim(),
      if (logoUrl.trim().isNotEmpty) 'logo_url': logoUrl.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (areas.isNotEmpty) 'service_areas': areas,
      if (adminFullName.trim().isNotEmpty)
        'admin_full_name': adminFullName.trim(),
      if (adminPassword.isNotEmpty) 'admin_password': adminPassword,
    };
  }
}

/// What onboarding returns — shown once, then unrecoverable.
///
/// [temporaryPassword] is null when the platform admin chose the password
/// themselves; the server does not echo a secret it was handed. [joinCode] and
/// the password are both one-time reveals: neither is readable again through any
/// platform surface.
class OfficeOnboardingResult {
  const OfficeOnboardingResult({
    required this.officeId,
    required this.officeName,
    required this.slug,
    required this.joinCode,
    required this.username,
    required this.listingStatus,
    this.temporaryPassword,
  });

  final String officeId;
  final String officeName;
  final String slug;
  final String joinCode;
  final String username;
  final String listingStatus;
  final String? temporaryPassword;

  bool get hasTemporaryPassword => (temporaryPassword ?? '').isNotEmpty;
}
