import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';

import '../../domain/entities/trip_incident.dart';
import 'incident_resolution_dialog.dart';
import 'live_ops_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Moves an incident to [next], recording [note] when the operator supplied one.
/// Returns an error message, or `null` on success.
typedef IncidentAction =
    Future<String?> Function(
      TripIncident incident,
      IncidentStatus next, {
      String? note,
    });

/// The open-incident queue: every report a captain filed from the road that the
/// desk has not closed, triaged worst-first and workable in place.
///
/// A report moves through *acknowledge* then *close* rather than a single
/// resolve click, because on a shared desk the acknowledgement is what stops two
/// operators calling the same captain about the same fault.
class IncidentQueueSection extends StatelessWidget {
  final List<TripIncident> incidents;
  final DateTime now;
  final IncidentAction onAction;

  /// Whether this operator may close reports. A support agent sees the queue —
  /// that is the point of giving them the module — but only an owner decides a
  /// report is handled, so for them the cards render read-only.
  final bool canAct;

  const IncidentQueueSection({
    super.key,
    required this.incidents,
    required this.now,
    required this.onAction,
    this.canAct = true,
  });

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) return const _NoIncidents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final incident in incidents) ...[
          _IncidentCard(
            incident: incident,
            now: now,
            onAction: onAction,
            canAct: canAct,
          ),
          const SizedBox(height: AppSpacing.small),
        ],
      ],
    );
  }
}

/// The cleared queue, drawn as the panel's own empty state rather than a card
/// nested inside the panel card it already sits in.
class _NoIncidents extends StatelessWidget {
  const _NoIncidents();

  @override
  Widget build(BuildContext context) {
    return const DashboardEmptyState(
      icon: Icons.verified_rounded,
      title: 'لا توجد بلاغات مفتوحة',
      message: 'كل البلاغات الواردة من الكباتن تمت معالجتها.',
    );
  }
}

class _IncidentCard extends StatefulWidget {
  final TripIncident incident;
  final DateTime now;
  final IncidentAction onAction;
  final bool canAct;

  const _IncidentCard({
    required this.incident,
    required this.now,
    required this.onAction,
    required this.canAct,
  });

  @override
  State<_IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<_IncidentCard> {
  bool _busy = false;

  /// Acknowledgement is a one-tap claim with no dialog: the whole point is that
  /// it is faster than picking up the phone, so nothing may stand between the
  /// operator and taking ownership.
  Future<void> _acknowledge() =>
      _run(IncidentStatus.acknowledged, successText: 'تم استلام البلاغ');

  /// Closing always asks for an account of what happened.
  Future<void> _close(IncidentStatus target) async {
    final resolution = await showIncidentResolutionDialog(
      context: context,
      incident: widget.incident,
      target: target,
    );
    if (resolution == null || !mounted) return;
    await _run(
      resolution.status,
      note: resolution.note,
      successText: target == IncidentStatus.dismissed
          ? 'تم استبعاد البلاغ'
          : 'تم إغلاق البلاغ',
    );
  }

  Future<void> _run(
    IncidentStatus next, {
    String? note,
    required String successText,
  }) async {
    setState(() => _busy = true);
    final error = await widget.onAction(widget.incident, next, note: note);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? successText)));
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = context.status(incidentSeverityTone(incident.severity));
    final age = incident.ageAt(widget.now);

    final tripContext = [
      incident.routeName,
      incident.driverName,
      incident.vehicleLabel,
    ].where((s) => s.isNotEmpty).join(' · ');

    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: colors.ink),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.tint,
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            incidentTypeIcon(incident.type),
                            size: 18,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          child: Text(
                            incident.type.label,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          liveOpsAgo(age),
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _StatusChip(status: incident.status),
                    if (tripContext.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        tripContext,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (incident.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(incident.description, style: text.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.small),
                    _Actions(
                      status: incident.status,
                      busy: _busy,
                      canAct: widget.canAct,
                      onAcknowledge: _acknowledge,
                      onResolve: () => _close(IncidentStatus.resolved),
                      onDismiss: () => _close(IncidentStatus.dismissed),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Names the report's lifecycle state in words, so "new" versus "someone is on
/// it" never depends on noticing a colour.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (container, on, icon) = switch (status) {
      IncidentStatus.pending => (
        context.status(AppStatusTone.error).tint,
        context.status(AppStatusTone.error).ink,
        Icons.fiber_new_rounded,
      ),
      IncidentStatus.acknowledged => (
        context.status(AppStatusTone.info).tint,
        context.status(AppStatusTone.info).ink,
        Icons.engineering_rounded,
      ),
      IncidentStatus.resolved => (
        context.status(AppStatusTone.success).tint,
        context.status(AppStatusTone.success).ink,
        Icons.check_circle_rounded,
      ),
      IncidentStatus.dismissed => (
        context.status(AppStatusTone.neutral).tint,
        context.status(AppStatusTone.neutral).ink,
        Icons.do_not_disturb_on_rounded,
      ),
    };

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: container,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: on),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: on,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The actions legal from the report's current state.
///
/// Only transitions [IncidentStatus.canTransitionTo] allows are offered, so the
/// UI can never ask for a move the domain will reject.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.status,
    required this.busy,
    required this.canAct,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onDismiss,
  });

  final IncidentStatus status;
  final bool busy;
  final bool canAct;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!canAct) return const SizedBox.shrink();

    if (busy) {
      return const Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final canAcknowledge = status.canTransitionTo(IncidentStatus.acknowledged);
    final canResolve = status.canTransitionTo(IncidentStatus.resolved);
    final canDismiss = status.canTransitionTo(IncidentStatus.dismissed);

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.xSmall,
        alignment: WrapAlignment.end,
        children: [
          if (canDismiss)
            TextButton(onPressed: onDismiss, child: const Text('استبعاد')),
          if (canResolve)
            OutlinedButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('تم الحل'),
            ),
          if (canAcknowledge)
            FilledButton.tonalIcon(
              onPressed: onAcknowledge,
              icon: const Icon(Icons.pan_tool_alt_rounded, size: 18),
              label: const Text('استلام'),
            ),
        ],
      ),
    );
  }
}
