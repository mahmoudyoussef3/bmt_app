import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../cubit/passenger_manifest_cubit.dart';
import '../cubit/passenger_manifest_state.dart';
import '../widgets/passenger_card.dart';
import '../widgets/passenger_filter_chips.dart';
import '../widgets/passenger_search_field.dart';
import '../widgets/passenger_stats_row.dart';

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

class _PassengerListView extends StatelessWidget {
  const _PassengerListView({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: BlocConsumer<PassengerManifestCubit, PassengerManifestState>(
        listenWhen: (_, current) => current is PassengerManifestUpdateError,
        listener: (context, state) {
          if (state is PassengerManifestUpdateError) {
            AppSnackbar.error(context, 'فشل تحديث الحالة: ${state.message}');
          }
        },
        builder: (context, state) {
          final loaded = switch (state) {
            PassengerManifestLoaded() => state,
            PassengerManifestUpdateError(:final loaded) => loaded,
            _ => null,
          };

          return CustomScrollView(
            slivers: [
              CaptainSliverHeader(
                title: 'قائمة الركاب',
                subtitle: loaded == null
                    ? null
                    : 'صعد ${loaded.counts.boarded} من أصل '
                          '${loaded.counts.total}',
              ),
              ...switch (state) {
                PassengerManifestLoading() => const [
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                PassengerManifestError(:final message) => [
                  SliverFillRemaining(
                    child: AsyncStateView(
                      status: AsyncViewStatus.error,
                      errorMessage: message,
                      onRetry: () =>
                          context.read<PassengerManifestCubit>().load(tripId),
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ],
                _ => _manifestSlivers(context, loaded!),
              },
            ],
          );
        },
      ),
    );
  }

  List<Widget> _manifestSlivers(
    BuildContext context,
    PassengerManifestLoaded state,
  ) {
    final cubit = context.read<PassengerManifestCubit>();

    return [
      SliverToBoxAdapter(child: PassengerStatsRow(counts: state.counts)),
      SliverToBoxAdapter(
        child: PassengerSearchField(
          hasQuery: state.search.isNotEmpty,
          onChanged: cubit.search,
        ),
      ),
      SliverToBoxAdapter(
        child: PassengerFilterChips(
          current: state.statusFilter,
          onSelect: cubit.toggleStatusFilter,
        ),
      ),
      if (state.visiblePassengers.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _EmptyManifest(isFiltering: state.isFiltering)),
        )
      else
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            CaptainDesignTokens.s24,
            CaptainDesignTokens.s24,
            CaptainDesignTokens.s24,
            CaptainDesignTokens.s48,
          ),
          sliver: SliverList.builder(
            itemCount: state.visiblePassengers.length,
            itemBuilder: (context, i) {
              final passenger = state.visiblePassengers[i];
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: CaptainDesignTokens.s24,
                ),
                child: PassengerCard(
                  passenger: passenger,
                  onCall: passenger.phone.trim().isEmpty
                      ? null
                      : () => _call(context, passenger.phone),
                ),
              );
            },
          ),
        ),
    ];
  }
}

Future<void> _call(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.trim());
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    AppSnackbar.error(context, 'تعذر بدء الاتصال بالرقم $phone');
  }
}

class _EmptyManifest extends StatelessWidget {
  const _EmptyManifest({required this.isFiltering});

  final bool isFiltering;

  @override
  Widget build(BuildContext context) {
    return CaptainEmptyState(
      icon: Icons.people_alt_rounded,
      title: isFiltering ? 'لا نتائج' : 'لا يوجد ركاب على هذه الرحلة',
      subtitle: isFiltering
          ? 'جرّب تغيير الفلتر أو كلمة البحث.'
          : 'ستظهر الحجوزات المؤكدة هنا فور إضافتها.',
    );
  }
}
