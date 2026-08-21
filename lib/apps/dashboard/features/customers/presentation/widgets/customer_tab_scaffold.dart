import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../cubit/customer_profile_state.dart';

/// The loading / failed / loaded frame every lazily-loaded profile tab shares.
///
/// ## Why a failed tab does not take the page
///
/// The header and نظرة عامة came from a different request and are still true.
/// Replacing the whole workspace because المدفوعات timed out would throw away
/// the answer the operator may already have been reading, so the failure is
/// contained here and named in the header's partial-data notice as well.
///
/// ## Why a failed *refresh* keeps its rows
///
/// [CustomerTabStatus.loaded] stays true when a reload fails over data that
/// already arrived, so this shows the stale rows with the error above them
/// rather than blanking a list that is merely out of date.
class CustomerTabScaffold extends StatelessWidget {
  const CustomerTabScaffold({
    super.key,
    required this.status,
    required this.onRetry,
    required this.child,
    this.header,
    this.loadingRows = 4,
  });

  final CustomerTabStatus status;
  final VoidCallback onRetry;
  final Widget child;

  /// Controls that belong above the content and stay put across loads — the
  /// قادمة / سابقة switch, for one, which must not vanish while its own list
  /// is being fetched.
  final Widget? header;

  final int loadingRows;

  @override
  Widget build(BuildContext context) {
    if (status.failed) {
      return DashboardErrorState(
        title: 'تعذر تحميل هذا القسم',
        message: status.error!,
        onRetry: onRetry,
      );
    }

    // Covers both "fetching for the first time" and "selected but the request
    // has not started yet" — the cubit asks for the tab on selection, so the
    // second is a single frame rather than a resting state, and showing the
    // same skeleton for both keeps it from flickering between two treatments.
    if (!status.loaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          // Same reason as the frame: every tab renders inside the
          // workspace's ListView.
          DashboardLoading(
            rows: loadingRows,
            showHeader: false,
            scrollable: false,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.error != null) ...[
          _StaleNotice(message: status.error!, onRetry: onRetry),
          const SizedBox(height: AppSpacing.small),
        ],
        ?header,
        AnimatedOpacity(
          opacity: status.loading ? 0.55 : 1,
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
      ],
    );
  }
}

/// Shown when a refresh failed over rows that are already on screen: the data
/// below is real but may be out of date, which is a different message from
/// "this section is broken".
class _StaleNotice extends StatelessWidget {
  const _StaleNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'تعذر التحديث، والبيانات المعروضة قد تكون قديمة. $message',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
