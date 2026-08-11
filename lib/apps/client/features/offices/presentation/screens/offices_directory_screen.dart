import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../cubit/offices_directory_cubit.dart';
import '../cubit/offices_directory_state.dart';
import '../widgets/office_brand_decor.dart';
import '../widgets/offices_directory_list.dart';
import '../widgets/offices_empty_view.dart';
import '../widgets/offices_search_band.dart';

/// The marketplace directory: every active transportation office, best-rated
/// first, searchable by company name or the cities it serves. Tapping one opens
/// its profile with the departures and routes it operates.
///
/// The whole screen rebuilds on state rather than only its body, because the
/// header carries the size of the directory — a count that is part of the
/// answer, not chrome around it.
class OfficesDirectoryScreen extends StatelessWidget {
  const OfficesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfficesDirectoryCubit, OfficesDirectoryState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final loaded = state is OfficesDirectoryLoaded ? state : null;

        return Scaffold(
          backgroundColor: ClientColors.backgroundFor(context),
          body: Column(
            children: [
              _DirectoryMasthead(
                title: l10n.offices_directoryTitle,
                lead: l10n.offices_directoryLead,
                count: loaded == null
                    ? null
                    : l10n.offices_countLabel(loaded.offices.length),
                
                searchBand: loaded != null && loaded.offices.isNotEmpty
                    ? OfficesSearchBand(state: loaded)
                    : null,
              ),
              Expanded(
                child: switch (state) {
                  OfficesDirectoryLoading() => const _DirectorySkeleton(),
                  OfficesDirectoryError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(ClientSpacing.md),
                      child: ClientErrorCard(
                        message: message,
                        retryLabel: l10n.common_retry,
                        onRetry: () =>
                            context.read<OfficesDirectoryCubit>().load(),
                      ),
                    ),
                  ),
                  OfficesDirectoryLoaded(:final offices) when offices.isEmpty =>
                    const OfficesEmptyView(),
                  final OfficesDirectoryLoaded loadedState =>
                    loadedState.isFilteredEmpty
                        ? OfficesEmptyView(query: loadedState.query)
                        : RefreshIndicator(
                            onRefresh: () =>
                                context.read<OfficesDirectoryCubit>().refresh(),
                            child: OfficesDirectoryList(
                              offices: loadedState.visibleOffices,
                            ),
                          ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The directory's letterhead: what this list is, how big it is, and the box
/// that narrows it.
///
/// It is the same brand band the office profile opens with — a rider who taps a
/// listing must land somewhere that looks like where they tapped from — and it
/// is fixed rather than scrolling, because a rider filtering a directory
/// reaches for the box repeatedly.
class _DirectoryMasthead extends StatelessWidget {
  const _DirectoryMasthead({
    required this.title,
    required this.lead,
    required this.count,
    required this.searchBand,
  });

  final String title;
  final String lead;

  /// "12 operators" — absent until the directory has loaded, because a count
  /// invented before the data arrives is a claim the screen cannot keep.
  final String? count;

  final Widget? searchBand;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: ClientColors.heroGradientFor(context),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(ClientRadius.xl),
          ),
          boxShadow: ClientElevation.md(context),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: OfficeBrandDecor()),
            Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        const SizedBox(width: ClientSpacing.xs),
                        IconButton(
                          icon: const DirectionalIcon(Icons.arrow_back_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () => Navigator.of(context).maybePop(),
                          color: Colors.white,
                        ),
                        const SizedBox(width: ClientSpacing.xs),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.headingMedium(context)
                                .copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: ClientSpacing.xs),
                          _CountPill(label: count!),
                        ],
                        const SizedBox(width: ClientSpacing.md),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ClientSpacing.lg,
                      0,
                      ClientSpacing.lg,
                      0,
                    ),
                    child: Text(
                      lead,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: Colors.white.withAlpha(210)),
                    ),
                  ),
                  ?searchBand,
                  if (searchBand == null)
                    const SizedBox(height: ClientSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How many operators the directory holds, as a glass chip on the band.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(46),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DirectorySkeleton extends StatelessWidget {
  const _DirectorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.md,
        ClientSpacing.xl,
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (_, _) => ClientSkeleton.officeCard(),
    );
  }
}
