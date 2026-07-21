import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_cubit.dart';
import '../cubit/offices_directory_state.dart';
import '../routes/offices_routes.dart';
import '../widgets/office_card.dart';

/// The marketplace directory: every active transportation office, best-rated
/// first. Tapping one opens its profile with the routes it operates.
class OfficesDirectoryScreen extends StatelessWidget {
  const OfficesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          context.l10n.offices_directoryTitle,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        centerTitle: true,
      ),
      body: BlocBuilder<OfficesDirectoryCubit, OfficesDirectoryState>(
        builder: (context, state) => switch (state) {
          OfficesDirectoryLoading() => const _DirectorySkeleton(),
          OfficesDirectoryError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClientErrorCard(
                message: message,
                retryLabel: context.l10n.common_retry,
                onRetry: () => context.read<OfficesDirectoryCubit>().load(),
              ),
            ),
          ),
          OfficesDirectoryLoaded(:final offices) => offices.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.offices_directoryEmpty,
                    style: ClientTypography.bodyMedium(context),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: offices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => OfficeCard(
                    office: offices[index],
                    onTap: () => Navigator.pushNamed(
                      context,
                      OfficesRoutes.profile,
                      arguments: offices[index],
                    ),
                  ),
                ),
        },
      ),
    );
  }
}

class _DirectorySkeleton extends StatelessWidget {
  const _DirectorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ClientSkeleton(height: 92, borderRadius: 16),
    );
  }
}
