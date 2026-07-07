import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_section_header.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/routes_hub_data.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_state.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_flow_steps.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_hero.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_search_card.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/routes_hub_skeleton.dart';
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

    return BlocBuilder<RoutesHubCubit, RoutesHubState>(
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppLayout.pagePaddingWithTop,
      children: [
        RoutesHubHero(title: data.title, subtitle: data.subtitle),
        const SizedBox(height: 24),
        RoutesHubSearchCard(
          title: data.searchTitle,
          description: data.searchDescription,
          onSearch: () => onOpenAction(data.searchAction),
        ),
        const SizedBox(height: 32),
        const ClientSectionHeader(title: 'How it works'),
        const SizedBox(height: 16),
        RoutesHubFlowSteps(steps: data.flowSteps),
        const SizedBox(height: 28),
        AppButton.secondary(
          text: 'Browse popular routes',
          icon: const Icon(Icons.trending_up_rounded, size: 18),
          onPressed: () => onOpenAction(data.popularRoutesAction),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}
