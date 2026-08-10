import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The brand block at the top of an auth screen: the same gradient app mark the
/// welcome screen opens with, a warm [title], and one supporting line.
///
/// The screen's *name* lives in the app bar, so the title here is the greeting
/// ("Welcome back"), never a second copy of the toolbar text.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, this.title, required this.subtitle});

  final String? title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ClientSpacing.md, bottom: ClientSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(ClientRadius.xl),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/branding/brand_glyph.png',
              color: ClientColors.textInverse,
              height: 36,
              width: 36,
            ),
          ),
          const SizedBox(height: ClientSpacing.lg),
          if (title case final String heading) ...[
            Text(
              heading,
              textAlign: TextAlign.center,
              style: ClientTypography.headingLarge(
                context,
              ).copyWith(color: ClientColors.textInverse),
            ),
            const SizedBox(height: ClientSpacing.xs),
          ],
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textInverse.withAlpha(220)),
          ),
        ],
      ),
    );
  }
}
