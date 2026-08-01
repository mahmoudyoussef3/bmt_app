import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_operational_status.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
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
  });

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final hint = Text(
      saving ? 'جاري الحفظ والرفع...' : 'راجع البيانات قبل الحفظ النهائي.',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );

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
          // The reassurance line is the first thing to go: on a narrow pane, or
          // once Arabic labels grow at a large text scale, the two buttons still
          // have to fit and stay tappable. Dropping the hint before wrapping the
          // buttons keeps the bar one row for as long as it honestly can.
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final roomForHint = constraints.maxWidth >= 520 * scale;

          if (roomForHint) {
            return Row(
              children: [
                Expanded(child: hint),
                const SizedBox(width: AppSpacing.medium),
                cancel,
                const SizedBox(width: AppSpacing.small),
                save,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: AppSpacing.small),
              Expanded(child: save),
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
          icon: const Icon(Icons.arrow_back_rounded),
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
          Icons.chevron_right_rounded,
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
/// Sits next to the lifecycle [StatusChip] rather than replacing it, because the
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

    final chip = StatusChip(
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
