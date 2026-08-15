import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../../../core/widgets/dashboard_state_views.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import 'licensing_widgets.dart';

/// The frame every licensing screen shares.
///
/// It exists to enforce one rule the dashboard design system already states and
/// this module must not break: **an action error never replaces the screen.**
/// A failed load shows the error view; a failed action shows a snackbar over
/// whatever the operator was editing, so the form they mistyped is still there.
class LicensingScreenFrame extends StatelessWidget {
  const LicensingScreenFrame({super.key, required this.builder});

  final Widget Function(BuildContext, PlatformLicensingLoaded) builder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformLicensingCubit, PlatformLicensingState>(
      listenWhen: (previous, current) =>
          current is PlatformLicensingLoaded &&
          (current.actionError != null || current.actionMessage != null),
      listener: (context, state) {
        if (state is! PlatformLicensingLoaded) return;
        final error = state.actionError;
        final message = state.actionMessage;
        if (error != null) {
          showLicensingFeedback(
            context,
            PlatformLicensingFeedback(error, isError: true),
          );
        } else if (message != null) {
          showLicensingFeedback(context, PlatformLicensingFeedback(message));
        }
      },
      builder: (context, state) => switch (state) {
        PlatformLicensingLoading() ||
        PlatformLicensingInitial() => const DashboardLoading(),
        PlatformLicensingError(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<PlatformLicensingCubit>().load(),
        ),
        PlatformLicensingLoaded() => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: builder(context, state),
            ),

            if (state.isBusy)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      },
    );
  }
}
