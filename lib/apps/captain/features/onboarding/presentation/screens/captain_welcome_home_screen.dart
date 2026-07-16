import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_awaiting_trips_view.dart';

import '../cubit/captain_activation_cubit.dart';
import '../cubit/captain_activation_state.dart';
import '../widgets/captain_activation_error.dart';
import '../widgets/captain_identity_card.dart';

/// Landing home for a freshly-approved captain. While operations finishes
/// activating the driver record, this waits — polling in the background and on
/// pull-to-refresh — and hands over to the operational shell the moment the
/// captain can sign in, without any sign-out/sign-in round trip.
class CaptainWelcomeHomeScreen extends StatefulWidget {
  final CaptainLocalSession session;
  final Future<void> Function() onSignOut;

  const CaptainWelcomeHomeScreen({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  @override
  State<CaptainWelcomeHomeScreen> createState() =>
      _CaptainWelcomeHomeScreenState();
}

class _CaptainWelcomeHomeScreenState extends State<CaptainWelcomeHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CaptainActivationCubit>().start(widget.session.phone);
  }

  Future<void> _refresh() =>
      context.read<CaptainActivationCubit>().check(widget.session.phone);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: CaptainColors.backgroundFor(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('حسابي'),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<CaptainActivationCubit, CaptainActivationState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(CaptainDesignTokens.s16),
                  children: [
                    CaptainIdentityCard(session: widget.session),
                    if (state is CaptainActivationFailed) ...[
                      const SizedBox(height: CaptainDesignTokens.s16),
                      CaptainActivationError(
                        message: state.message,
                        onRetry: _refresh,
                      ),
                    ],
                    const SizedBox(height: CaptainDesignTokens.s24),
                    CaptainAwaitingTripsView(
                      onRefresh: _refresh,
                      isRefreshing: state is CaptainActivationChecking,
                      title: 'حسابك جاهز — بانتظار أول رحلة',
                      currentStepLabel:
                          'بانتظار تفعيل العمليات وإسناد أول رحلة لك',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
