import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_profile_model.dart';
import 'profile_datasource.dart';

class SupabaseProfileDatasource implements ProfileDatasource {
  final SupabaseClient _supabase;

  const SupabaseProfileDatasource(this._supabase);

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Future<ClientProfileDataModel> getProfileData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final response = await _supabase
        .from('clients')
        .select()
        .eq('id', user.id)
        .limit(1)
        .maybeSingle();

    final name = response?['full_name']?.toString() ?? 'Unknown User';
    final email = response?['email']?.toString() ?? user.email ?? 'No email';
    final initials = _getInitials(name);

    return ClientProfileDataModel(
      profile: ClientProfileModel(
        initials: initials,
        name: name,
        email: email,
        badge: 'Premium', // You can load this from subscriptions later
      ),
      sections: const [
        ProfileMenuSectionModel(
          title: 'Travel',
          items: [
            ProfileMenuItemModel(
              iconKey: 'trips',
              title: 'My trips',
              subtitle: 'Upcoming, active & history',
              route: '/trips',
            ),
          ],
        ),
        ProfileMenuSectionModel(
          title: 'Wallet & rewards',
          items: [
            ProfileMenuItemModel(
              iconKey: 'wallet',
              title: 'Wallet',
              subtitle: 'EGP 240.00 available',
              route: '/payment-demo',
            ),
            ProfileMenuItemModel(
              iconKey: 'rewards',
              title: 'Rewards',
              subtitle: '1,250 points · Refer friends',
              route: '/rewards',
            ),
            ProfileMenuItemModel(
              iconKey: 'loyalty',
              title: 'Loyalty',
              subtitle: 'Tier benefits & perks',
              route: '/loyalty',
            ),
          ],
        ),
        ProfileMenuSectionModel(
          title: 'Support',
          items: [
            ProfileMenuItemModel(
              iconKey: 'support',
              title: 'Help center',
              subtitle: 'FAQs, chat & tickets',
              route: '/support',
            ),
            ProfileMenuItemModel(
              iconKey: 'messages',
              title: 'Messages',
              subtitle: 'Driver & support chat',
              route: '/communication',
            ),
          ],
        ),
        ProfileMenuSectionModel(
          title: 'Settings & legal',
          items: [
            ProfileMenuItemModel(
              iconKey: 'settings',
              title: 'Settings',
              subtitle: 'Preferences & security',
              route: '/settings',
            ),
            ProfileMenuItemModel(
              iconKey: 'terms',
              title: 'Terms & privacy',
              subtitle: 'Legal information',
            ),
          ],
        ),
      ],
    );
  }
}
