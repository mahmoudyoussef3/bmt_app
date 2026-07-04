import 'package:flutter/material.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/theme/tokens.dart';

import '../routes/auth_routes.dart';
import '../widgets/social_login_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/bmt_welcome_bg.png',
            fit: BoxFit.cover,
          ),
          
          // Dark Gradient Overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                  AppColors.background.withOpacity(0.9),
                  AppColors.background,
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header (Logo + Language Switcher)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: AppColors.primary,
                        ),
                      ),
                      
                      // Language Switcher (Mock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'English',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Text Content
                  Text(
                    'مرحباً بك في BMT',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'المنصة الرائدة للنقل الذكي والمريح. احجز رحلتك بكل سهولة وأمان.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/phone-login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                      ),
                    ),
                    child: const Text('المتابعة برقم الهاتف'),
                  ),
                  const SizedBox(height: 12),
                  
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AuthRoutes.signIn);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      'المتابعة بالبريد الإلكتروني',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Social Login section
                  const SocialLoginButtons(),
                  
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () {
                      // Navigate to Home as guest
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: Text(
                      'الاستمرار كضيف',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer Terms
                  Text(
                    'بالاستمرار، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
