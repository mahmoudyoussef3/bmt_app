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
    if (user == null) throw Exception('User is not authenticated');

    // Fetch profile and loyalty account in parallel.
    final profileFuture = _supabase
        .from('clients')
        .select()
        .eq('id', user.id)
        .limit(1)
        .maybeSingle();
    final accountFuture = _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', user.id)
        .maybeSingle();

    final profileResponse = await profileFuture;
    final accountResponse = await accountFuture;

    final name =
        profileResponse?['full_name']?.toString() ?? 'Unknown User';
    final email =
        profileResponse?['email']?.toString() ?? user.email ?? 'No email';
    final initials = _getInitials(name);

    final points = accountResponse?['points'] as int? ?? 0;
    final walletBalance =
        accountResponse?['wallet_balance'] as int? ?? 0;

    final walletSubtitle = walletBalance > 0
        ? 'EGP $walletBalance.00 available'
        : 'View wallet & balance';

    final rewardsSubtitle = points > 0
        ? '$points points · Refer friends'
        : 'Earn points & refer friends';

    return ClientProfileDataModel(
      profile: ClientProfileModel(
        initials: initials,
        name: name,
        email: email,
        badge: 'Premium',
      ),
      sections: [
        const ProfileMenuSectionModel(
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
              subtitle: walletSubtitle,
              route: '/loyalty',
            ),
            ProfileMenuItemModel(
              iconKey: 'rewards',
              title: 'Rewards',
              subtitle: rewardsSubtitle,
              route: '/rewards',
            ),
            const ProfileMenuItemModel(
              iconKey: 'loyalty',
              title: 'Loyalty',
              subtitle: 'Tier benefits & perks',
              route: '/loyalty',
            ),
          ],
        ),
        const ProfileMenuSectionModel(
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
        const ProfileMenuSectionModel(
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
