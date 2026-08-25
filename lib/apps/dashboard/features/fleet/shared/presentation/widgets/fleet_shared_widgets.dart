import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/forms/forms.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_operational_status.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class FleetAvatar extends StatelessWidget {
  final String label;
  final String profileImageUrl;

  const FleetAvatar({
    super.key,
    required this.label,
    this.profileImageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: profileImageUrl.isNotEmpty
          ? NetworkImage(profileImageUrl)
          : null,
      child: profileImageUrl.isNotEmpty ? null : Text(label),
    );
  }
}

class FleetVehicleThumb extends StatelessWidget {
  final String label;
  final String imageUrl;

  const FleetVehicleThumb({super.key, required this.label, this.imageUrl = ''});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayUrl = imageUrl.contains(',')
        ? imageUrl.split(',').first.trim()
        : imageUrl;
    return Container(
      width: 54,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(90)),
        image: displayUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(displayUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: displayUrl.isNotEmpty
          ? null
          : Icon(Icons.directions_bus_rounded, color: scheme.primary),
    );
  }
}

class FleetSectionTitle extends StatelessWidget {
  const FleetSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FleetFormHeroCard extends StatelessWidget {
  const FleetFormHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
            child: Icon(icon, color: scheme.primary, size: 30),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FleetFormActionsBar extends StatelessWidget {
  const FleetFormActionsBar({
    super.key,
    required this.saving,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
    this.hint,
    this.requiredFilled,
    this.requiredTotal,
  });

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  /// Replaces the generic "review before saving" line with something specific
  /// — what is still outstanding, or what is about to be written.
  final String? hint;

  /// When both are supplied, the bar carries a live completion readout, so the
  /// operator can see how much is left without scrolling back up the form.
  final int? requiredFilled;
  final int? requiredTotal;

  @override
  Widget build(BuildContext context) {
    final hasProgress = requiredFilled != null && requiredTotal != null;

    final hintLine = Text(
      saving
          ? 'جاري الحفظ والرفع...'
          : (hint ?? 'راجع البيانات قبل الحفظ النهائي.'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );

    final status = hasProgress
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DashboardFormProgress(
                filled: requiredFilled!,
                total: requiredTotal!,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.xSmall),
              hintLine,
            ],
          )
        : hintLine;

    final cancel = OutlinedButton(
      onPressed: saving ? null : onCancel,
      child: const Text('إلغاء'),
    );

    final save = FilledButton.icon(
      onPressed: saving ? null : onSave,
      icon: saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_rounded),
      label: Text(saveLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final roomForHint = constraints.maxWidth >= 520 * scale;

          if (roomForHint) {
            return Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: AppSpacing.medium),
                cancel,
                const SizedBox(width: AppSpacing.small),
                save,
              ],
            );
          }

          final buttons = Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: AppSpacing.small),
              Expanded(child: save),
            ],
          );

          // The hint is the first thing to go when there is no room; the
          // progress track survives it, being one line tall and the only
          // signal of how much work is left.
          if (!hasProgress) return buttons;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DashboardFormProgress(
                filled: requiredFilled!,
                total: requiredTotal!,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.small),
              buttons,
            ],
          );
        },
      ),
    );
  }
}

class FleetEmptyInlineState extends StatelessWidget {
  const FleetEmptyInlineState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(65),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 38),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class FleetBreadcrumbs extends StatelessWidget {
  final String currentLabel;
  final VoidCallback onBack;

  const FleetBreadcrumbs({
    super.key,
    required this.currentLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(DashboardIcons.back),
          tooltip: 'رجوع',
        ),
        const SizedBox(width: AppSpacing.small),
        TextButton(
          onPressed: onBack,
          child: Text(
            'إدارة الأسطول',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        Icon(
          DashboardIcons.breadcrumbSeparator,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            currentLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class FleetMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const FleetMetaRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Text('$label:', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.xSmall),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? scheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "what is this bus doing right now" chip.
///
/// Sits next to the lifecycle [DashboardStatusChip] rather than replacing it, because the
/// two answer different questions and are allowed to disagree — a vehicle marked
/// for maintenance while a trip is under way reads "في الصيانة" and "في رحلة" side
/// by side, which is exactly the contradiction a dispatcher needs to see.
class FleetOperationalChip extends StatelessWidget {
  const FleetOperationalChip({super.key, required this.status, this.duty});

  final FleetOperationalStatus status;

  /// The trip behind an `onTrip` / `assigned` reading, shown as a tooltip so the
  /// chip stays short but the operator can find out which trip without leaving
  /// the list.
  final FleetVehicleDuty? duty;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      FleetOperationalStatus.available => (
        context.status(AppStatusTone.success).tint,
        context.status(AppStatusTone.success).ink,
      ),
      FleetOperationalStatus.assigned => (
        context.status(AppStatusTone.info).tint,
        context.status(AppStatusTone.info).ink,
      ),
      FleetOperationalStatus.onTrip => (
        context.status(AppStatusTone.special).tint,
        context.status(AppStatusTone.special).ink,
      ),
      FleetOperationalStatus.maintenance => (
        context.status(AppStatusTone.warning).tint,
        context.status(AppStatusTone.warning).ink,
      ),
      FleetOperationalStatus.unavailable => (
        context.status(AppStatusTone.error).tint,
        context.status(AppStatusTone.error).ink,
      ),
      FleetOperationalStatus.retired => (
        context.status(AppStatusTone.neutral).tint,
        context.status(AppStatusTone.neutral).ink,
      ),
    };

    final chip = DashboardStatusChip(
      label: status.label,
      color: background,
      textColor: foreground,
    );

    if (duty == null) return chip;

    final route = duty!.routeName.isEmpty ? '' : ' • ${duty!.routeName}';
    return Tooltip(
      message: 'رحلة ${duty!.tripCode}$route • ${duty!.departureTime}',
      child: chip,
    );
  }
}

/// The "الرحلة" table column — what a vehicle/driver is doing right now, or
/// the next thing they are committed to, whichever applies. Shared by the
/// vehicles and drivers tables since both key duties from the same
/// `FleetVehicleDuty` shape (see [FleetWorkspace.underwayDutyOf] and its
/// driver-scoped mirror).
class FleetTripCell extends StatelessWidget {
  const FleetTripCell({super.key, this.underway, this.next});

  final FleetVehicleDuty? underway;
  final FleetVehicleDuty? next;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (underway != null) {
      final route = underway!.routeName.isEmpty
          ? ''
          : ' • ${underway!.routeName}';
      return Text(
        'الآن: ${underway!.tripCode}$route',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
      );
    }

    if (next != null) {
      final route = next!.routeName.isEmpty ? '' : ' • ${next!.routeName}';
      return Text(
        'القادمة: ${next!.tripDate.toIso8601String().split('T').first}$route',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    return Text(
      'لا توجد رحلة مجدولة',
      style: TextStyle(color: scheme.onSurfaceVariant),
    );
  }
}

/// The "آخر تحديث" table column — a real `updated_at` timestamp, labelled
/// honestly as a last-changed date rather than "last activity": one column
/// update is not the same claim as a genuine usage/activity log, which this
/// data model does not have.
class FleetLastUpdatedCell extends StatelessWidget {
  const FleetLastUpdatedCell({super.key, required this.updatedAt});

  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = updatedAt;
    if (value == null) {
      return Text('—', style: TextStyle(color: scheme.onSurfaceVariant));
    }
    return Text(
      value.toIso8601String().split('T').first,
      style: TextStyle(color: scheme.onSurfaceVariant),
    );
  }
}
