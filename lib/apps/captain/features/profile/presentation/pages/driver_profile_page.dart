import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_root_header.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../domain/entities/driver_profile.dart';
import '../cubit/driver_profile_cubit.dart';
import '../cubit/driver_profile_state.dart';
import '../widgets/driver_profile_identity_card.dart';
import '../widgets/driver_profile_info_card.dart';
import '../widgets/driver_profile_settings_card.dart';
import '../widgets/driver_profile_sign_out_button.dart';
import '../widgets/driver_profile_skeleton.dart';
import '../widgets/driver_profile_stats_card.dart';
import '../widgets/driver_profile_vehicle_card.dart';
import '../widgets/verification_card.dart';

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: BlocBuilder<DriverProfileCubit, DriverProfileState>(
        builder: (context, state) => switch (state) {
          DriverProfileLoading() => const DriverProfileSkeleton(),
          DriverProfileError(:final message) => _ErrorBody(message: message),
          DriverProfileLoaded(:final profile) => _ProfileBody(profile: profile),
        },
      ),
    );
  }
}

/// The page reads top-down as: who you are → what you have done → what you
/// drive → whether you are cleared to drive it → your record → the app.
///
/// The screen used to open straight into four identical grey groups, with the
/// captain's name shrunk into the toolbar and the trips and passengers the
/// repository already loaded never drawn at all. The identity block and the
/// stats strip are the two things that make it a *profile* rather than a
/// settings page; everything under them stays in the app's grouped-list idiom.
class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DriverProfileCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CaptainRootHeader(
            // The tab is named, not the captain: the name and the office now
            // have their own block below, and a toolbar title that changes per
            // user gives the tab no fixed identity to come back to.
            title: CaptainRootHeader.titleSubtitle(context, title: 'حسابي'),
            onNotificationsTap: () => context.openNotifications(),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s8,
              CaptainDesignTokens.s20,
              CaptainBottomNav.reservedSpace(context),
            ),
            sliver: SliverList.list(
              children: [
                DriverProfileIdentityCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s12),
                DriverProfileStatsCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s24),
                if (profile.hasVehicle) ...[
                  DriverProfileVehicleCard(profile: profile),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                VerificationCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s24),
                DriverProfileInfoCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s24),
                const DriverProfileSettingsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: AsyncStateView(
              status: AsyncViewStatus.error,
              errorMessage: message,
              onRetry: () => context.read<DriverProfileCubit>().load(),
              child: const SizedBox.shrink(),
            ),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s24,
              0,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s24,
            ),
            child: DriverProfileSignOutButton(
              variant: CaptainButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
