import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_routes.dart';
import 'package:bmt_app/features/component/presentation/widgets/ui/profile_hub_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: ListView(
          padding: AppLayout.pagePaddingWithTop,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppLayout.spaceLg),
              child: Row(
                children: [
                  AppAvatar(initials: 'AH', radius: 28,
                  backgroundColor: scheme.primary,),
                  const SizedBox(width: AppLayout.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ahmed Hassan',
                          style: AppTypography.heading(scheme),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ahmed.hassan@company.com',
                          style: AppTypography.caption(scheme),
                        ),
                      ],
                    ),
                  ),
                  const AppBadge(text: 'Premium'),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            const SectionHeader(title: 'Account'),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.person_outline_rounded,
              title: 'Account details',
              subtitle: 'Employee ID · Operations',
              onTap: () {},
            ),
            const SizedBox(height: AppLayout.spaceXl),
            const SectionHeader(title: 'Travel'),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.luggage_rounded,
              title: 'My trips',
              subtitle: 'Upcoming, active & history',
              onTap: () => onOpenRoute(TripsRoutes.myTrips),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.card_membership_outlined,
              title: 'Packages',
              subtitle: 'Monthly & weekly plans',
              onTap: () => onOpenRoute('/subscription'),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.search_rounded,
              title: 'Book a route',
              subtitle: 'Search trips & vehicles',
              onTap: () => onOpenRoute(BookingRoutes.search),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            const SectionHeader(title: 'Wallet & rewards'),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'EGP 240.00 available',
              onTap: () => onOpenRoute('/payment-demo'),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.emoji_events_outlined,
              title: 'Rewards',
              subtitle: '1,250 points · Refer friends',
              onTap: () => onOpenRoute('/rewards'),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.stars_outlined,
              title: 'Loyalty',
              subtitle: 'Tier benefits & perks',
              onTap: () => onOpenRoute('/loyalty'),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            const SectionHeader(title: 'Support'),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.support_agent_outlined,
              title: 'Help center',
              subtitle: 'FAQs, chat & tickets',
              onTap: () => onOpenRoute('/support'),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Messages',
              subtitle: 'Driver & support chat',
              onTap: () => onOpenRoute('/communication'),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            const SectionHeader(title: 'Settings & legal'),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Preferences & security',
              onTap: () => onOpenRoute('/settings'),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            ProfileHubTile(
              icon: Icons.description_outlined,
              title: 'Terms & privacy',
              subtitle: 'Legal information',
              onTap: () {},
            ),
            const SizedBox(height: AppLayout.spaceLg),
            const _DevVersionSwitcher(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
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
