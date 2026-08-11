import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_details.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// One office in full, for the platform admin deciding what to do about it.
///
/// Organised so the two questions that matter are answerable without scrolling
/// past each other: *is this office real* (identity, operators, activity) and
/// *what do passengers see* (listing state, and the actual marketplace card).
class PlatformOfficeDetailsPanel extends StatelessWidget {
  const PlatformOfficeDetailsPanel({
    super.key,
    required this.officeName,
    required this.details,
    required this.isLoading,
    required this.error,
    required this.isBusy,
    required this.onClose,
    required this.onRetry,
    required this.onSetListing,
    required this.onSetStatus,
    this.metrics,
    this.windowDays = 30,
  });

  /// Shown while [details] is still null, so the panel names the office the
  /// operator picked rather than opening blank.
  final String officeName;
  final PlatformOfficeDetails? details;

  /// This office's windowed activity, or null when analytics has not loaded.
  /// The performance section is omitted entirely in that case — the rest of the
  /// panel comes from a different RPC and does not wait on it.
  final PlatformOfficeMetrics? metrics;
  final int windowDays;
  final bool isLoading;
  final String? error;
  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final ValueChanged<String> onSetListing;
  final ValueChanged<String> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final loaded = details;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          title: loaded?.office.name ?? officeName,
          subtitle: loaded?.office.slug,
          onClose: onClose,
        ),
        const SizedBox(height: AppSpacing.small),
        if (isLoading && loaded == null)
          const DashboardLoading(rows: 3, showHeader: false, scrollable: false)
        else if (error != null && loaded == null)
          DashboardErrorState(message: error!, onRetry: onRetry)
        else if (loaded != null)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                
                if (error != null) ...[
                  _InlineNotice(message: error!, isError: true),
                  const SizedBox(height: AppSpacing.small),
                ],
                _IdentitySection(details: loaded),
                const SizedBox(height: AppSpacing.medium),
                _OperationalSection(details: loaded),
                const SizedBox(height: AppSpacing.medium),
                
                if (metrics case final m?) ...[
                  _PerformanceSection(
                    metrics: m,
                    office: loaded.office,
                    windowDays: windowDays,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
                _MarketplaceSection(
                  details: loaded,
                  isBusy: isBusy,
                  onSetListing: onSetListing,
                  onSetStatus: onSetStatus,
                ),
                const SizedBox(height: AppSpacing.medium),
                _OperatorsSection(operators: loaded.operators),
              ],
            ),
          ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if ((subtitle ?? '').isNotEmpty)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'إغلاق',
        ),
      ],
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.details});

  final PlatformOfficeDetails details;

  @override
  Widget build(BuildContext context) {
    final office = details.office;
    final scheme = Theme.of(context).colorScheme;

    return _Section(
      title: 'بيانات المكتب',
      icon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OfficeLogo(logoUrl: office.logoUrl, name: office.name),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      office.description.trim().isEmpty
                          ? 'لا يوجد وصف للمكتب'
                          : office.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: office.description.trim().isEmpty
                            ? scheme.error
                            : null,
                        fontStyle: office.description.trim().isEmpty
                            ? FontStyle.italic
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _KeyValue(label: 'الهاتف', value: office.phone),
                    _KeyValue(label: 'البريد الإلكتروني', value: office.email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'مناطق الخدمة',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          if (office.serviceAreas.isEmpty)
            Text(
              'لم تُحدَّد مناطق خدمة',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            )
          else
            Wrap(
              spacing: AppSpacing.xSmall,
              runSpacing: AppSpacing.xSmall,
              children: [
                for (final area in office.serviceAreas)
                  StatusChip(
                    label: area,
                    color: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.medium),
          _ProfileCompleteness(office: office),
        ],
      ),
    );
  }
}

/// How full the office's marketplace card is.
///
/// Shows more than the publish guard checks: an office can satisfy the guard and
/// still reach passengers as a card with no logo and no phone number. The bar is
/// the warning the guard cannot give.
class _ProfileCompleteness extends StatelessWidget {
  const _ProfileCompleteness({required this.office});

  final PlatformOffice office;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = office.missingProfileFields;
    final ratio = office.profileCompleteness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'اكتمال الملف',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '${office.completedProfileFields}/${office.totalProfileFields}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            color: ratio == 1 ? scheme.primary : scheme.tertiary,
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'ناقص: ${missing.join('، ')}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _OperationalSection extends StatelessWidget {
  const _OperationalSection({required this.details});

  final PlatformOfficeDetails details;

  @override
  Widget build(BuildContext context) {
    final office = details.office;
    final counts = details.counts;
    final scheme = Theme.of(context).colorScheme;

    return _Section(
      title: 'التشغيل',
      icon: Icons.insights_outlined,
      trailing: StatusChip(
        label: office.statusLabel,
        color: office.status == 'active'
            ? scheme.primary.withAlpha(18)
            : scheme.errorContainer.withAlpha(80),
        textColor: office.status == 'active' ? scheme.primary : scheme.error,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.medium,
            children: [
              _Metric(label: 'المسارات', value: counts.routes),
              _Metric(label: 'الرحلات', value: counts.trips),
              _Metric(label: 'الحجوزات', value: counts.bookings),
              _Metric(label: 'الكباتن', value: counts.drivers),
              _Metric(label: 'المركبات', value: counts.vehicles),
              _Metric(label: 'المشغّلون', value: counts.operators),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _KeyValue(label: 'تاريخ الإنشاء', value: _date(office.createdAt)),
          _KeyValue(label: 'آخر تحديث', value: _date(office.updatedAt)),
          if (!counts.hasTraded) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'لم يُسجَّل أي نشاط تشغيلي لهذا المكتب بعد.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the office actually did, as against what it owns.
///
/// Every figure above this section is a lifetime total or a piece of
/// configuration; every figure in it is bounded by the analytics window, and
/// the section says so in its own subtitle so the two can never be read as the
/// same kind of number.
class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({
    required this.metrics,
    required this.office,
    required this.windowDays,
  });

  final PlatformOfficeMetrics metrics;
  final PlatformOffice office;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = metrics.activityLevel;

    return _Section(
      title: 'الأداء خلال $windowDays يوم',
      icon: Icons.query_stats_outlined,
      trailing: StatusChip(
        label: level.label,
        color: switch (level) {
          ActivityLevel.active => scheme.primary.withAlpha(18),
          ActivityLevel.idle => scheme.tertiary.withAlpha(28),
          ActivityLevel.never => scheme.surfaceContainerHighest,
        },
        textColor: switch (level) {
          ActivityLevel.active => scheme.primary,
          ActivityLevel.idle => scheme.tertiary,
          ActivityLevel.never => scheme.onSurfaceVariant,
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.medium,
            children: [
              _Metric(
                label: 'الإيراد المعتمد',
                valueText: metrics.revenueRecentLabel,
              ),
              _Metric(label: 'الحجوزات', value: metrics.recentBookings),
              _Metric(label: 'الرحلات', value: metrics.recentTrips),
              _Metric(label: 'رحلات قادمة', value: metrics.upcomingTrips),
              if (metrics.occupancyLabel case final occupancy?)
                _Metric(label: 'إشغال المقاعد', valueText: occupancy),
              _Metric(label: 'تقييمات جديدة', value: metrics.recentReviews),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _KeyValue(
            label: 'الإيراد الإجمالي',
            value: metrics.revenueTotalLabel,
          ),
          if (metrics.averageBookingValue case final average?)
            _KeyValue(label: 'متوسط قيمة الحجز', value: formatMoney(average)),
          _KeyValue(
            label: 'نسبة الإلغاء',
            value:
                '${metrics.cancellationRateLabel} '
                '(${metrics.cancelledBookings} من ${metrics.totalBookings})',
          ),
          if (metrics.averageRating case final rating?)
            _KeyValue(
              label: 'متوسط تقييم المكتب',
              value:
                  '${rating.toStringAsFixed(1)} من 5 '
                  '(${metrics.reviewsTotal} تقييم)',
            ),
          _KeyValue(
            label: 'آخر حجز',
            value: switch (metrics.daysSinceLastBooking) {
              null => 'لا يوجد',
              0 => 'اليوم',
              final days => 'منذ $days يوم',
            },
          ),
          _KeyValue(label: 'أول حجز', value: _date(metrics.firstBookingAt)),
          const SizedBox(height: AppSpacing.small),
          
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.xSmall,
            children: [
              _Pending(
                label: 'مدفوعات بانتظار المراجعة',
                value:
                    '${metrics.paymentsAwaitingReview} '
                    '(${metrics.awaitingAmountLabel})',
                isAlert: metrics.paymentsAwaitingReview > 0,
              ),
              _Pending(
                label: 'رحلات فات موعدها',
                value: '${metrics.staleTrips}',
                isAlert: metrics.staleTrips > 0,
              ),
              _Pending(
                label: 'تذاكر دعم مفتوحة',
                value: '${metrics.openTickets}',
                isAlert: metrics.openTickets > 0,
              ),
              _Pending(
                label: 'طلبات كباتن معلقة',
                value: '${metrics.pendingCaptainRequests}',
                isAlert: metrics.pendingCaptainRequests > 0,
              ),
            ],
          ),
          if (office.isListed && metrics.upcomingTrips == 0) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'هذا المكتب معروض في سوق العملاء بلا رحلة واحدة متاحة للحجز — '
              'كل عميل يفتحه الآن يصل إلى صفحة فارغة.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({
    required this.label,
    required this.value,
    required this.isAlert,
  });

  final String label;
  final String value;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isAlert
              ? Icons.pending_actions_outlined
              : Icons.check_circle_outline_rounded,
          size: 16,
          color: isAlert ? scheme.tertiary : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isAlert ? scheme.tertiary : scheme.onSurfaceVariant,
            fontWeight: isAlert ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

class _MarketplaceSection extends StatelessWidget {
  const _MarketplaceSection({
    required this.details,
    required this.isBusy,
    required this.onSetListing,
    required this.onSetStatus,
  });

  final PlatformOfficeDetails details;
  final bool isBusy;
  final ValueChanged<String> onSetListing;
  final ValueChanged<String> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final office = details.office;
    final scheme = Theme.of(context).colorScheme;
    final absence = details.marketplaceAbsenceReason;

    return _Section(
      title: 'السوق',
      icon: Icons.storefront_outlined,
      trailing: StatusChip(
        label: office.listingLabel,
        color: office.isListed
            ? scheme.primary.withAlpha(18)
            : scheme.surfaceContainerHighest,
        textColor: office.isListed ? scheme.primary : scheme.onSurfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.medium,
            children: [
              _Metric(
                label: 'التقييم',
                valueText: office.ratingsCount == 0
                    ? '—'
                    : office.rating.toStringAsFixed(1),
              ),
              _Metric(label: 'عدد التقييمات', value: office.ratingsCount),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _KeyValue(label: 'تاريخ العرض', value: _date(office.listedAt)),
          const SizedBox(height: AppSpacing.medium),

          Text(
            'كما يراه العميل',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          if (details.marketplace case final preview?)
            _MarketplacePreviewCard(preview: preview)
          else
            _InlineNotice(
              message: absence ?? 'المكتب غير معروض في سوق العملاء.',
              isError: false,
            ),

          const SizedBox(height: AppSpacing.medium),
          _ListingActions(
            office: office,
            isBusy: isBusy,
            onSetListing: onSetListing,
            onSetStatus: onSetStatus,
          ),
        ],
      ),
    );
  }
}

/// The office's marketplace card, rendered from `public_offices` only.
///
/// Deliberately shows nothing the view does not carry — no phone, no email, no
/// operational status — so what the platform admin previews is what a passenger
/// gets, rather than a richer version only this screen can see.
class _MarketplacePreviewCard extends StatelessWidget {
  const _MarketplacePreviewCard({required this.preview});

  final PlatformOfficeMarketplacePreview preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OfficeLogo(logoUrl: preview.logoUrl, name: preview.name, size: 44),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (preview.description.trim().isNotEmpty)
                  Text(
                    preview.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: AppSpacing.xSmall),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: scheme.tertiary),
                    const SizedBox(width: 2),
                    Text(
                      preview.ratingsCount == 0
                          ? 'لا توجد تقييمات بعد'
                          : '${preview.rating.toStringAsFixed(1)} (${preview.ratingsCount})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (preview.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    preview.serviceAreas.join('، '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Publish / withdraw / suspend, on the same two axes as the list card.
///
/// Calls the same cubit methods the card does, which reach the same
/// `platform_set_office_listing` RPC — there is no second listing path here.
class _ListingActions extends StatelessWidget {
  const _ListingActions({
    required this.office,
    required this.isBusy,
    required this.onSetListing,
    required this.onSetStatus,
  });

  final PlatformOffice office;
  final bool isBusy;
  final ValueChanged<String> onSetListing;
  final ValueChanged<String> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!office.canBeListed && !office.isListed) ...[
          _InlineNotice(
            message:
                'قبل العرض في السوق: ${office.blockersToListing.join('، ')}',
            isError: true,
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [
            if (office.isListed)
              OutlinedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => _confirm(
                        context,
                        title: 'سحب المكتب من السوق',
                        body:
                            'لن يظهر «${office.name}» في تطبيق العملاء، وسيستمر '
                            'موظفوه وكباتنه في العمل كالمعتاد. يمكن إعادة عرضه '
                            'في أي وقت.',
                        confirmLabel: 'سحب من السوق',
                        onConfirmed: () => onSetListing('unlisted'),
                      ),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('سحب من السوق'),
              )
            else
              FilledButton.icon(
                onPressed: isBusy || !office.canBeListed
                    ? null
                    : () => _confirm(
                        context,
                        title: 'عرض المكتب في السوق',
                        body:
                            'سيظهر «${office.name}» لكل العملاء في السوق، '
                            'وستصبح رحلاته قابلة للحجز.',
                        confirmLabel: 'عرض في السوق',
                        onConfirmed: () => onSetListing('listed'),
                      ),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(
                  office.listingStatus == 'unlisted'
                      ? 'إعادة العرض في السوق'
                      : 'عرض في السوق',
                ),
              ),
            if (office.status == 'active')
              TextButton.icon(
                onPressed: isBusy
                    ? null
                    : () => _confirm(
                        context,
                        title: 'إيقاف المكتب',
                        body:
                            'سيُمنع مسؤولو «${office.name}» وكباتنه من الدخول، '
                            'وستختفي رحلاته من تطبيق العملاء. يمكن التراجع لاحقاً.',
                        confirmLabel: 'إيقاف',
                        onConfirmed: () => onSetStatus('suspended'),
                      ),
                icon: Icon(Icons.block_outlined, size: 18, color: scheme.error),
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
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirmed,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmed();
  }
}

/// Who can sign in to this office's dashboard.
///
/// Read-only, and carries no email or password field — see
/// [PlatformOfficeOperator] for why, and for what a reset flow would need before
/// it could exist here.
class _OperatorsSection extends StatelessWidget {
  const _OperatorsSection({required this.operators});

  final List<PlatformOfficeOperator> operators;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Section(
      title: 'مسؤولو المكتب',
      icon: Icons.people_outline,
      child: operators.isEmpty
          ? Text(
              'لا يوجد مسؤولون لهذا المكتب — لا يمكن لأحد تسجيل الدخول إليه.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            )
          : Column(
              children: [
                for (final operator in operators)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.surfaceContainerHighest,
                          child: Icon(
                            operator.isOwner
                                ? Icons.shield_outlined
                                : Icons.support_agent_outlined,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                operator.displayName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${operator.username} · ${operator.roleLabel}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: operator.statusLabel,
                          color: operator.isActive
                              ? scheme.primary.withAlpha(18)
                              : scheme.surfaceContainerHighest,
                          textColor: operator.isActive
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xSmall),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const Divider(height: AppSpacing.large),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, this.value, this.valueText});

  final String label;
  final int? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valueText ?? '${value ?? 0}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
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

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = (value ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              text.isEmpty ? '—' : text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficeLogo extends StatelessWidget {
  const _OfficeLogo({
    required this.logoUrl,
    required this.name,
    this.size = 56,
  });

  final String? logoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = (logoUrl ?? '').trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _placeholder(context, scheme)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(context, scheme),
              ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: isError
            ? scheme.errorContainer.withAlpha(60)
            : scheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xSmall),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

String? _date(DateTime? value) {
  if (value == null) return null;
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
