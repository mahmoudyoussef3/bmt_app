import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_container.dart';

/// One clickable label in the navbar's link row — a title plus the section
/// it scrolls to.
class LandingNavLink {
  const LandingNavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// The page's fixed header: brand mark, section links, and the two auth CTAs.
///
/// Collapses to a brand mark + menu button under [LandingContainer.isMobile]
/// — a desktop link row has nowhere to go on a phone width, so it moves into
/// a bottom sheet instead of wrapping.
class LandingNavbar extends StatelessWidget {
  const LandingNavbar({
    super.key,
    required this.links,
    required this.onLogin,
    required this.onGetStarted,
  });

  final List<LandingNavLink> links;
  final VoidCallback onLogin;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = LandingContainer.isMobile(context);

    return Container(
      color: scheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LandingContainer(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 20 : 48,
              vertical: 14,
            ),
            maxWidth: 1280,
            child: Row(
              children: [
                _Brand(scheme: scheme),
                const Spacer(),
                if (!mobile) ...[
                  for (final link in links) _NavLinkButton(link: link),
                  const SizedBox(width: AppSpacing.medium),
                  TextButton(onPressed: onLogin, child: const Text('تسجيل الدخول')),
                  const SizedBox(width: AppSpacing.small),
                  LandingButton.primary(label: 'ابدأ مع EWT', onPressed: onGetStarted),
                ] else
                  IconButton(
                    onPressed: () => _showMobileMenu(context),
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'القائمة',
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            0,
            AppSpacing.large,
            AppSpacing.xLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final link in links)
                ListTile(
                  title: Text(
                    link.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    link.onTap();
                  },
                ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onLogin();
                },
                child: const Text('تسجيل الدخول'),
              ),
              const SizedBox(height: AppSpacing.small),
              LandingButton.primary(
                label: 'ابدأ مع EWT',
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onGetStarted();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Icon(DashboardIcons.fleetActive, size: 18, color: scheme.onPrimary),
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          'EWT',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _NavLinkButton extends StatelessWidget {
  const _NavLinkButton({required this.link});

  final LandingNavLink link;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: link.onTap,
      style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
      child: Text(link.label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
