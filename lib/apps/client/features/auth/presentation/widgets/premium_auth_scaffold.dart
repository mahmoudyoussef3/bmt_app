import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/directional_icon.dart';

import 'auth_scaffold_header.dart';

class PremiumAuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final Widget? logo;

  const PremiumAuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = true,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Subtle Top Gradient Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom App Bar Area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      if (showBack)
                        IconButton(
                          icon: DirectionalIcon(
                            Icons.arrow_back_ios_new_rounded,
                            color: theme.iconTheme.color,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                    ],
                  ),
                ),

                AuthScaffoldHeader(
                  title: title,
                  subtitle: subtitle,
                  logo: logo,
                ),
                const SizedBox(height: 32),

                // Scrollable Content Form
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ).copyWith(bottom: 40),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
