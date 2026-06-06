class SettingsData {
  const SettingsData({
    required this.selectedLanguage,
    required this.selectedTheme,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.activeSessions,
    required this.notificationsSettings,
    required this.faqs,
    required this.termsTableOfContents,
  });

  final String selectedLanguage;
  final String selectedTheme;
  final String userName;
  final String userEmail;
  final String userPhone;
  final List<Map<String, String>> activeSessions;
  final Map<String, Map<String, bool>> notificationsSettings;
  final List<Map<String, String>> faqs;
  final List<Map<String, dynamic>> termsTableOfContents;
}
