// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/widgets/switch_widget.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';

import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Navigation stack history
  final List<int> _viewHistory = [1];
  int _currentView = 1;

  // State Variables
  String _selectedLanguage = 'en'; // 'en' or 'ar'
  String _selectedTheme = 'system'; // 'system', 'light', 'dark'

  // Privacy States
  bool _allowLocation = true;
  bool _allowBackgroundLocation = false;
  bool _dataSharing = true;
  bool _personalizedRecommendations = true;
  String _profileVisibility = 'public'; // 'public' or 'private'

  // Security States
  bool _twoStepVerification = true;
  bool _biometricEnabled = false;
  bool _faceIdEnabled = false;
  bool _fingerprintEnabled = false;

  // Active Sessions
  List<Map<String, String>> _activeSessions = [];

  // Profile States
  String _userName = 'Ahmed Hassan';
  String _userEmail = 'ahmed.hassan@example.com';
  String _userPhone = '+20 10 1234 5678';

  // Notifications State Map
  Map<String, Map<String, bool>> _notificationsSettings = {};

  // FAQ Search & Accordion State
  String _faqSearch = '';
  final Set<String> _expandedFaqIds = {};

  // Terms & Conditions Search
  double _termsScrollProgress = 0.0;

  // FAQ Data List
  List<Map<String, String>> _faqs = [];

  // Table of Contents for Terms & Conditions
  List<Map<String, dynamic>> _termsTOC = [];

  bool _settingsDataApplied = false;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Navigation Logic
  void _navigateTo(int view) {
    setState(() {
      if (view == 3) {
        final host = ClientAppTheme.maybeOf(context);
        if (host != null) {
          _selectedTheme = ClientAppTheme.keyFromThemeMode(host.themeMode);
        }
      }
      _viewHistory.add(view);
      _currentView = view;
    });
  }

  void _navigateBack() {
    if (_viewHistory.length > 1) {
      setState(() {
        _viewHistory.removeLast();
        _currentView = _viewHistory.last;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getViewTitle() {
    return switch (_currentView) {
      1 => 'Settings & Preferences',
      2 => 'Language & Localization',
      3 => 'Appearance & Theme',
      4 => 'Privacy Center',
      5 => 'Security Center',
      6 => 'Active Sessions',
      7 => 'Biometric Authentication',
      8 => 'Notification Settings',
      9 => 'Support & Help Hub',
      10 => 'Frequently Asked Questions',
      11 => 'Terms & Conditions',
      12 => 'Privacy Policy',
      13 => 'Contact Customer Care',
      14 => 'About Mega Commute',
      15 => 'Application Version',
      _ => 'Settings',
    };
  }

  // Simulated Actions
  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applySettingsData(SettingsLoaded state) {
    if (_settingsDataApplied) return;

    final data = state.data;
    _selectedLanguage = data.selectedLanguage;
    _selectedTheme = data.selectedTheme;
    _userName = data.userName;
    _userEmail = data.userEmail;
    _userPhone = data.userPhone;
    _activeSessions = data.activeSessions
        .map((session) => Map<String, String>.from(session))
        .toList();
    _notificationsSettings = data.notificationsSettings.map(
      (key, value) => MapEntry(key, Map<String, bool>.from(value)),
    );
    _faqs = data.faqs.map((faq) => Map<String, String>.from(faq)).toList();
    _termsTOC = data.termsTableOfContents
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _settingsDataApplied = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoaded) {
          _applySettingsData(state);
        }

        if (state is SettingsError && !_settingsDataApplied) {
          return Scaffold(
            backgroundColor: ClientColors.surfaceMutedFor(context),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (!_settingsDataApplied) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            if (_viewHistory.length > 1) {
              _navigateBack();
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: ClientColors.surfaceMutedFor(context),
            appBar: AppBar(
              title: Text(
                _getViewTitle(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              leading: IconButton(
                onPressed: _navigateBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              elevation: 0,
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildCurrentView(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(BuildContext context) {
    return switch (_currentView) {
      1 => _buildHomeSettingsView(context),
      2 => _buildLanguageSettingsView(context),
      3 => _buildAppearanceSettingsView(context),
      4 => _buildPrivacySettingsView(context),
      5 => _buildSecurityCenterView(context),
      6 => _buildActiveSessionsView(context),
      7 => _buildBiometricLoginView(context),
      8 => _buildNotificationSettingsView(context),
      9 => _buildSupportHubView(context),
      10 => _buildFAQView(context),
      11 => _buildTermsView(context),
      12 => _buildPrivacyPolicyView(context),
      13 => _buildContactUsView(context),
      14 => _buildAboutAppView(context),
      15 => _buildAppVersionView(context),
      _ => const SizedBox.shrink(),
    };
  }

  // --- SCREEN 1: SETTINGS HOME SCREEN ---
  Widget _buildHomeSettingsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // User Profile Header
    //    _buildProfileHeaderCard(context),
      //  const SizedBox(height: 18),

        // Quick Actions
        _buildProfileQuickActionsRow(context),
        const SizedBox(height: 24),

        // Settings Groups
        const Text(
          'GENERAL PREFERENCES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.language_rounded,
                title: 'Language & Localization',
                subtitle: _selectedLanguage == 'en'
                    ? 'English (Save Option)'
                    : 'العربية (خيار الحفظ)',
                onTap: () => _navigateTo(2),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'Appearance & Theme',
                subtitle: _selectedTheme == 'dark'
                    ? 'Dark Mode Active'
                    : (_selectedTheme == 'light'
                          ? 'Light Mode Active'
                          : 'System Default'),
                onTap: () => _navigateTo(3),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'PRIVACY & PERMISSIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Center & Data',
                subtitle: 'Manage sharing and location tracking',
                onTap: () => _navigateTo(4),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'SECURITY & SESSIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.shield_rounded,
                title: 'Security Center',
                subtitle: 'Two-step check and device protection',
                onTap: () => _navigateTo(5),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.devices_rounded,
                title: 'Active Sessions',
                subtitle:
                    '${_activeSessions.length} connected device authorizations',
                onTap: () => _navigateTo(6),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'COMMUNICATION ALERTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notification Settings',
                subtitle: 'Customize push, SMS, and email alerts',
                onTap: () => _navigateTo(8),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'SUPPORT & LEGAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.help_center_rounded,
                title: 'Support & Help Hub',
                subtitle: 'Live Chat, FAQ, and Ticket submissions',
                onTap: () => _navigateTo(9),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.description_rounded,
                title: 'Terms & Conditions',
                subtitle: 'Usage guidelines and legal agreement',
                onTap: () => _navigateTo(11),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.policy_rounded,
                title: 'Privacy Policy',
                subtitle: 'How we collect and utilize your data',
                onTap: () => _navigateTo(12),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'APP SPECIFICS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Application',
                subtitle: 'Mega Commute mission and user stats',
                onTap: () => _navigateTo(14),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.system_update_rounded,
                title: 'App Version & Release Notes',
                subtitle: 'v2.4.0 (Latest update changelogs)',
                onTap: () => _navigateTo(15),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Logout Danger Button
        ClientButton.secondary(
          label: 'Log Out of Account',
          expand: true,
          onPressed: () => _showLogoutConfirmationDialog(context),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
/*
  Widget _buildProfileHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ClientColors.primary, ClientColors.journeyGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: ClientColors.primaryLight,
            child: Text(
              _userName.split(' ').map((e) => e[0]).join(),
              style: const TextStyle(color: ClientColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Gold Commuter',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildProfileQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.edit_note_rounded,
            label: 'Edit Profile',
            color: Colors.teal,
            onTap: () => _showEditProfileBottomSheet(context),
            context: context,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.card_membership_rounded,
            label: 'Subscription',
            color: Colors.indigo,
            onTap: () => Navigator.of(context).pushNamed('/subscription'),
            context: context,
          ),
        ),
    /*    const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.card_giftcard_rounded,
            label: 'Rewards',
            color: Colors.orange,
            onTap: () => Navigator.of(context).pushNamed('/rewards'),
            context: context,
          ),
        ),
        */
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: ClientColors.primary.withAlpha(24),
        child: Icon(icon, color: ClientColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Colors.grey,
      ),
    );
  }

  // --- SCREEN 2: LANGUAGE SETTINGS SCREEN ---
  Widget _buildLanguageSettingsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Select your preferred application language. The language affects trip notifications, search results, and navigation layouts.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        // English option
        _buildLanguageOptionCard(
          langCode: 'en',
          title: 'English',
          nativeName: 'English (US)',
          context: context,
        ),
        const SizedBox(height: 12),

        // Arabic option
        _buildLanguageOptionCard(
          langCode: 'ar',
          title: 'Arabic',
          nativeName: 'العربية (EG)',
          context: context,
        ),
        const SizedBox(height: 30),

        // Translated Preview area
        const Text(
          'PREVIEW TRANSLATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedLanguage == 'en'
                        ? 'Mega Commute Portal'
                        : 'بوابة ميجا للتنقل',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ClientColors.surfaceMutedFor(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: ClientColors.borderFor(context)),
                    ),
                    child: Text(
                      _selectedLanguage == 'en'
                          ? 'English translation'
                          : 'مترجم للعربية',
                      style: ClientTypography.labelSmall(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _selectedLanguage == 'en'
                    ? 'Flexible commutes made simpler. Tap to release your reserved seat or book daily luxury shuttle trips in seconds.'
                    : 'التنقلات المرنة أصبحت أكثر بساطة. اضغط لتحرير مقعدك المحجوز أو احجز رحلات مكوكية فاخرة يومية في ثوانٍ.',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Actions
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _navigateBack,
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ClientButton(
                label: 'Save Language',
                expand: true,
                onPressed: () {
                  _showSuccessSnack(
                    'Language updated to ${_selectedLanguage == 'en' ? 'English' : 'Arabic'} successfully!',
                  );
                  _navigateBack();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageOptionCard({
    required String langCode,
    required String title,
    required String nativeName,
    required BuildContext context,
  }) {
    final isSelected = _selectedLanguage == langCode;
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = langCode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? ClientColors.primary : ClientColors.borderFor(context),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isSelected
                        ? ClientColors.primary.withAlpha(24)
                        : Colors.grey.withAlpha(24),
                    child: Text(
                      langCode.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? ClientColors.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nativeName,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Radio<String>(
                value: langCode,
                groupValue: _selectedLanguage,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
                activeColor: ClientColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SCREEN 3: APPEARANCE SETTINGS SCREEN ---
  Widget _buildAppearanceSettingsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Choose the interface mode. Dark mode saves battery on OLED devices, while Light mode offers better contrast under direct sunlight.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Visual options grid
        Row(
          children: [
            Expanded(
              child: _buildThemeOptionCard(
                'system',
                'System',
                Icons.settings_brightness_rounded,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOptionCard(
                'light',
                'Light Mode',
                Icons.light_mode_rounded,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOptionCard(
                'dark',
                'Dark Mode',
                Icons.dark_mode_rounded,
                context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        const Text(
          'COMPONENT RENDERING PREVIEW',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),

        // Render preview mockups depending on select
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _selectedTheme == 'light' ? Colors.white : Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subtle Typography Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _selectedTheme == 'light'
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Secondary supporting preview text.',
                style: TextStyle(
                  fontSize: 10,
                  color: _selectedTheme == 'light'
                      ? Colors.grey[700]
                      : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              // Buttons mockup
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ClientColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Primary',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ClientColors.primary),
                      ),
                      child: Text(
                        'Outline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ClientColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cards mockup
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedTheme == 'light'
                      ? Colors.grey[100]
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      color: ClientColors.journeyGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _selectedTheme == 'light'
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _selectedTheme == 'light'
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        ClientButton(
          label: 'Apply Appearance Change',
          expand: true,
          onPressed: () {
            ClientAppTheme.maybeOf(
              context,
            )?.setThemeMode(ClientAppTheme.themeModeFromKey(_selectedTheme));
            _showSuccessSnack('Appearance theme applied successfully!');
            _navigateBack();
          },
        ),
      ],
    );
  }

  Widget _buildThemeOptionCard(
    String themeKey,
    String label,
    IconData icon,
    BuildContext context,
  ) {
    final isSelected = _selectedTheme == themeKey;
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _selectedTheme = themeKey),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? ClientColors.primary : ClientColors.borderFor(context),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? ClientColors.primary : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? ClientColors.primary : Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              CircleAvatar(
                radius: 8,
                backgroundColor: isSelected ? ClientColors.primary : Colors.transparent,
                child: isSelected
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SCREEN 4: PRIVACY SETTINGS SCREEN ---
  Widget _buildPrivacySettingsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Control how Mega Commute uses your device locations and visibility credentials.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        const Text(
          'LOCATION ACCESS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _buildPrivacyToggleCard(
          icon: Icons.my_location_rounded,
          title: 'Allow Location Access',
          description:
              'Required to locate close pickup hubs and trace real-time tracking navigation correctly.',
          value: _allowLocation,
          onChanged: (val) => setState(() => _allowLocation = val),
          context: context,
        ),
        const SizedBox(height: 10),
        _buildPrivacyToggleCard(
          icon: Icons.explore_rounded,
          title: 'Allow Background Location',
          description:
              'Tracks vehicle distance relative to your position even when app is closed to trigger delay updates.',
          value: _allowBackgroundLocation,
          onChanged: (val) => setState(() => _allowBackgroundLocation = val),
          context: context,
        ),
        const SizedBox(height: 20),

        const Text(
          'ACCOUNT VISIBILITY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildVisibilityRadioTile(
                value: 'public',
                title: 'Public Profile Visibility',
                description:
                    'Other subscribers sharing the same vehicle can view your avatar name in group logs.',
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildVisibilityRadioTile(
                value: 'private',
                title: 'Private Profile Visibility',
                description:
                    'Stops other passengers from viewing your profile details. Recommended for complete anonymity.',
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'DATA SHARING & MARKETING',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _buildPrivacyToggleCard(
          icon: Icons.analytics_outlined,
          title: 'Share Usage Analytics',
          description:
              'Help us improve by sending anonymous logs of performance and interface interactions.',
          value: _dataSharing,
          onChanged: (val) => setState(() => _dataSharing = val),
          context: context,
        ),
        const SizedBox(height: 10),
        _buildPrivacyToggleCard(
          icon: Icons.recommend_rounded,
          title: 'Personalized Recommendations',
          description:
              'Get relevant discount promos, package offers, and custom loyalty tiers notifications.',
          value: _personalizedRecommendations,
          onChanged: (val) =>
              setState(() => _personalizedRecommendations = val),
          context: context,
        ),
        const SizedBox(height: 30),

        ClientButton(
          label: 'Save Privacy Settings',
          expand: true,
          onPressed: () {
            _showSuccessSnack('Privacy preferences saved successfully!');
            _navigateBack();
          },
        ),
      ],
    );
  }

  Widget _buildPrivacyToggleCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ClientColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildVisibilityRadioTile({
    required String value,
    required String title,
    required String description,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: () => setState(() => _profileVisibility = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: _profileVisibility,
              onChanged: (val) {
                if (val != null) setState(() => _profileVisibility = val);
              },
              activeColor: ClientColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 5: SECURITY CENTER SCREEN ---
  Widget _buildSecurityCenterView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Security score card
        _buildSecurityScoreCard(context),
        const SizedBox(height: 20),

        const Text(
          'SECURITY TILE ACTIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update credentials frequently',
                onTap: () => _showChangePasswordDialog(context),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.phone_android_rounded,
                title: 'Change Phone Number',
                subtitle: 'Active: $_userPhone',
                onTap: () => _showChangePhoneDialog(context),
                context: context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildSettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Access Settings',
                subtitle: _biometricEnabled
                    ? 'Enabled (Face ID / Touch ID)'
                    : 'Disabled',
                onTap: () => _navigateTo(7),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'SECURITY VERIFICATIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _buildPrivacyToggleCard(
          icon: Icons.phonelink_ring_rounded,
          title: 'Two-Step Verification (2FA)',
          description:
              'Require SMS OTP confirmation whenever logging in from a new unrecognized device.',
          value: _twoStepVerification,
          onChanged: (val) => setState(() => _twoStepVerification = val),
          context: context,
        ),
        const SizedBox(height: 20),

        ClientButton.secondary(
          label: 'View Connected Sessions',
          expand: true,
          onPressed: () => _navigateTo(6),
        ),
      ],
    );
  }

  Widget _buildSecurityScoreCard(BuildContext context) {
    // 90% logic score
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          // Circular Canvas representation
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: 0.9,
                    strokeWidth: 8,
                    backgroundColor: ClientColors.borderFor(context),
                    valueColor: const AlwaysStoppedAnimation(
                      Colors.greenAccent,
                    ),
                  ),
                ),
                const Text(
                  '90%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'High Protection Score',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your account security looks great. Turn on biometric locks to hit 100% protection.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  hintText: '••••••••',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: '••••••••',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: '••••••••',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ClientButton(
              label: 'Update',
              onPressed: () {
                if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                  return;
                }
                Navigator.pop(context);
                _showSuccessSnack('Password updated successfully!');
              },
            ),
          ],
        );
      },
    );
  }

  void _showChangePhoneDialog(BuildContext context) {
    final phoneCtrl = TextEditingController(text: _userPhone);
    int step = 1; // 1 = input phone, 2 = input OTP

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                step == 1 ? 'Change Phone Number' : 'Verify SMS Code',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: step == 1
                  ? TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'New Phone Number',
                        prefixText: '',
                      ),
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter the 4-digit code sent to your new phone number.',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _OtpBox(),
                            _OtpBox(),
                            _OtpBox(),
                            _OtpBox(),
                          ],
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ClientButton(
                  label: step == 1 ? 'Send OTP' : 'Verify & Save',
                  onPressed: () {
                    if (step == 1) {
                      setDialogState(() => step = 2);
                    } else {
                      setState(() => _userPhone = phoneCtrl.text);
                      Navigator.pop(context);
                      _showSuccessSnack(
                        'Phone number verified and updated successfully!',
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- SCREEN 6: ACTIVE SESSIONS SCREEN ---
  Widget _buildActiveSessionsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'These devices are currently authorized to access your Mega Commute account. Revoke access from any devices you do not recognize.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Sessions list
        ..._activeSessions.map((session) {
          final isCurrent = session['current'] == 'true';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent
                    ? ClientColors.primary.withAlpha(140)
                    : ClientColors.borderFor(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isCurrent
                          ? ClientColors.primary.withAlpha(24)
                          : Colors.grey.withAlpha(24),
                      child: Icon(
                        session['device']!.contains('MacBook') ||
                                session['device']!.contains('Windows')
                            ? Icons.laptop_mac_rounded
                            : Icons.phone_iphone_rounded,
                        color: isCurrent ? ClientColors.primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['device']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session['platform']} • ${session['time']}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _activeSessions.removeWhere(
                          (s) => s['id'] == session['id'],
                        );
                      });
                      _showSuccessSnack('Session terminated successfully.');
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    tooltip: 'Revoke access',
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 30),

        if (_activeSessions.length > 1)
          ClientButton.secondary(
            label: 'Logout of All Other Devices',
            expand: true,
            onPressed: () {
              setState(() {
                _activeSessions.removeWhere((s) => s['current'] != 'true');
              });
              _showSuccessSnack(
                'Logged out of all other devices successfully.',
              );
            },
          ),
      ],
    );
  }

  // --- SCREEN 7: BIOMETRIC LOGIN SCREEN ---
  Widget _buildBiometricLoginView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.fingerprint_rounded,
          size: 60,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 20),
        const Text(
          'Biometric Credentials Security',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Enable Face ID or Fingerprint authentication to unlock your app securely without needing to type your password every session.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.face_retouching_natural_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Enable Face ID Access',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSwitch(
                    value: _faceIdEnabled,
                    onChanged: (val) {
                      setState(() {
                        _faceIdEnabled = val;
                        _biometricEnabled =
                            _faceIdEnabled || _fingerprintEnabled;
                      });
                      _showSuccessSnack(
                        val
                            ? 'Face ID authorization enabled.'
                            : 'Face ID authorization disabled.',
                      );
                    },
                  ),
                ],
              ),
              Divider(color: ClientColors.borderFor(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Enable Fingerprint Access',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSwitch(
                    value: _fingerprintEnabled,
                    onChanged: (val) {
                      setState(() {
                        _fingerprintEnabled = val;
                        _biometricEnabled =
                            _faceIdEnabled || _fingerprintEnabled;
                      });
                      _showSuccessSnack(
                        val
                            ? 'Fingerprint authentication enabled.'
                            : 'Fingerprint authentication disabled.',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        // Explanatory note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withAlpha(60)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blueAccent,
                size: 16,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mega Commute never transfers or stores your biometric records. Authentication is executed locally via device Hardware Keychains.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blueAccent,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SCREEN 8: NOTIFICATION SETTINGS SCREEN ---
  Widget _buildNotificationSettingsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Customize your notification alerts. Choose what updates you want to receive and on which communication channels.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        _buildNotificationChannelGroup(
          'TRIPS & RIDES',
          'trips',
          'Booking confirmations, reminders, and route delays.',
          context,
        ),
        const SizedBox(height: 18),
        _buildNotificationChannelGroup(
          'PAYMENT & BILLING',
          'payments',
          'Invoices, transaction updates, and cashback alerts.',
          context,
        ),
        const SizedBox(height: 18),
        _buildNotificationChannelGroup(
          'PACKAGES & SUBSCRIPTIONS',
          'packages',
          'Package renewal alerts and seat confirmations.',
          context,
        ),
        const SizedBox(height: 18),
        _buildNotificationChannelGroup(
          'OFFERS & REFERRALS',
          'promotions',
          'Discount codes, referral bonuses, and milestones.',
          context,
        ),
        const SizedBox(height: 18),
        _buildNotificationChannelGroup(
          'CUSTOMER SUPPORT',
          'support',
          'Support responses and live driver chat updates.',
          context,
        ),

        const SizedBox(height: 30),
        ClientButton(
          label: 'Save Notification Preferences',
          expand: true,
          onPressed: () {
            _showSuccessSnack(
              'Notification configurations updated successfully.',
            );
            _navigateBack();
          },
        ),
      ],
    );
  }

  Widget _buildNotificationChannelGroup(
    String label,
    String key,
    String description,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ClientColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNotificationToggle(
                'Push App',
                _notificationsSettings[key]!['push']!,
                (val) {
                  setState(() => _notificationsSettings[key]!['push'] = val);
                },
              ),
              _buildNotificationToggle(
                'SMS text',
                _notificationsSettings[key]!['sms']!,
                (val) {
                  setState(() => _notificationsSettings[key]!['sms'] = val);
                },
              ),
              _buildNotificationToggle(
                'Email',
                _notificationsSettings[key]!['email']!,
                (val) {
                  setState(() => _notificationsSettings[key]!['email'] = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- SCREEN 9: SUPPORT HUB SCREEN ---
  Widget _buildSupportHubView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Welcome Support text
        const Text(
          'How can we assist you today? Search our knowledge base or open a ticket with our support representative.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        // FAQ accordion shortcut
        _buildSupportTile(
          icon: Icons.quiz_outlined,
          title: 'Frequently Asked Questions (FAQ)',
          description:
              'Search solutions to booking, refunds, and technical issues.',
          onTap: () => _navigateTo(10),
          context: context,
        ),
        const SizedBox(height: 12),

        // Live Chat triggers communication screen
        _buildSupportTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Start Live Support Chat',
          description:
              'Chat instantly with one of our desk agents in real-time.',
          onTap: () => Navigator.of(context).pushNamed('/communication'),
          context: context,
        ),
        const SizedBox(height: 12),

        // Submit Ticket screen
        _buildSupportTile(
          icon: Icons.assignment_late_outlined,
          title: 'Open Urgent Support Ticket',
          description:
              'Submit an issue ticket (driver, refund, or booking errors).',
          onTap: () => Navigator.of(context).pushNamed('/support'),
          context: context,
        ),
        const SizedBox(height: 12),

        // Contact details directly
        _buildSupportTile(
          icon: Icons.contact_phone_outlined,
          title: 'Contact Customer Support Care',
          description:
              'Get support phone hotlines, WhatsApp, and operating hours.',
          onTap: () => _navigateTo(13),
          context: context,
        ),
        const SizedBox(height: 24),

        const Text(
          'SEND FEEDBACK OR REPORT COMPLAINT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),

        // Feedback Text inputs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              const Text(
                'Send Us Your Feedback',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Share your suggestion or report a problem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClientButton(
                label: 'Submit Feedback',
                expand: true,
                onPressed: () {
                  _showSuccessSnack(
                    'Thank you! Your feedback has been received.',
                  );
                  _navigateBack();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ClientColors.primary.withAlpha(24),
                child: Icon(icon, color: ClientColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SCREEN 10: FAQ SCREEN ---
  Widget _buildFAQView(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      if (_faqSearch.isEmpty) return true;
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final s = _faqSearch.toLowerCase();
      return q.contains(s) || a.contains(s);
    }).toList();

    return Column(
      children: [
        // Search bar area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _faqSearch = val),
            decoration: InputDecoration(
              hintText: 'Search FAQ questions...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _faqSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _faqSearch = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        Expanded(
          child: filteredFaqs.isEmpty
              ? Center(
                  child: ClientErrorCard.fullScreen(
                    message:
                        'No FAQ matches found\nTry searching other keywords like booking, payments, or wallets.',
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, idx) {
                    final faq = filteredFaqs[idx];
                    final isExpanded = _expandedFaqIds.contains(faq['id']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ClientColors.surfaceFor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ClientColors.borderFor(context)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedFaqIds.remove(faq['id']);
                                } else {
                                  _expandedFaqIds.add(faq['id']!);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ClientColors.journeyGreen.withAlpha(24),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    faq['category']!,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: ClientColors.journeyGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                faq['question']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  const Divider(height: 12),
                                  Text(
                                    faq['answer']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- SCREEN 11: TERMS & CONDITIONS SCREEN ---
  Widget _buildTermsView(BuildContext context) {
    return Column(
      children: [
        // Horizontal scroll progress bar
        LinearProgressIndicator(
          value: _termsScrollProgress,
          backgroundColor: ClientColors.borderFor(context),
          valueColor: AlwaysStoppedAnimation(ClientColors.primary),
        ),

        // TOC list layout
        Container(
          height: 44,
          color: ClientColors.surfaceFor(context),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _termsTOC.length,
            itemBuilder: (context, idx) {
              final toc = _termsTOC[idx];
              final isCurrent =
                  _termsScrollProgress >= (toc['progress'] - 0.1) &&
                  _termsScrollProgress <= (toc['progress'] + 0.15);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: ChoiceChip(
                  label: Text(
                    toc['title'],
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: isCurrent,
                  onSelected: (selected) {
                    setState(() {
                      _termsScrollProgress = toc['progress'];
                    });
                  },
                ),
              );
            },
          ),
        ),

        // Terms details
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scroll) {
              if (scroll.metrics.maxScrollExtent > 0) {
                setState(() {
                  _termsScrollProgress =
                      scroll.metrics.pixels / scroll.metrics.maxScrollExtent;
                });
              }
              return true;
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'TERMS OF SERVICE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Last updated: June 3, 2026',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const Divider(height: 24),

                const Text(
                  '1. Introduction',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome to Mega Commute. By subscribing to or utilizing our transportation platform and package booking options, you represent that you have read, understood, and agreed to these Terms of Service. If you do not accept these rules, please stop using our services.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  '2. User Accounts & Registration',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You must create a verified account by providing a valid phone number and full name. You are solely responsible for all actions taken on your account. If you suspect any security breaches or session hijackings, contact support care immediately.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  '3. Subscription Packages & Billing',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Subscribers can choose weekly, monthly, or quarterly packages. Package bookings guarantee reserved seats on chosen routes. All payments are billed upfront. Subscriptions are non-refundable but allow flexible seat releases.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  '4. Seat Release & Cancellation Policy',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Seats can be released at least 12 hours before trip departure times. If a released seat gets rebooked by a third-party passenger, you receive compensation wallet credits or points. Late releases (under 12 hours) are subject to partial or full forfeiture.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  '5. Fair Use & Code of Conduct',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mega Commute enforces a zero-tolerance policy against misconduct, harassment, or damage to luxury shuttle interiors. Drivers hold authority to drop passengers violating safety conduct without refund options.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SCREEN 12: PRIVACY POLICY SCREEN ---
  Widget _buildPrivacyPolicyView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'PRIVACY CHARTER & DATA CHARTERS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Last updated: June 3, 2026',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const Divider(height: 24),

        _buildPolicySectionCard(
          icon: Icons.analytics_rounded,
          title: 'Data Collection',
          content:
              'We collect phone numbers, profile names, payment transaction metadata, and live device geo-coordinates during rides to offer route tracking and secure payouts verification.',
          context: context,
        ),
        const SizedBox(height: 12),

        _buildPolicySectionCard(
          icon: Icons.tune_rounded,
          title: 'Data Usage',
          content:
              'We use your telemetry data to map optimal shuttles pathways, identify high utilization routes, verify package billing validity, and distribute seat release compensations instantly.',
          context: context,
        ),
        const SizedBox(height: 12),

        _buildPolicySectionCard(
          icon: Icons.lock_person_rounded,
          title: 'Security Measures',
          content:
              'Account files, passwords, and sessions are encrypted using industry-standard TLS protocols. Offline telemetry logs are anonymized and stored inside secure clouds keys.',
          context: context,
        ),
        const SizedBox(height: 12),

        _buildPolicySectionCard(
          icon: Icons.badge_rounded,
          title: 'User Rights',
          content:
              'You retain the right to download a copy of all shared usage logs, request immediate data anonymization, or permanently delete your account visages from Settings hub.',
          context: context,
        ),
      ],
    );
  }

  Widget _buildPolicySectionCard({
    required IconData icon,
    required String title,
    required String content,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ClientColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 13: CONTACT US SCREEN ---
  Widget _buildContactUsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Our customer success agents are available around the clock. Contact us using any of the communication channels listed below.',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              _buildContactDetailItem(
                Icons.headset_mic_rounded,
                'Hotline Support',
                '19876 (24/7 Toll Free)',
                context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildContactDetailItem(
                Icons.email_outlined,
                'Email Support',
                'support@megacommute.com',
                context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildContactDetailItem(
                Icons.chat_outlined,
                'WhatsApp Chatbot',
                '+20 10 9988 7766',
                context,
              ),
              Divider(color: ClientColors.borderFor(context)),
              _buildContactDetailItem(
                Icons.schedule_rounded,
                'Support Hours',
                'Daily: 6:00 AM - 12:00 AM',
                context,
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        ClientButton(
          label: 'Call Support Hotline',
          expand: true,
          onPressed: () => _simulateCall(context),
        ),
        const SizedBox(height: 10),
        ClientButton.secondary(
          label: 'Start WhatsApp Chat',
          expand: true,
          onPressed: () {
            _showSuccessSnack('Opening WhatsApp chat portal...');
          },
        ),
      ],
    );
  }

  Widget _buildContactDetailItem(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: ClientColors.primary, size: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _simulateCall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Calling Support Care...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dialing 19876...',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ClientButton(
                label: 'Hang Up',
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SCREEN 14: ABOUT APPLICATION SCREEN ---
  Widget _buildAboutAppView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // App branding logo
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ClientColors.primary, ClientColors.journeyGreen],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Mega Commute Client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 2.4.0 (Build 8204)',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        const Text(
          'YOUR COMMUTE IN METRICS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        // Stats grid
        Row(
          children: [
            Expanded(
              child: _buildMetricMiniCard(
                'Total Trips',
                '148',
                Icons.directions_bus_rounded,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricMiniCard(
                'Active Tier',
                'Gold Level',
                Icons.stars_rounded,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricMiniCard(
                'Subscriber',
                '2 Years',
                Icons.history_toggle_off_rounded,
                context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text(
          'COMPANY INFORMATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mega Transport Solutions LLC',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Our mission is to establish sustainable, comfortable, and intelligent corporate transportation pathways that solve daily commuting challenges in crowded cities.',
                style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard(
    String label,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: ClientColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- SCREEN 15: APP VERSION SCREEN ---
  Widget _buildAppVersionView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Update Card status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withAlpha(60)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 30,
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application is Up-to-Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Active: v2.4.0 (Latest version)',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'RELEASE NOTES HISTORY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),

        _buildReleaseLogItem('Version 2.4.0', 'June 2026', [
          'Added complete Seat Release Management Module.',
          'Stateful timelines and fintech rebooking trackers.',
          'Subtle micro-animations and confetti celebrations.',
        ], context),
        const SizedBox(height: 14),
        _buildReleaseLogItem('Version 2.3.0', 'May 2026', [
          'Enhanced Live Trip Tracking widgets.',
          'Integrated custom map layouts with moving shuttle icons.',
          'Introduced Loyalty level progressions and perks.',
        ], context),

        const SizedBox(height: 30),
        ClientButton(
          label: 'Force Update Checks',
          expand: true,
          onPressed: () {
            _showSuccessSnack(
              'Checking servers... You already have the latest build.',
            );
          },
        ),
      ],
    );
  }

  Widget _buildReleaseLogItem(
    String version,
    String date,
    List<String> notes,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                version,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 16),
          ...notes.map((n) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: ClientColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      n,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- LOGOUT FLOW DIALOG ---
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirm Logout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of your Mega Commute account? You will need to verify your phone number to sign back in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClientButton(
                      label: 'Log Out',
                      expand: true,
                      onPressed: () {
                        Navigator.pop(context);
                        // Redirect to welcome screen route
                        Navigator.of(context).pushReplacementNamed('/welcome');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- EDIT PROFILE SHEET ---
  void _showEditProfileBottomSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    final phoneCtrl = TextEditingController(text: _userPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: ClientColors.surfaceMutedFor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Profile Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClientButton(
                      label: 'Save Changes',
                      expand: true,
                      onPressed: () {
                        setState(() {
                          _userName = nameCtrl.text;
                          _userEmail = emailCtrl.text;
                          _userPhone = phoneCtrl.text;
                        });
                        Navigator.pop(context);
                        _showSuccessSnack(
                          'Profile details updated successfully.',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom simple widgets for changing credentials
class _OtpBox extends StatelessWidget {
  const _OtpBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[700]!),
      ),
      alignment: Alignment.center,
      child: const Text(
        '•',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
