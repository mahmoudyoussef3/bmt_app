import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chat_details_page.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';

import '../../domain/entities/passenger.dart';
import '../cubit/passenger_manifest_cubit.dart';
import '../cubit/passenger_manifest_state.dart';
import '../widgets/passenger_card.dart';

class PassengerListPage extends StatelessWidget {
  const PassengerListPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PassengerManifestCubit>(
      create: (_) => captainGetIt<PassengerManifestCubit>()..load(tripId),
      child: _PassengerListView(tripId: tripId),
    );
  }
}

class _PassengerListView extends StatefulWidget {
  const _PassengerListView({required this.tripId});

  final String tripId;

  @override
  State<_PassengerListView> createState() => _PassengerListViewState();
}

class _PassengerListViewState extends State<_PassengerListView> {
  String _search = '';
  PassengerBoardingStatus? _filter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Passenger> _apply(List<Passenger> all) {
    var result = all;
    if (_filter != null) result = result.where((p) => p.status == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.seat.toLowerCase().contains(q) ||
          p.pickupPoint.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PassengerManifestCubit, PassengerManifestState>(
      listener: (context, state) {
        if (state is PassengerManifestUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تحديث الحالة: ${state.message}'),
              backgroundColor: CaptainColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final passengers = switch (state) {
          PassengerManifestLoaded(:final passengers) => passengers,
          PassengerManifestUpdateError(:final passengers) => passengers,
          _ => <Passenger>[],
        };

        final filtered = _apply(passengers);

        final boarded = passengers.where((p) => p.status == PassengerBoardingStatus.boarded).length;
        final pending = passengers.where((p) => p.status == PassengerBoardingStatus.pending).length;
        final absent = passengers.where((p) => p.status == PassengerBoardingStatus.absent).length;
        final late = passengers.where((p) => p.status == PassengerBoardingStatus.late).length;

        return Scaffold(
          backgroundColor: CaptainColors.backgroundFor(context),
          body: CustomScrollView(
            slivers: [
              _AppBar(
                tripId: widget.tripId,
                total: passengers.length,
                boarded: boarded,
              ),
              if (state is PassengerManifestLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (state is PassengerManifestError)
                SliverFillRemaining(
                  child: AsyncStateView(
                    status: AsyncViewStatus.error,
                    errorMessage: state.message,
                    onRetry: () => context.read<PassengerManifestCubit>().load(widget.tripId),
                    child: const SizedBox.shrink(),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _StatsRow(
                    boarded: boarded,
                    pending: pending,
                    absent: absent,
                    late: late,
                    total: passengers.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        CaptainDesignTokens.s24, CaptainDesignTokens.s16, CaptainDesignTokens.s24, CaptainDesignTokens.s16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو المقعد أو نقطة الركوب',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: CaptainColors.surfaceFor(context),
                        border: OutlineInputBorder(
                          borderRadius: CaptainDesignTokens.br16,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: CaptainDesignTokens.s16, horizontal: CaptainDesignTokens.s24),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FilterChips(
                    current: _filter,
                    onSelect: (f) => setState(() => _filter = _filter == f ? null : f),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CaptainEmptyState(
                        title: _filter != null || _search.isNotEmpty
                            ? 'لا نتائج'
                            : 'لا يوجد ركاب على هذه الرحلة',
                        subtitle: _filter != null || _search.isNotEmpty
                            ? 'جرّب تغيير الفلتر أو كلمة البحث.'
                            : 'ستظهر الحجوزات المؤكدة هنا فور إضافتها.',
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        CaptainDesignTokens.s24, CaptainDesignTokens.s24, CaptainDesignTokens.s24, CaptainDesignTokens.s48),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: CaptainDesignTokens.s24),
                          child: PassengerCard(
                            passenger: p,
                            onCall: () => launchUrl(Uri.parse('tel:${p.phone}')),
                            onChat: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatDetailsPage(
                                  tripId: widget.tripId,
                                  passengerId: p.id,
                                  title: p.name,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.tripId, required this.total, required this.boarded});

  final String tripId;
  final int total;
  final int boarded;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: CaptainColors.surfaceFor(context),
      iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'قائمة الركاب',
              style: CaptainTypography.titleLarge(context).copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'صعد $boarded من أصل $total',
              style: CaptainTypography.labelMedium(context).copyWith(
                    color: CaptainColors.textSecondaryFor(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.boarded,
    required this.pending,
    required this.absent,
    required this.late,
    required this.total,
  });

  final int boarded, pending, absent, late, total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : boarded / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          CaptainDesignTokens.s24, CaptainDesignTokens.s16, CaptainDesignTokens.s24, CaptainDesignTokens.s16),
      child: Container(
        padding: const EdgeInsets.all(CaptainDesignTokens.s24),
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br24,
          boxShadow: CaptainDesignTokens.softShadow(context),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _Stat(label: 'صعد', value: boarded, color: CaptainColors.success),
                _Stat(label: 'بانتظار', value: pending, color: CaptainColors.primary),
                _Stat(label: 'متأخر', value: late, color: CaptainColors.warning),
                _Stat(label: 'غائب', value: absent, color: CaptainColors.error),
              ],
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
            ClipRRect(
              borderRadius: CaptainDesignTokens.br8,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: CaptainColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? CaptainColors.success : CaptainColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: CaptainTypography.headlineMedium(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: CaptainTypography.labelSmall(context).copyWith(color: CaptainColors.textSecondaryFor(context), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onSelect});

  final PassengerBoardingStatus? current;
  final void Function(PassengerBoardingStatus) onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = [
      ('صعد', PassengerBoardingStatus.boarded, CaptainColors.success),
      ('بانتظار', PassengerBoardingStatus.pending, CaptainColors.primary),
      ('متأخر', PassengerBoardingStatus.late, CaptainColors.warning),
      ('غائب', PassengerBoardingStatus.absent, CaptainColors.error),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips.map((c) {
          final isActive = current == c.$2;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(c.$1),
              selected: isActive,
              onSelected: (_) => onSelect(c.$2),
              selectedColor: c.$3.withAlpha(30),
              checkmarkColor: c.$3,
              backgroundColor: CaptainColors.surfaceFor(context),
              labelStyle: CaptainTypography.labelMedium(context).copyWith(
                color: isActive ? c.$3 : CaptainColors.textSecondaryFor(context),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
              side: BorderSide(color: isActive ? c.$3 : Colors.transparent),
            ),
          );
        }).toList(),
      ),
    );
  }
}
