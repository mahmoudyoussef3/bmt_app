import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/forms/forms.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_expiry.dart';
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

  /// Readiness, drawn as a ring around the picture.
  ///
  /// The list's first column is the one the eye lands on, so the row's single
  /// most important fact — can this driver be put on a bus — is carried there
  /// too, not only in the status column further along the row.
  final Color? ringColor;

  /// Compact rows (a table) want a smaller picture than a card does.
  final double size;

  const FleetAvatar({
    super.key,
    required this.label,
    this.profileImageUrl = '',
    this.ringColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: profileImageUrl.isNotEmpty
          ? NetworkImage(profileImageUrl)
          : null,
      child: profileImageUrl.isNotEmpty
          ? null
          : Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
              ),
            ),
    );

    final ring = ringColor;
    if (ring == null) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: avatar,
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

/// The status role a vehicle's live operational state reads as, so the chip in
/// a card and the merged status cell in a table can never disagree about what
/// colour "في رحلة" is.
AppStatusTone fleetOperationalTone(FleetOperationalStatus status) =>
    switch (status) {
      FleetOperationalStatus.available => AppStatusTone.success,
      FleetOperationalStatus.assigned => AppStatusTone.info,
      FleetOperationalStatus.onTrip => AppStatusTone.special,
      FleetOperationalStatus.maintenance => AppStatusTone.warning,
      FleetOperationalStatus.unavailable => AppStatusTone.error,
      FleetOperationalStatus.retired => AppStatusTone.neutral,
    };

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
    final style = context.status(fleetOperationalTone(status));

    final chip = DashboardStatusChip(
      label: status.label,
      color: style.tint,
      textColor: style.ink,
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
///
/// Two short lines — a lead ("الآن" / a date) and the route under it — rather
/// than one long sentence: at the width a column of a nine-column table can
/// afford, `'الآن: TRP-1001 • القاهرة → الإسكندرية'` ellipsised away the half
/// that says *where*, which is the half an operator is scanning for.
class FleetTripCell extends StatelessWidget {
  const FleetTripCell({super.key, this.underway, this.next});

  final FleetVehicleDuty? underway;
  final FleetVehicleDuty? next;

  @override
  Widget build(BuildContext context) {
    final duty = underway ?? next;
    if (duty == null) {
      return Text(
        'بدون رحلة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.faintInk(context),
        ),
      );
    }

    final live = underway != null;
    final tone = live ? AppStatusTone.special : AppStatusTone.neutral;
    final lead = live
        ? 'الآن • ${duty.tripCode}'
        : '${FleetFormat.date(duty.tripDate)} • ${duty.departureTime}';

    return Tooltip(
      message:
          'رحلة ${duty.tripCode}'
          '${duty.routeName.isEmpty ? '' : ' • ${duty.routeName}'}'
          ' • ${FleetFormat.date(duty.tripDate)} ${duty.departureTime}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (live) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: context.status(tone).ink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  lead,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: live
                        ? context.status(tone).ink
                        : DashboardColors.ink(context),
                  ),
                ),
              ),
            ],
          ),
          if (duty.routeName.isNotEmpty)
            Text(
              duty.routeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// The "آخر تحديث" table column — a real `updated_at` timestamp, labelled
/// honestly as a last-changed date rather than "last activity": one column
/// update is not the same claim as a genuine usage/activity log, which this
/// data model does not have.
///
/// Read as an age ("منذ ٣ أيام") with the exact date on hover: in a list, how
/// stale a record is is the question; `2026-08-19` made the reader do the
/// arithmetic in every row.
class FleetLastUpdatedCell extends StatelessWidget {
  const FleetLastUpdatedCell({super.key, required this.updatedAt});

  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final value = updatedAt;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: DashboardColors.mutedInk(context));

    if (value == null) {
      return Text(
        '—',
        style: style?.copyWith(color: DashboardColors.faintInk(context)),
      );
    }

    return Tooltip(
      message: 'آخر تحديث ${FleetFormat.date(value)}',
      child: Text(
        FleetFormat.age(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// A status chip with the one sentence that explains it underneath.
///
/// The drivers table used to spend two full columns — "الصحة" and "التوفر" —
/// on what is one answer: نعم/لا this driver can take a bus today, and why
/// not. Side by side they mostly restated each other ("سليم" next to "معين",
/// "حرج" next to "موقوف") while the *reason* — the only part that tells the
/// operator what to fix — was hidden in a tooltip. This is that pair merged:
/// the availability chip painted in the health tone, with the blocking reason
/// spelled out under it whenever there is one.
class FleetStatusReasonCell extends StatelessWidget {
  const FleetStatusReasonCell({
    super.key,
    required this.label,
    required this.tone,
    this.note,
    this.tooltip,
  });

  final String label;
  final AppStatusTone tone;

  /// The line under the chip — shown only when there is something to say.
  final String? note;

  /// Everything behind the note (all the attention reasons, the assigned
  /// trip), for the operator who wants the detail without opening the file.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final style = context.status(tone);
    final cell = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardStatusChip(
          label: label,
          color: style.tint,
          textColor: style.ink,
        ),
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            note!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ],
    );

    if (tooltip == null || tooltip!.isEmpty) return cell;
    return Tooltip(message: tooltip!, child: cell);
  }
}

/// The pairing column: which bus a driver is on, or which driver a bus has.
///
/// An unpaired record is the actionable state — a bus with no driver cannot be
/// scheduled — so it says so in the warning ink rather than as a filled chip:
/// a chip in every second row of a dense list reads as decoration, and stops
/// carrying weight exactly where it matters.
class FleetPairingCell extends StatelessWidget {
  const FleetPairingCell({
    super.key,
    required this.icon,
    required this.value,
    required this.emptyLabel,
  });

  final IconData icon;
  final String value;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      final warning = context.status(AppStatusTone.warning);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_circle_outline_rounded,
            size: 14,
            color: warning.ink,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              emptyLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: warning.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Tooltip(
      message: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: DashboardColors.mutedInk(context)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: DashboardColors.ink(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One dated document, for the columns that report validity.
class FleetDatedDocument {
  const FleetDatedDocument({required this.label, required this.date});

  final String label;

  /// ISO `yyyy-MM-dd`, exactly as the record stores it. Empty when the office
  /// never entered one.
  final String date;
}

/// "Is the paperwork good?" — one verdict per row, not a stack of dates.
///
/// The vehicles table used to print three date chips (رخصة / تأمين / فحص) in
/// one cell, which tripled the height of every row and still made the operator
/// compare three dates against today in their head. This answers the question
/// the column is actually asked — the worst of the three — and keeps the dates
/// themselves on hover and in the vehicle's file.
class FleetDocumentsHealthCell extends StatelessWidget {
  const FleetDocumentsHealthCell({super.key, required this.documents});

  final List<FleetDatedDocument> documents;

  @override
  Widget build(BuildContext context) {
    final known = documents.where((doc) => doc.date.trim().isNotEmpty).toList();

    if (known.isEmpty) {
      return FleetStatusReasonCell(
        label: 'غير مسجلة',
        tone: AppStatusTone.neutral,
        tooltip: 'لم تُسجَّل تواريخ الرخصة أو التأمين أو الفحص',
      );
    }

    FleetDatedDocument? worst;
    var worstLevel = FleetExpiryLevel.valid;
    var worstDays = 1 << 30;

    for (final doc in known) {
      final level = FleetExpiry.levelOf(doc.date);
      final days = FleetExpiry.daysRemaining(doc.date) ?? 1 << 30;
      final rank = switch (level) {
        FleetExpiryLevel.expired => 3,
        FleetExpiryLevel.expiringSoon => 2,
        FleetExpiryLevel.missing => 1,
        FleetExpiryLevel.valid => 0,
      };
      final worstRank = switch (worstLevel) {
        FleetExpiryLevel.expired => 3,
        FleetExpiryLevel.expiringSoon => 2,
        FleetExpiryLevel.missing => 1,
        FleetExpiryLevel.valid => 0,
      };
      if (worst == null ||
          rank > worstRank ||
          (rank == worstRank && days < worstDays)) {
        worst = doc;
        worstLevel = level;
        worstDays = days;
      }
    }

    final (label, tone) = switch (worstLevel) {
      FleetExpiryLevel.expired => (
        '${worst!.label} منتهية',
        AppStatusTone.error,
      ),
      FleetExpiryLevel.expiringSoon => (
        '${worst!.label} ${FleetFormat.remainingShort(worst.date)}',
        AppStatusTone.warning,
      ),
      FleetExpiryLevel.missing => ('تاريخ غير صالح', AppStatusTone.neutral),
      FleetExpiryLevel.valid => ('سارية', AppStatusTone.success),
    };

    final missing = documents
        .where((doc) => doc.date.trim().isEmpty)
        .map((doc) => doc.label)
        .toList();

    return FleetStatusReasonCell(
      label: label,
      tone: tone,
      note: missing.isEmpty ? null : 'بدون ${missing.join('، ')}',
      tooltip: [
        for (final doc in documents)
          '${doc.label}: ${doc.date.trim().isEmpty ? 'غير مسجلة' : '${FleetFormat.dateText(doc.date)} (${FleetFormat.relativeDate(doc.date)})'}',
      ].join('\n'),
    );
  }
}

/// A single expiry date read the way an operator reads it: the date, and how
/// long that leaves, coloured by how urgent it is.
class FleetExpiryCell extends StatelessWidget {
  const FleetExpiryCell({super.key, required this.date, this.emptyLabel = '—'});

  /// ISO `yyyy-MM-dd`.
  final String date;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (date.trim().isEmpty) {
      return Text(
        emptyLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.faintInk(context),
        ),
      );
    }

    final level = FleetExpiry.levelOf(date);
    final tone = switch (level) {
      FleetExpiryLevel.expired => AppStatusTone.error,
      FleetExpiryLevel.expiringSoon => AppStatusTone.warning,
      FleetExpiryLevel.missing => AppStatusTone.neutral,
      FleetExpiryLevel.valid => AppStatusTone.neutral,
    };
    final urgent =
        level == FleetExpiryLevel.expired ||
        level == FleetExpiryLevel.expiringSoon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FleetFormat.dateText(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: urgent ? FontWeight.w800 : FontWeight.w600,
            color: urgent
                ? context.status(tone).ink
                : DashboardColors.ink(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          FleetFormat.relativeDate(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: urgent
                ? context.status(tone).ink
                : DashboardColors.mutedInk(context),
            fontWeight: urgent ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}

/// The row-level icon action — one size, one density, in both tabs.
///
/// A default [IconButton] reserves 48px of width each; three of them are
/// 144px of a table that has ~130 to give the whole actions column, which is
/// how the fleet tables ended up wider than the pane they live in.
class FleetRowActionButton extends StatelessWidget {
  const FleetRowActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: color ?? DashboardColors.mutedInk(context),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      splashRadius: 18,
    );
  }
}
