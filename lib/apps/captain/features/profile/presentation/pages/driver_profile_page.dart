import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/driver_profile.dart';
import '../cubit/driver_profile_cubit.dart';
import '../cubit/driver_profile_state.dart';

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverProfileCubit, DriverProfileState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          body: switch (state) {
            DriverProfileLoading() => const Center(child: CircularProgressIndicator()),
            DriverProfileError(:final message) => _ErrorBody(
                message: message,
                onRetry: () => context.read<DriverProfileCubit>().load(),
              ),
            DriverProfileLoaded(:final profile) => _ProfileBody(profile: profile),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _StatsCard(profile: profile),
                const SizedBox(height: 16),
                if (profile.hasVehicle) ...[
                  _VehicleCard(profile: profile),
                  const SizedBox(height: 16),
                ],
                if (profile.hasRating) ...[
                  _RatingCard(rating: profile.averageRating),
                  const SizedBox(height: 16),
                ],
                _InfoCard(profile: profile),
                const SizedBox(height: 24),
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
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: scheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'تسجيل الخروج',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('تسجيل الخروج'),
                content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('خروج'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await captainGetIt<CaptainAuthCubit>().signOut();
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primary.withAlpha(200), scheme.surface],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withAlpha(40),
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
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                ),
                if (profile.hasRating) ...[
                  const SizedBox(height: 6),
                  _StarRating(rating: profile.averageRating),
                ],
              ],
            ),
          ),
        ),
        title: Text(
          'ملفي',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'إحصائياتي',
      icon: Icons.bar_chart_rounded,
      child: Row(
        children: [
          _StatTile(
            label: 'رحلات مكتملة',
            value: '${profile.totalTrips}',
            icon: Icons.route_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          _StatTile(
            label: 'إجمالي الركاب',
            value: '${profile.totalPassengers}',
            icon: Icons.people_alt_rounded,
            color: Colors.teal,
          ),
          if (profile.hasRating)
            _StatTile(
              label: 'التقييم',
              value: profile.averageRating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: Colors.amber,
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
    final scheme = Theme.of(context).colorScheme;
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'مركبة جاهزة للتشغيل',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
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
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                    ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarRating(rating: rating),
                  const SizedBox(height: 4),
                  Text(
                    _ratingLabel(rating),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
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
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('خروج'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await Supabase.instance.client.auth.signOut();
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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
    final scheme = Theme.of(context).colorScheme;
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: large ? 32 : 18,
          fontWeight: FontWeight.w900,
          color: scheme.onPrimaryContainer,
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
      child: AsyncStateView(
        status: AsyncViewStatus.error,
        errorMessage: message,
        onRetry: onRetry,
        child: const SizedBox.shrink(),
      ),
    );
  }
}
