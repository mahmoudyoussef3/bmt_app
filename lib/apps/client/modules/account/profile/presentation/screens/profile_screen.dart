import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/modules/account/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/modules/account/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/modules/account/profile/presentation/cubit/profile_state.dart';
import 'package:bmt_app/apps/client/modules/account/profile/presentation/widgets/profile_hub_tile.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: switch (state) {
              ProfileLoading() => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ClientSkeleton(height: 100, borderRadius: 24),
                  const SizedBox(height: 24),
                  ClientSkeleton(height: 56, borderRadius: 14),
                  const SizedBox(height: 8),
                  ClientSkeleton(height: 56, borderRadius: 14),
                  const SizedBox(height: 8),
                  ClientSkeleton(height: 56, borderRadius: 14),
                ],
              ),
              ProfileError(:final message) => ClientErrorCard.fullScreen(
                message: message,
                onRetry: () => context.read<ProfileCubit>().load(),
              ),
              ProfileLoaded(:final data) => ListView(
                padding: AppLayout.pagePaddingWithTop,
                children: [
                  // ── Premium profile header ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ClientColors.primary, Color(0xFF1554C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              data.profile.initials,
                              style: ClientTypography.headingMedium(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.profile.name,
                                style: ClientTypography.headingSmall(
                                  context,
                                ).copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.profile.email,
                                style: ClientTypography.bodySmall(
                                  context,
                                ).copyWith(color: Colors.white.withAlpha(200)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Sections ────────────────────────────────────────────
                  for (final section in data.sections) ...[
                    const SizedBox(height: AppLayout.spaceXl),
                    ClientSectionHeader(title: section.title),
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
    return BlocBuilder<AppModeCubit, AppModeState>(
      builder: (context, state) {
        final cubit = context.read<AppModeCubit>();
        final current = state.mode;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Developer',
                style: ClientTypography.bodySmall(
                  context,
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
      },
    );
  }
}
