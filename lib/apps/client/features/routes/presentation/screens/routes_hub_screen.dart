import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_section_header.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/routes_hub_data.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_state.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_flow_steps.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_hero.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_offices_card.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_search_card.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_skeleton.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Routes tab — premium route discovery entry into the booking search flow.
class RoutesHubScreen extends StatefulWidget {
  const RoutesHubScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<RoutesHubScreen> createState() => _RoutesHubScreenState();
}

class _RoutesHubScreenState extends State<RoutesHubScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RoutesHubCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return BlocConsumer<RoutesHubCubit, RoutesHubState>(
      listenWhen: (previous, current) =>
          current is RoutesHubLoaded && current.refreshFailure != null,
      listener: (context, state) {
        final message = (state as RoutesHubLoaded).refreshFailure!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(message),
              action: SnackBarAction(
                label: context.l10n.common_retry,
                onPressed: () => context.read<RoutesHubCubit>().load(),
              ),
            ),
          );
      },
      builder: (context, state) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: switch (state) {
              RoutesHubLoading() => const RoutesHubSkeleton(),
              RoutesHubError(:final message) => ClientErrorCard.fullScreen(
                message: message,
                onRetry: () => context.read<RoutesHubCubit>().load(),
              ),
              RoutesHubLoaded(:final data) => _LoadedBody(
                data: data,
                onOpenAction: _openAction,
              ),
            },
          ),
        );
      },
    );
  }

  void _openAction(RoutesHubAction action) {
    widget.onOpenRoute(
      action.route,
      action.arguments.isEmpty ? null : action.arguments,
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.data, required this.onOpenAction});

  final RoutesHubData data;
  final void Function(RoutesHubAction) onOpenAction;

  /// The hub's copy is static app chrome (see the comment in
  /// [SupabaseRoutesHubDatasource]) that happens to be threaded through the
  /// data layer for `searchAction`/`popularRoutesAction` routing — the
  /// display text itself is localized here rather than read off [data], so
  /// [RoutesHubData.title]/[subtitle]/etc. stay unused by design.
  List<RoutesHubFlowStep> _localizedSteps(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      (l10n.routes_step1Title, l10n.routes_step1Subtitle),
      (l10n.routes_step2Title, l10n.routes_step2Subtitle),
      (l10n.routes_step3Title, l10n.routes_step3Subtitle),
      (l10n.routes_step4Title, l10n.routes_step4Subtitle),
    ];
    return data.flowSteps.map((step) {
      final idx = step.step - 1;
      if (idx < 0 || idx >= labels.length) return step;
      final (title, subtitle) = labels[idx];
      return RoutesHubFlowStep(
        step: step.step,
        title: title,
        subtitle: subtitle,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () => context.read<RoutesHubCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppLayout.pagePaddingWithTop,
        children: [
          RoutesHubHero(title: l10n.nav_routes, subtitle: l10n.routes_heroSubtitle),
          const SizedBox(height: 24),
          RoutesHubSearchCard(
            title: l10n.home_whereAreYouGoing,
            description: l10n.routes_searchDescription,
            onSearch: () => onOpenAction(data.searchAction),
          ),
          const SizedBox(height: 16),
          RoutesHubOfficesCard(
            onTap: () =>
                onOpenAction(const RoutesHubAction(route: OfficesRoutes.directory)),
          ),
          const SizedBox(height: 32),
          ClientSectionHeader(title: l10n.routes_howItWorks),
          const SizedBox(height: 16),
          RoutesHubFlowSteps(steps: _localizedSteps(context)),
          const SizedBox(height: 28),
          AppButton.secondary(
            text: l10n.routes_browsePopularRoutes,
            icon: const Icon(Icons.trending_up_rounded, size: 18),
            onPressed: () => onOpenAction(data.popularRoutesAction),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
