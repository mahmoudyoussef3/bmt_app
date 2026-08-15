import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';

/// One office as the platform sees it, with the two levers that act on it.
///
/// Listing and status are deliberately separate controls, because they answer
/// different questions: withdrawing a listing hides an office from passengers
/// while its staff keep working; suspending it locks the staff and its captains
/// out. Collapsing them into one toggle would make the milder action look like
/// the severe one.
class PlatformOfficeCard extends StatelessWidget {
  const PlatformOfficeCard({
    super.key,
    required this.office,
    required this.isBusy,
    required this.isSelected,
    required this.onOpen,
    required this.onSetListing,
    required this.onSetStatus,
    this.metrics,
    this.onOpenFeatures,
  });

  final PlatformOffice office;

  /// This office's activity, or null while the analytics call is in flight.
  /// The card renders fully without it — the configuration half of the card
  /// does not depend on the measuring half.
  final PlatformOfficeMetrics? metrics;

  final bool isBusy;

  /// Whether this office's details panel is the one currently open.
  final bool isSelected;

  final VoidCallback onOpen;

  /// Jumps to this office's feature board in التراخيص — what it can use, and
  /// how much of it. Null where the console cannot reach that screen, so the
  /// card keeps working in a harness that mounts it alone.
  final VoidCallback? onOpenFeatures;

  final ValueChanged<String> onSetListing;
  final ValueChanged<String> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Flexible(
                          child: Text(
                            office.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? scheme.primary : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      office.slug,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (office.ownerLabel case final owner?)
                      Text(
                        'المالك: $owner',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.xSmall,
                children: [
                  if (metrics case final m?)
                    StatusChip(
                      label: m.activityLevel.label,
                      color: switch (m.activityLevel) {
                        ActivityLevel.active => scheme.primary.withAlpha(18),
                        ActivityLevel.idle => scheme.tertiary.withAlpha(28),
                        ActivityLevel.never => scheme.surfaceContainerHighest,
                      },
                      textColor: switch (m.activityLevel) {
                        ActivityLevel.active => scheme.primary,
                        ActivityLevel.idle => scheme.tertiary,
                        ActivityLevel.never => scheme.onSurfaceVariant,
                      },
                    ),
                  StatusChip(
                    label: office.listingLabel,
                    color: office.isListed
                        ? scheme.primary.withAlpha(18)
                        : scheme.surfaceContainerHighest,
                    textColor: office.isListed
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  StatusChip(
                    label: office.statusLabel,
                    color: office.status == 'active'
                        ? scheme.primary.withAlpha(18)
                        : scheme.errorContainer.withAlpha(80),
                    textColor: office.status == 'active'
                        ? scheme.primary
                        : scheme.error,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.xSmall,
            children: [
              _Stat(label: 'مشغّلون', value: office.operators),
              _Stat(label: 'سائقون', value: office.drivers),
              _Stat(label: 'مركبات', value: office.vehicles),
              _Stat(label: 'مسارات', value: office.routes),
              _Stat(label: 'رحلات', value: office.trips),
            ],
          ),

          if (metrics case final m?) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Wrap(
              spacing: AppSpacing.large,
              runSpacing: AppSpacing.xSmall,
              children: [
                _Metric(label: 'إيراد المدة', value: m.revenueRecentLabel),
                _Metric(label: 'حجوزات المدة', value: '${m.recentBookings}'),
                _Metric(label: 'رحلات قادمة', value: '${m.upcomingTrips}'),
                if (m.occupancyLabel case final occupancy?)
                  _Metric(label: 'إشغال', value: occupancy),
                if (m.averageRating case final rating?)
                  _Metric(
                    label: 'تقييم',
                    value: '${rating.toStringAsFixed(1)} ★',
                  ),
              ],
            ),
            if (_activityNote(m) case final note?) ...[
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                note,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.tertiary),
              ),
            ],
          ],
          if (office.missingProfileFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'اكتمال الملف '
              '${office.completedProfileFields}/${office.totalProfileFields}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (office.serviceAreas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              office.serviceAreas.join('، '),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (!office.canBeListed && !office.isListed) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'قبل العرض في السوق: ${office.blockersToListing.join('، ')}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              if (onOpenFeatures case final open?)
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : open,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('الميزات والحدود'),
                ),
              if (office.isListed)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => onSetListing('unlisted'),
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('سحب من السوق'),
                )
              else
                FilledButton.icon(
                  onPressed: isBusy || !office.canBeListed
                      ? null
                      : () => onSetListing('listed'),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('عرض في السوق'),
                ),
              if (office.status == 'active')
                TextButton.icon(
                  onPressed: isBusy ? null : () => _confirmSuspend(context),
                  icon: Icon(
                    Icons.block_outlined,
                    size: 18,
                    color: scheme.error,
                  ),
                  label: Text('إيقاف', style: TextStyle(color: scheme.error)),
                )
              else
                TextButton.icon(
                  onPressed: isBusy ? null : () => onSetStatus('active'),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('تفعيل'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The single most useful sentence about this office's activity, or null when
  /// there is nothing worth saying.
  ///
  /// One line, not a list: the card is a triage surface, and the full set of
  /// findings for an office belongs in the attention queue above and the details
  /// panel beside it. Ordered by severity so the worst thing is the thing shown.
  String? _activityNote(PlatformOfficeMetrics metrics) {
    if (office.isListed && metrics.upcomingTrips == 0) {
      return 'معروض في السوق بلا رحلات متاحة للحجز.';
    }
    if (metrics.paymentsAwaitingReview > 0) {
      return '${metrics.paymentsAwaitingReview} عملية دفع بانتظار المراجعة '
          '(${metrics.awaitingAmountLabel}).';
    }
    if (metrics.staleTrips > 0) {
      return '${metrics.staleTrips} رحلة فات موعدها وما زالت مفتوحة.';
    }
    if (metrics.isIdle) {
      final days = metrics.daysSinceLastBooking;
      return days == null ? 'لا نشاط خلال المدة.' : 'آخر حجز منذ $days يوم.';
    }
    return null;
  }

  /// Suspension signs the office's whole staff out and blocks its captains, so
  /// it asks first. Publishing does not: it is reversible in one click.
  Future<void> _confirmSuspend(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إيقاف المكتب'),
        content: Text(
          'سيُمنع مسؤولو «${office.name}» وكباتنه من الدخول، وستختفي رحلاته '
          'من تطبيق العملاء. يمكن التراجع لاحقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
    if (confirmed == true) onSetStatus('suspended');
  }
}

/// The activity counterpart to [_Stat]: same shape, but takes a preformatted
/// string, because money and percentages are not integers.
class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
