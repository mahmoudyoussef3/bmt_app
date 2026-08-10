import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/routes_directory_cubit.dart';

/// Two different empty catalogs, told apart on purpose.
///
/// With no [query] this is "no route is running yet" — nothing the rider can
/// do. With one, their search simply matched nothing, so it names the term
/// and offers a way back to the full catalog.
class RoutesEmptyView extends StatelessWidget {
  const RoutesEmptyView({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSearch = query.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.xl,
        vertical: ClientSpacing.xxl,
      ),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ClientColors.primaryContainerFor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.route_outlined,
                size: 42,
                color: ClientColors.onPrimaryContainerFor(context),
              ),
            ),
            const SizedBox(height: ClientSpacing.md),
            Text(
              isSearch
                  ? l10n.routes_noSearchResults(query)
                  : l10n.routes_catalogEmpty,
              textAlign: TextAlign.center,
              style: ClientTypography.headingSmall(context),
            ),
            if (isSearch) ...[
              const SizedBox(height: ClientSpacing.xs),
              Text(
                l10n.routes_searchHint,
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: ClientSpacing.lg),
              ClientButton.secondary(
                label: l10n.routes_clearSearch,
                expand: false,
                onPressed: () =>
                    context.read<RoutesDirectoryCubit>().setQuery(''),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
