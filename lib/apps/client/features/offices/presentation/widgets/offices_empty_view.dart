import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: ClientColors.primaryFor(context).withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.storefront_outlined,
                size: 40,
                color: ClientColors.primaryFor(context),
              ),
            ),
            const SizedBox(height: ClientSpacing.md),
            Text(
              isSearch
                  ? l10n.offices_noSearchResults(query)
                  : l10n.offices_directoryEmpty,
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            if (isSearch) ...[
              const SizedBox(height: ClientSpacing.xs),
              TextButton(
                onPressed: () =>
                    context.read<OfficesDirectoryCubit>().setQuery(''),
                child: Text(l10n.offices_clearSearch),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
