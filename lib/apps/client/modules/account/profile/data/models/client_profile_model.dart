import '../../domain/entities/client_profile.dart';

class ClientProfileModel {
  const ClientProfileModel({
    required this.initials,
    required this.name,
    required this.email,
    required this.badge,
  });

  final String initials;
  final String name;
  final String email;
  final String badge;

  ClientProfile toEntity() {
    return ClientProfile(
      initials: initials,
      name: name,
      email: email,
      badge: badge,
    );
  }
}

class ProfileMenuItemModel {
  const ProfileMenuItemModel({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    this.route,
  });

  final String iconKey;
  final String title;
  final String subtitle;
  final String? route;

  ProfileMenuItem toEntity() {
    return ProfileMenuItem(
      iconKey: iconKey,
      title: title,
      subtitle: subtitle,
      route: route,
    );
  }
}

class ProfileMenuSectionModel {
  const ProfileMenuSectionModel({required this.title, required this.items});

  final String title;
  final List<ProfileMenuItemModel> items;

  ProfileMenuSection toEntity() {
    return ProfileMenuSection(
      title: title,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

class ClientProfileDataModel {
  const ClientProfileDataModel({required this.profile, required this.sections});

  final ClientProfileModel profile;
  final List<ProfileMenuSectionModel> sections;

  ClientProfileData toEntity() {
    return ClientProfileData(
      profile: profile.toEntity(),
      sections: sections.map((section) => section.toEntity()).toList(),
    );
  }
}
