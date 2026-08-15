import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import 'subscription_details_panel.dart';

/// Opens one subscriber's whole file as a modal sheet.
///
/// The board owns the full page width now, so the file can no longer sit beside
/// it in a permanent split — a pane that was empty most of the day and squeezed
/// the list into a third of the screen the rest of it. A sheet is what replaces
/// it: it covers the board while one subscriber is being read, and hands the
/// operator back the exact same scroll position and filters when it closes,
/// which a pushed route would not.
Future<void> openSubscriptionDetails(
  BuildContext context,
  String subscriptionId,
) {
  final cubit = context.read<SubscriptionsCubit>();

  // Opening is also a refetch: the sheet reports server truth, not whatever the
  // list last cached.
  cubit.loadDetails(subscriptionId);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 960),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusSheet),
      ),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: SubscriptionDetailsSheet(subscriptionId: subscriptionId),
    ),
  ).whenComplete(() {
    // Dismissal is what drops the selection, however it happened — close
    // button, drag or scrim — so the card highlight never outlives the sheet.
    if (!cubit.isClosed) cubit.select(null);
  });
}

/// The sheet body: everything known about one subscriber, kept live against the
/// cubit for as long as it is open.
class SubscriptionDetailsSheet extends StatelessWidget {
  const SubscriptionDetailsSheet({super.key, required this.subscriptionId});

  /// Held as an id, not as an entity: every office action refetches the whole
  /// book, so the sheet has to follow the *fresh* row rather than pin the copy
  /// that happened to be on screen when the card was tapped.
  final String subscriptionId;

  /// Near full height — the file is long (account, ride ledger, origin,
  /// operations) and a half sheet turns it into a peephole.
  static const double heightFactor = 0.94;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * heightFactor,
      // The sheet hosts its own messenger: feedback posted to the page behind it
      // would render under the scrim, where nobody sees the outcome of the
      // action they just ran from here.
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BlocConsumer<SubscriptionsCubit, SubscriptionsState>(
            listenWhen: (previous, current) =>
                current is SubscriptionsLoaded &&
                (current.actionError != null || current.actionMessage != null),
            listener: (context, state) {
              if (state is! SubscriptionsLoaded) return;
              final error = state.actionError;
              final message = state.actionMessage;
              if (error != null) {
                AppSnackbar.error(context, error);
              } else if (message != null) {
                AppSnackbar.success(context, message);
              }
            },
            builder: (context, state) {
              if (state is! SubscriptionsLoaded) {
                return const SizedBox.shrink();
              }

              final subscription = _find(state);
              if (subscription == null) return const _MissingSubscriber();

              return Column(
                children: [
                  SizedBox(
                    height: 2,
                    child: state.isProcessing
                        ? const LinearProgressIndicator(minHeight: 2)
                        : null,
                  ),
                  Expanded(
                    child: SubscriptionDetailsPanel(
                      subscription: subscription,
                      state: state,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  UserSubscription? _find(SubscriptionsLoaded state) {
    for (final subscription in state.subscriptions) {
      if (subscription.id == subscriptionId) return subscription;
    }
    return null;
  }
}

/// The row left the book while the sheet was open — a refetch after an action
/// that removed it. Better to say so than to keep showing a stale file.
class _MissingSubscriber extends StatelessWidget {
  const _MissingSubscriber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            emoji: '🗂️',
            title: 'لم يعد هذا الاشتراك متاحًا',
            subtitle: 'تم تحديث القائمة ولم يعد هذا الاشتراك ضمنها.',
          ),
          const SizedBox(height: AppSpacing.medium),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            label: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
