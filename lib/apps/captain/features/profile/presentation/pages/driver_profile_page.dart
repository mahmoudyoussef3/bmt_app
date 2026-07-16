import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
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
import '../widgets/driver_profile_skeleton.dart';

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
              0,
              CaptainDesignTokens.s24,
              // Cleared for the shell's floating nav bar.
              CaptainBottomNav.reservedSpace(context),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: CaptainDesignTokens.s24),
                _StatsCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s16),
                if (profile.hasVehicle) ...[
                  _VehicleCard(profile: profile),
                  const SizedBox(height: CaptainDesignTokens.s16),
                ],
                if (profile.hasRating) ...[
                  _RatingCard(rating: profile.averageRating),
                  const SizedBox(height: CaptainDesignTokens.s16),
                ],
                _InfoCard(profile: profile),
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

class _ProfileSliverHeader extends StatelessWidget {
  const _ProfileSliverHeader({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: CaptainColors.backgroundFor(context),
      centerTitle: true,
      title: Text(
        'ملفي',
        style: CaptainTypography.titleMedium(context).copyWith(
          fontWeight: FontWeight.w800,
          color: CaptainColors.textPrimaryFor(context),
        ),
      ),

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: CaptainColors.backgroundFor(context),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: CaptainDesignTokens.s24),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CaptainColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: CaptainColors.surfaceFor(context),
                      width: 3,
                    ),
                    boxShadow: CaptainDesignTokens.floatingShadow(context),
                  ),
                  child: profile.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            profile.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _InitialsAvatar(
                              name: profile.name,
                              large: true,
                            ),
                          ),
                        )
                      : _InitialsAvatar(name: profile.name, large: true),
                ),
                const SizedBox(height: CaptainDesignTokens.s12),
                Text(
                  profile.name,
                  style: CaptainTypography.titleLarge(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
                if (profile.hasRating) ...[
                  const SizedBox(height: CaptainDesignTokens.s8),
                  _StarRating(rating: profile.averageRating),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: CaptainDesignTokens.br24,
        gradient: LinearGradient(
          colors: [
            CaptainColors.primary,
            CaptainColors.primary.withValues(alpha: 0.8),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        boxShadow: CaptainDesignTokens.floatingShadow(context),
      ),
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: CaptainDesignTokens.br12,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              Text(
                'إحصائياتي',
                style: CaptainTypography.titleSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Row(
            children: [
              _StatTile(
                label: 'رحلات',
                value: '${profile.totalTrips}',
                icon: Icons.route_rounded,
                isLight: true,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _StatTile(
                label: 'ركاب',
                value: '${profile.totalPassengers}',
                icon: Icons.people_alt_rounded,
                isLight: true,
              ),
              if (profile.hasRating) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _StatTile(
                  label: 'تقييم',
                  value: profile.averageRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  isLight: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'تقييم الركاب',
      icon: Icons.star_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: CaptainTypography.displaySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(width: CaptainDesignTokens.s24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarRating(rating: rating),
                  const SizedBox(height: CaptainDesignTokens.s8),
                  Text(
                    _ratingLabel(rating),
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: CaptainColors.textPrimaryFor(context),
                    ),
                  ),
                ],
              ),
            ],
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.isLight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s12),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.2)
                  : CaptainColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isLight ? Colors.white : CaptainColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Text(
            value,
            style: CaptainTypography.headlineSmall(context).copyWith(
              fontWeight: FontWeight.w900,
              color: isLight
                  ? Colors.white
                  : CaptainColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: CaptainTypography.labelSmall(context).copyWith(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.8)
                  : CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
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
      child: Row(
        children: [
          Icon(icon, size: 18, color: CaptainColors.textSecondaryFor(context)),
          const SizedBox(width: CaptainDesignTokens.s12),
          Text(
            label,
            style: CaptainTypography.bodyMedium(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: CaptainTypography.bodyMedium(context).copyWith(
              color: CaptainColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 20,
        );
      }),
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
