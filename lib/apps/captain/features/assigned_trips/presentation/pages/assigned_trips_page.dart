import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/pages/trip_execution_page.dart';

import '../../domain/entities/assigned_trip.dart';
import '../cubit/assigned_trips_cubit.dart';
import '../cubit/assigned_trips_state.dart';
import '../widgets/assigned_trip_card.dart';

class AssignedTripsPage extends StatefulWidget {
  const AssignedTripsPage({super.key});

  @override
  State<AssignedTripsPage> createState() => _AssignedTripsPageState();
}

class _AssignedTripsPageState extends State<AssignedTripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssignedTripsCubit>().load();
  }

  void _showDevModeSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<AppModeCubit, AppModeState>(
            builder: (context, state) {
              final cubit = context.read<AppModeCubit>();
              final current = state.mode;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعدادات المطور',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تغيير وضع التطبيق (للتطوير فقط)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppMode.values.map((m) {
                      final active = m == current;
                      return FilterChip(
                        label: Text(m.displayLabel),
                        selected: active,
                        onSelected: (_) {
                          if (!active) {
                            cubit.changeMode(m);
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocBuilder<AssignedTripsCubit, AssignedTripsState>(
        builder: (context, state) {
          if (state is AssignedTripsLoading) {
            return const _AssignedTripsSkeleton();
          }
          if (state is AssignedTripsError) {
            return SafeArea(
              child: AsyncStateView(
                status: AsyncViewStatus.error,
                errorMessage: state.message,
                onRetry: () => context.read<AssignedTripsCubit>().load(),
                child: const SizedBox.shrink(),
              ),
            );
          }

          final List<AssignedTrip> trips = state is AssignedTripsLoaded
              ? state.trips
              : const <AssignedTrip>[];

          final boarded = trips.fold<int>(
            0,
            (total, trip) => total + trip.boardedCount,
          );
          final passengers = trips.fold<int>(
            0,
            (total, trip) => total + trip.passengerCount,
          );
          final activeTrips = trips
              .where(
                (trip) =>
                    trip.status == AssignedTripStatus.boarding ||
                    trip.status == AssignedTripStatus.inProgress,
              )
              .length;

          return RefreshIndicator(
            onRefresh: () => context.read<AssignedTripsCubit>().refresh(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: CaptainColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CaptainColors.primary,
                            CaptainColors.primary.withValues(alpha: 0.8),
                          ],
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            CaptainDesignTokens.s24,
                            CaptainDesignTokens.s32,
                            CaptainDesignTokens.s24,
                            CaptainDesignTokens.s16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مرحباً كابتن 👋',
                                    style: CaptainTypography.titleMedium(context)
                                        .copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: CaptainDesignTokens.s4),
                                  Text(
                                    'لوحة القيادة',
                                    style: CaptainTypography.headlineMedium(context)
                                        .copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _showDevModeSwitcher(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: const AppAvatar(initials: 'ك'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CaptainDesignTokens.s24,
                      ),
                      child: _OverviewPanel(
                        trips: trips.length,
                        passengers: passengers,
                        boarded: boarded,
                        activeTrips: activeTrips,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainDesignTokens.s24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
                            decoration: BoxDecoration(
                              color: CaptainColors.primary.withValues(alpha: 0.1),
                              borderRadius: CaptainDesignTokens.br12,
                            ),
                            child: const Icon(Icons.calendar_today_rounded, size: 20, color: CaptainColors.primary),
                          ),
                          const SizedBox(width: CaptainDesignTokens.s12),
                          Expanded(
                            child: Text(
                              'رحلات اليوم',
                              style: CaptainTypography.titleLarge(
                                context,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CaptainDesignTokens.s16,
                              vertical: CaptainDesignTokens.s8,
                            ),
                            decoration: BoxDecoration(
                              color: trips.isNotEmpty ? CaptainColors.primary : CaptainColors.surfaceFor(context),
                              borderRadius: CaptainDesignTokens.br32,
                              boxShadow: trips.isNotEmpty ? CaptainDesignTokens.floatingShadow(context) : null,
                            ),
                            child: Text(
                              '${trips.length} رحلات',
                              style: CaptainTypography.labelMedium(context)
                                  .copyWith(
                                    color: trips.isNotEmpty ? Colors.white : CaptainColors.textSecondaryFor(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (trips.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CaptainEmptyState(
                        title: 'لا توجد رحلات اليوم',
                        subtitle:
                            'ستظهر رحلاتك هنا عند تعيينها من قبل العمليات.',
                        icon: Icons.route_outlined,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s16,
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s48,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final trip = trips[index];
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: CaptainDesignTokens.s24,
                          ),
                          child: AssignedTripCard(
                            trip: trip,
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TripExecutionPage(trip: trip),
                              ),
                            ),
                            onManifest: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PassengerListPage(tripId: trip.id),
                              ),
                            ),
                          ),
                        );
                      }, childCount: trips.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.trips,
    required this.passengers,
    required this.boarded,
    required this.activeTrips,
  });

  final int trips;
  final int passengers;
  final int boarded;
  final int activeTrips;

  @override
  Widget build(BuildContext context) {
    final progress = passengers == 0 ? 0.0 : boarded / passengers;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: CaptainDesignTokens.floatingShadow(context),
        border: Border.all(color: CaptainColors.primary.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Metric(
                label: 'الرحلات',
                value: trips.toString(),
                icon: Icons.route_rounded,
                color: CaptainColors.primary,
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              _Metric(
                label: 'نشطة',
                value: activeTrips.toString(),
                icon: Icons.bolt_rounded,
                color: Colors.orange,
                isHighlight: activeTrips > 0,
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              _Metric(
                label: 'الركاب',
                value: passengers.toString(),
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            decoration: BoxDecoration(
              color: CaptainColors.primary.withValues(alpha: 0.03),
              borderRadius: CaptainDesignTokens.br16,
              border: Border.all(color: CaptainColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تقدم الصعود',
                      style: CaptainTypography.labelLarge(context).copyWith(
                        color: CaptainColors.textPrimaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CaptainColors.primary.withValues(alpha: 0.1),
                        borderRadius: CaptainDesignTokens.br8,
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: CaptainTypography.titleSmall(context).copyWith(
                          color: CaptainColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CaptainDesignTokens.s16),
                ClipRRect(
                  borderRadius: CaptainDesignTokens.br8,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: CaptainColors.primary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(CaptainColors.primary),
                  ),
                ),
                const SizedBox(height: CaptainDesignTokens.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: CaptainColors.textSecondaryFor(context)),
                    const SizedBox(width: CaptainDesignTokens.s8),
                    Text(
                      'صعد $boarded من أصل $passengers راكب',
                      style: CaptainTypography.labelMedium(context).copyWith(
                        color: CaptainColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w600,
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
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: CaptainDesignTokens.s16,
          horizontal: CaptainDesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: isHighlight ? color : CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br16,
          boxShadow: isHighlight ? CaptainDesignTokens.floatingShadow(context) : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: isHighlight ? null : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(CaptainDesignTokens.s8),
              decoration: BoxDecoration(
                color: isHighlight ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: isHighlight ? Colors.white : color),
            ),
            const SizedBox(height: CaptainDesignTokens.s12),
            Text(
              value,
              style: CaptainTypography.headlineMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: isHighlight ? Colors.white : CaptainColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s4),
            Text(
              label,
              style: CaptainTypography.labelSmall(context).copyWith(
                color: isHighlight ? Colors.white.withValues(alpha: 0.9) : CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedTripsSkeleton extends StatelessWidget {
  const _AssignedTripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CaptainDesignTokens.s24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CaptainSkeleton(height: 32, width: 140),
              CaptainSkeleton(
                height: 40,
                width: 40,
                borderRadius: CaptainDesignTokens.br32,
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          const CaptainSkeleton(height: 18, width: double.infinity),
          const SizedBox(height: CaptainDesignTokens.s12),
          const CaptainSkeleton(height: 16, width: double.infinity),
          const SizedBox(height: CaptainDesignTokens.s16),
          Row(
            children: [
              const Expanded(
                child: CaptainSkeleton(height: 36, width: double.infinity),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              const Expanded(
                child: CaptainSkeleton(height: 36, width: double.infinity),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s32),
          const CaptainSkeleton(height: 24, width: 120),
          const SizedBox(height: CaptainDesignTokens.s16),
          for (var i = 0; i < 3; i++) ...[
            CaptainSkeleton(
              height: 220,
              borderRadius: CaptainDesignTokens.br24,
              width: double.infinity,
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
          ],
        ],
      ),
    );
  }
}
