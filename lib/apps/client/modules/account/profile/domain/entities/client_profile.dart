class ClientProfile {
  const ClientProfile({
    required this.initials,
    required this.name,
    required this.email,
    required this.badge,
  });

  final String initials;
  final String name;
  final String email;
  final String badge;
}

class ProfileMenuItem {
  const ProfileMenuItem({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    this.route,
  });

  final String iconKey;
  final String title;
  final String subtitle;
  final String? route;
}

class ProfileMenuSection {
  const ProfileMenuSection({required this.title, required this.items});

  final String title;
  final List<ProfileMenuItem> items;
}

class ClientProfileData {
  const ClientProfileData({required this.profile, required this.sections});

  final ClientProfile profile;
  final List<ProfileMenuSection> sections;
}
