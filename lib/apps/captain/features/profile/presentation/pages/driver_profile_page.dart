import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../domain/entities/driver_profile.dart';
import '../cubit/driver_profile_cubit.dart';
import '../cubit/driver_profile_state.dart';
import '../widgets/driver_profile_header.dart';
import '../widgets/driver_profile_info_card.dart';
import '../widgets/driver_profile_settings_card.dart';
import '../widgets/driver_profile_sign_out_button.dart';
import '../widgets/driver_profile_skeleton.dart';
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
          DriverProfileHeader(profile: profile),
          SliverPadding(
            // Groups sit closer to the screen edge than the old framed cards
            // did: they read as full-width list sections, not as objects
            // floating on a page.
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s20,
              // Cleared for the shell's floating nav bar.
              CaptainBottomNav.reservedSpace(context),
            ),
            sliver: SliverList.list(
              children: [
                // The vehicle leads: it is the one thing a captain opens this
                // screen mid-shift to check.
                if (profile.hasVehicle) ...[
                  DriverProfileVehicleCard(profile: profile),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                VerificationCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s24),
                DriverProfileInfoCard(profile: profile),
                const SizedBox(height: CaptainDesignTokens.s24),
                // Sign-out is the last row of this group.
                const DriverProfileSettingsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sign-out stays reachable here on purpose: if the profile can't load, the
/// captain would otherwise be stranded on this tab with no way out of a bad
/// session.
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
