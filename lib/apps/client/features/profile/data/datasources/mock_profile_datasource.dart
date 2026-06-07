import '../models/client_profile_model.dart';

class MockProfileDatasource {
  const MockProfileDatasource();

  Future<ClientProfileDataModel> getProfileData() async {
    return const ClientProfileDataModel(
      profile: ClientProfileModel(
        initials: 'AH',
        name: 'Ahmed Hassan',
        email: 'ahmed.hassan@company.com',
        badge: 'Premium',
      ),
      sections: [
        /*
        ProfileMenuSectionModel(
          title: 'Account',
          items: [
            ProfileMenuItemModel(
              iconKey: 'person',
              title: 'Account details',
              subtitle: 'Employee ID · Operations',
            ),
          ],
        ),
        */
        ProfileMenuSectionModel(
          title: 'Travel',
          items: [
            ProfileMenuItemModel(
              iconKey: 'trips',
              title: 'My trips',
              subtitle: 'Upcoming, active & history',
              route: '/trips',
            ),
            /*
            ProfileMenuItemModel(
              iconKey: 'packages',
              title: 'Packages',
              subtitle: 'Monthly & weekly plans',
              route: '/subscription',
            ),


            ProfileMenuItemModel(
              iconKey: 'search',
              title: 'Book a route',
              subtitle: 'Search trips & vehicles',
              route: '/booking/search',
            ),

            */
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
