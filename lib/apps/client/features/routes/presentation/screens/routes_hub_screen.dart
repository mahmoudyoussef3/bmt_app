import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_section_header.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/routes_hub_data.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_state.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

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
              RoutesHubLoading() => _LoadingBody(),
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

// ── Loading body ─────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppLayout.pagePaddingWithTop,
      children: [
        ClientSkeleton.routeCard(),
        const SizedBox(height: 16),
        ClientSkeleton.routeCard(),
        const SizedBox(height: 16),
        ClientSkeleton.routeCard(),
      ],
    );
  }
}

// ── Loaded body ──────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.data, required this.onOpenAction});

  final RoutesHubData data;
  final void Function(RoutesHubAction) onOpenAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppLayout.pagePaddingWithTop,
      children: [
        _GradientHeader(title: data.title, subtitle: data.subtitle),
        const SizedBox(height: 24),
        _SearchCtaCard(
          searchTitle: data.searchTitle,
          searchDescription: data.searchDescription,
          onSearch: () => onOpenAction(data.searchAction),
        ),
        const SizedBox(height: 32),
        ClientSectionHeader(title: 'How it works'),
        const SizedBox(height: 16),
        for (final step in data.flowSteps)
          _FlowStep(
            step: step.step,
            title: step.title,
            subtitle: step.subtitle,
            isLast: step.step == data.flowSteps.length,
          ),
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

// ── Gradient header ───────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withAlpha(220),
              scheme.secondary.withAlpha(210),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withAlpha(210),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _HeroTag(label: 'Fast discovery'),
                _HeroTag(label: 'Live availability'),
                _HeroTag(label: 'Premium routes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Search CTA card ───────────────────────────────────────────────────────────

class _SearchCtaCard extends StatelessWidget {
  const _SearchCtaCard({
    required this.searchTitle,
    required this.searchDescription,
    required this.onSearch,
  });

  final String searchTitle;
  final String searchDescription;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      searchTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      searchDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(170),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton.primary(text: 'Search trips', onPressed: onSearch),
        ],
      ),
    );
  }
}

// ── Flow step ─────────────────────────────────────────────────────────────────

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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: ClientColors.borderFor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClientTypography.headingSmall(
                      context,
                    ).copyWith(color: ClientColors.textPrimaryFor(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
