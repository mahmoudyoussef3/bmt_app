import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_state.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: switch (state) {
              ProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ProfileError(:final message) => EmptyState(
                title: 'Profile unavailable',
                subtitle: message,
              ),
              ProfileLoaded(:final data) => ListView(
                padding: AppLayout.pagePaddingWithTop,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(AppLayout.spaceLg),
                    child: Row(
                      children: [
                        AppAvatar(
                          initials: data.profile.initials,
                          radius: 28,
                          backgroundColor: scheme.primary,
                        ),
                        const SizedBox(width: AppLayout.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.profile.name,
                                style: AppTypography.heading(scheme),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.profile.email,
                                style: AppTypography.caption(scheme),
                              ),
                            ],
                          ),
                        ),
                        AppBadge(text: data.profile.badge),
                      ],
                    ),
                  ),
                  for (final section in data.sections) ...[
                    const SizedBox(height: AppLayout.spaceXl),
                    SectionHeader(title: section.title),
                    const SizedBox(height: AppLayout.spaceSm),
                    for (final item in section.items) ...[
                      ProfileHubTile(
                        icon: _iconForMenuItem(item),
                        title: item.title,
                        subtitle: item.subtitle,
                        onTap: () {
                          if (item.route == null) return;
                          widget.onOpenRoute(item.route!);
                        },
                      ),
                      const SizedBox(height: AppLayout.spaceSm),
                    ],
                  ],
                  const SizedBox(height: AppLayout.spaceLg),
                  const _DevVersionSwitcher(),
                  const SizedBox(height: 120),
                ],
              ),
            },
          ),
        );
      },
    );
  }

  IconData _iconForMenuItem(ProfileMenuItem item) {
    return switch (item.iconKey) {
      'person' => Icons.person_outline_rounded,
      'trips' => Icons.luggage_rounded,
      'packages' => Icons.card_membership_outlined,
      'search' => Icons.search_rounded,
      'wallet' => Icons.account_balance_wallet_outlined,
      'rewards' => Icons.emoji_events_outlined,
      'loyalty' => Icons.stars_outlined,
      'support' => Icons.support_agent_outlined,
      'messages' => Icons.chat_bubble_outline_rounded,
      'settings' => Icons.settings_outlined,
      'terms' || _ => Icons.description_outlined,
    };
  }
}

class _DevVersionSwitcher extends StatelessWidget {
  const _DevVersionSwitcher();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppModeCubit>();
    final current = cubit.state.mode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developer',
            style: AppTypography.caption(
              Theme.of(context).colorScheme,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppLayout.spaceSm),
          Text(
            'Switch app mode (dev only)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppLayout.spaceSm),
          Wrap(
            spacing: AppLayout.spaceSm,
            runSpacing: AppLayout.spaceSm,
            children: AppMode.values.map((m) {
              final active = m == current;
              return FilterChip(
                label: Text(m.displayLabel),
                selected: active,
                onSelected: (_) {
                  if (!active) cubit.changeMode(m);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
