import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_state.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_content.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_loading_skeleton.dart';
import 'package:bmt_app/core/localization/failure_l10n_ext.dart';

/// Client home — the passenger's launchpad.
///
/// Renders one of three states:
/// - loading: branded skeleton mirroring the real layout
/// - error: full-screen retryable error
/// - loaded: hero search canvas + operational sections ([HomeContent])
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenRoute,
    required this.onOpenNotifications,
  });

  final void Function(String route, [Object? arguments]) onOpenRoute;
  final VoidCallback onOpenNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Realtime keeps Home in sync while the app is active; this is the
  /// fallback for a missed event or a reconnect after being offline.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          current is HomeLoaded && current.refreshFailure != null,
      listener: (context, state) {
        final failure = (state as HomeLoaded).refreshFailure!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(failure.localizedMessage(context)),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => context.read<HomeCubit>().load(),
              ),
            ),
          );
      },
      builder: (context, state) {
        return switch (state) {
          HomeLoaded(:final data) => HomeContent(
            data: data,
            onOpenRoute: widget.onOpenRoute,
            onOpenNotifications: widget.onOpenNotifications,
          ),
          HomeError(:final failure) => ColoredBox(
            color: ClientColors.backgroundFor(context),
            child: SafeArea(
              child: ClientErrorCard.fullScreen(
                message: failure.localizedMessage(context),
                onRetry: () => context.read<HomeCubit>().load(),
              ),
            ),
          ),
          HomeLoading() => const HomeLoadingSkeleton(),
        };
      },
    );
  }
}
