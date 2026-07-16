import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/driver_profile.dart';
import '../cubit/driver_profile_cubit.dart';
import '../cubit/driver_profile_state.dart';
import '../widgets/captain_appearance_sheet.dart';
import '../widgets/driver_profile_metrics.dart';
import '../widgets/driver_profile_skeleton.dart';
import '../widgets/verification_card.dart';

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverProfileCubit, DriverProfileState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: CaptainColors.backgroundFor(context),
          body: switch (state) {
            DriverProfileLoading() => const DriverProfileSkeleton(),
            DriverProfileError(:final message) => _ErrorBody(
              message: message,
              onRetry: () => context.read<DriverProfileCubit>().load(),
            ),
            DriverProfileLoaded(:final profile) => _ProfileBody(
              profile: profile,
            ),
          },
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DriverProfileCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          _ProfileSliverHeader(profile: profile),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
              // Cleared for the shell's floating nav bar.
              CaptainBottomNav.reservedSpace(context),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                VerificationCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s16),
                if (profile.hasVehicle) ...[
                  _VehicleCard(profile: profile),
                  const SizedBox(height: CaptainDesignTokens.s16),
                ],
                _InfoCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s16),
                const _SettingsCard(),
                const SizedBox(height: CaptainDesignTokens.s32),
                _SignOutButton(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// The captain's identity block: avatar, name, standing and lifetime numbers,
/// all on the brand gradient.
///
/// The stats live here rather than in a card of their own — they *are* the
/// captain's identity on this screen, and hosting them on the header's gradient
/// leaves exactly one accent surface instead of a flat header competing with a
/// gradient card directly beneath it.
class _ProfileSliverHeader extends StatelessWidget {
  const _ProfileSliverHeader({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: DriverProfileMetrics.headerHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: scheme.primary,
      foregroundColor: CaptainColors.onPrimary,
      centerTitle: true,
      title: Text(
        'ملفي',
        style: CaptainTypography.titleMedium(
          context,
        ).copyWith(fontWeight: FontWeight.w800, color: CaptainColors.onPrimary),
      ),
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CaptainColors.primaryGradient(context),
        ),
        child: Stack(
          children: [
            // A soft highlight that keeps the large gradient from reading flat.
            PositionedDirectional(
              top: -80,
              end: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withAlpha(40), Colors.transparent],
                  ),
                ),
              ),
            ),
            FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  // Top clears the pinned toolbar the title sits in.
                  padding: const EdgeInsets.fromLTRB(
                    CaptainDesignTokens.s24,
                    kToolbarHeight,
                    CaptainDesignTokens.s24,
                    CaptainDesignTokens.s16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfileAvatar(profile: profile),
                      const SizedBox(height: CaptainDesignTokens.s12),
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CaptainTypography.titleLarge(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: CaptainColors.onPrimary,
                        ),
                      ),
                      if (profile.hasRating) ...[
                        const SizedBox(height: CaptainDesignTokens.s8),
                        _RatingPill(rating: profile.averageRating),
                      ],
                      const SizedBox(height: CaptainDesignTokens.s20),
                      _HeaderStats(profile: profile),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(40),
        border: Border.all(color: Colors.white.withAlpha(140), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: profile.photoUrl != null
          ? ClipOval(
              child: Image.network(
                profile.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) =>
                    _InitialsAvatar(name: profile.name, large: true),
              ),
            )
          : _InitialsAvatar(name: profile.name, large: true),
    );
  }
}

/// Rating and its plain-language reading in one pill — the qualitative label a
/// captain actually reads, next to the number it comes from.
class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s4,
        CaptainDesignTokens.s12,
        CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: CaptainColors.rating),
          const SizedBox(width: CaptainDesignTokens.s4),
          Text(
            '${rating.toStringAsFixed(1)} · ${_ratingLabel(rating)}',
            style: CaptainTypography.labelMedium(
              context,
            ).copyWith(color: CaptainColors.onPrimary),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 4.5) return 'ممتاز';
    if (r >= 4.0) return 'جيد جداً';
    if (r >= 3.5) return 'جيد';
    if (r >= 3.0) return 'مقبول';
    return 'بحاجة لتحسين';
  }
}

/// Lifetime totals, on glass tiles over the header gradient.
class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          _StatTile(
            label: 'رحلات',
            value: '${profile.totalTrips}',
            icon: Icons.route_rounded,
          ),
          _StatDivider(),
          _StatTile(
            label: 'ركاب',
            value: '${profile.totalPassengers}',
            icon: Icons.people_alt_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white.withAlpha(45));
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'المركبة المخصصة',
      icon: Icons.directions_bus_rounded,
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.confirmation_number_rounded,
            label: 'كود المركبة',
            value: profile.vehicleCode ?? '—',
          ),
          _DetailRow(
            icon: Icons.credit_card_rounded,
            label: 'لوحة الترخيص',
            value: profile.plateNumber ?? '—',
          ),
          if (profile.vehicleModel != null)
            _DetailRow(
              icon: Icons.directions_car_rounded,
              label: 'الموديل',
              value: profile.vehicleModel!,
            ),
          if (profile.vehicleCapacity != null)
            _DetailRow(
              icon: Icons.event_seat_rounded,
              label: 'السعة',
              value: '${profile.vehicleCapacity} راكب',
            ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s12,
              vertical: CaptainDesignTokens.s8,
            ),
            decoration: BoxDecoration(
              color: CaptainColors.primary.withValues(alpha: 0.1),
              borderRadius: CaptainDesignTokens.br12,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: CaptainColors.primary,
                ),
                const SizedBox(width: CaptainDesignTokens.s12),
                Text(
                  'مركبة جاهزة للتشغيل',
                  style: CaptainTypography.labelMedium(context).copyWith(
                    color: CaptainColors.primary,
                    fontWeight: FontWeight.w700,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'معلومات الحساب',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.phone_rounded,
            label: 'رقم الهاتف',
            value: profile.phone.isNotEmpty ? profile.phone : '—',
          ),
          if (profile.licenseNumber != null)
            _DetailRow(
              icon: Icons.badge_rounded,
              label: 'رقم الرخصة',
              value: profile.licenseNumber!,
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'الإعدادات',
      icon: Icons.settings_rounded,
      child: BlocBuilder<CaptainThemeCubit, CaptainThemeState>(
        builder: (context, state) {
          return InkWell(
            onTap: () => showCaptainAppearanceSheet(context),
            borderRadius: CaptainDesignTokens.br12,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CaptainDesignTokens.s4,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    size: 18,
                    color: CaptainColors.textSecondaryFor(context),
                  ),
                  const SizedBox(width: CaptainDesignTokens.s12),
                  Text(
                    'المظهر',
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _themeModeLabel(state.themeMode),
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      color: CaptainColors.textPrimaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: CaptainDesignTokens.s4),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: CaptainColors.textSecondaryFor(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'فاتح',
    ThemeMode.dark => 'داكن',
    ThemeMode.system => 'تلقائي',
  };
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CaptainButton(
      label: 'تسجيل الخروج',
      icon: Icons.logout_rounded,
      onPressed: () => _confirmAndSignOut(context),
      variant: CaptainButtonVariant.danger,
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  color: CaptainColors.primary.withValues(alpha: 0.1),
                  borderRadius: CaptainDesignTokens.br12,
                ),
                child: Icon(icon, size: 18, color: CaptainColors.primary),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              Expanded(
                child: Text(
                  title,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          child,
        ],
      ),
    );
  }
}

/// A single lifetime total. Only ever rendered on the header gradient, so it
/// commits to on-primary colours rather than carrying a light/dark switch.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withAlpha(200), size: 14),
              const SizedBox(width: CaptainDesignTokens.s4),
              Text(
                label,
                style: CaptainTypography.labelSmall(
                  context,
                ).copyWith(color: Colors.white.withAlpha(200)),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          Text(
            value,
            style: CaptainTypography.headlineSmall(context).copyWith(
              fontWeight: FontWeight.w900,
              color: CaptainColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: CaptainDesignTokens.s12,
      ),
      // The label yields before the value does: a truncated "الموديل" still
      // reads, a truncated plate number is useless. Neither may overflow —
      // these rows carry long values (models, plates) on narrow phones.
      child: Row(
        children: [
          Icon(icon, size: 18, color: CaptainColors.textSecondaryFor(context)),
          const SizedBox(width: CaptainDesignTokens.s12),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: large ? 32 : 18,
          fontWeight: FontWeight.w900,
          color: CaptainColors.primary,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: AsyncStateView(
              status: AsyncViewStatus.error,
              errorMessage: message,
              onRetry: onRetry,
              child: const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s24,
              0,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
            ),
            child: CaptainButton(
              label: 'تسجيل الخروج',
              icon: Icons.logout_rounded,
              variant: CaptainButtonVariant.secondary,
              onPressed: () => _confirmAndSignOut(context),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmAndSignOut(BuildContext context) async {
  final confirmed = await CaptainConfirmDialog.show(
    context,
    title: 'تسجيل الخروج',
    message: 'هل أنت متأكد من تسجيل الخروج؟',
    confirmLabel: 'خروج',
    confirmColor: Colors.red,
  );
  if (confirmed) {
    await captainGetIt<CaptainAuthCubit>().signOut();
  }
}
