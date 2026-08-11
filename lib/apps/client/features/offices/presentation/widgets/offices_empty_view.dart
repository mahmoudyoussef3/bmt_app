import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_cubit.dart';

/// Two different empty directories, told apart on purpose.
///
/// With no [query] this is "no office is operating yet" — nothing the rider can
/// do. With one, their search simply matched nothing, so it names the term and
/// offers a way back to the full list.
class OfficesEmptyView extends StatelessWidget {
  const OfficesEmptyView({super.key, this.query = ''});

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
                isSearch ? Icons.search_off_rounded : Icons.storefront_outlined,
                size: 42,
                color: ClientColors.onPrimaryContainerFor(context),
              ),
            ),
            const SizedBox(height: ClientSpacing.md),
            Text(
              isSearch
                  ? l10n.offices_noSearchResults(query)
                  : l10n.offices_directoryEmpty,
              textAlign: TextAlign.center,
              style: ClientTypography.headingSmall(context),
            ),
            if (isSearch) ...[
              const SizedBox(height: ClientSpacing.xs),
              Text(
                l10n.offices_searchHint,
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: ClientSpacing.lg),
              ClientButton.secondary(
                label: l10n.offices_clearSearch,
                expand: false,
                onPressed: () =>
                    context.read<OfficesDirectoryCubit>().setQuery(''),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
