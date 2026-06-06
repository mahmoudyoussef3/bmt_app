import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/routes_hub_data.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_state.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/section_header.dart';

/// Routes tab — focused entry into the booking search flow.
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
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return BlocBuilder<RoutesHubCubit, RoutesHubState>(
      builder: (context, state) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: switch (state) {
              RoutesHubLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              RoutesHubError(:final message) => EmptyState(
                title: 'Routes unavailable',
                subtitle: message,
              ),
              RoutesHubLoaded(:final data) => ListView(
                padding: AppLayout.pagePaddingWithTop,
                children: [
                  Text(data.title, style: AppTypography.display(scheme)),
                  const SizedBox(height: AppLayout.spaceSm),
                  Text(
                    data.subtitle,
                    style: AppTypography.caption(
                      scheme,
                    ).copyWith(color: scheme.onSurface.withAlpha(180)),
                  ),
                  const SizedBox(height: AppLayout.spaceXl),
                  AppCard(
                    padding: const EdgeInsets.all(AppLayout.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 40,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: AppLayout.spaceMd),
                        Text(
                          data.searchTitle,
                          style: AppTypography.heading(scheme),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppLayout.spaceSm),
                        Text(
                          data.searchDescription,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(
                            scheme,
                          ).copyWith(color: scheme.onSurface.withAlpha(170)),
                        ),
                        const SizedBox(height: AppLayout.spaceLg),
                        AppButton(
                          label: 'Search Trip',
                          height: 52,
                          onPressed: () => _openAction(data.searchAction),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceXl),
                  const SectionHeader(
                    title: 'How booking works',
                    subtitle: 'A simple path from search to seat',
                  ),
                  const SizedBox(height: AppLayout.spaceMd),
                  for (final step in data.flowSteps)
                    _FlowStep(
                      step: step.step,
                      title: step.title,
                      subtitle: step.subtitle,
                      isLast: step.step == data.flowSteps.length,
                    ),
                  const SizedBox(height: AppLayout.spaceLg),
                  OutlinedButton.icon(
                    onPressed: () => _openAction(data.popularRoutesAction),
                    icon: const Icon(Icons.trending_up_rounded),
                    label: const Text('Browse popular routes'),
                  ),
                  const SizedBox(height: 120),
                ],
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

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.step,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primary.withAlpha(50),
                child: Text(
                  '$step',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outline.withAlpha(100),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppLayout.spaceMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppLayout.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subheading(scheme)),
                  Text(subtitle, style: AppTypography.caption(scheme)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
