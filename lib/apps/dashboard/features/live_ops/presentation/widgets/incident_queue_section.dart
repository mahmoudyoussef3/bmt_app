import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/trip_incident.dart';
import 'incident_resolution_dialog.dart';
import 'live_ops_format.dart';

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
///
/// **Rows on the panel's surface, divided.** This is Home's «يحتاج إلى إجراء»
/// vocabulary applied to the one queue that is not on Home: a tinted glyph
/// square carrying the severity, the report in ink, what it is about underneath,
/// and the decision on the trailing edge. The cards it used to draw — each with
/// its own border, shadow and 5px severity spine, stacked inside the bordered
/// panel they already sat in — were the console's card-in-card fault, and made a
/// queue of four reports read as four separate alarms.
class IncidentQueueSection extends StatelessWidget {
  final List<TripIncident> incidents;
  final DateTime now;
  final IncidentAction onAction;

  /// Whether this operator may close reports. A support agent sees the queue —
  /// that is the point of giving them the module — but only an owner decides a
  /// report is handled, so for them the rows render read-only.
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
          _IncidentRow(
            incident: incident,
            now: now,
            onAction: onAction,
            canAct: canAct,
          ),
          if (incident != incidents.last)
            const Divider(height: AppSpacing.large),
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

class _IncidentRow extends StatefulWidget {
  final TripIncident incident;
  final DateTime now;
  final IncidentAction onAction;
  final bool canAct;

  const _IncidentRow({
    required this.incident,
    required this.now,
    required this.onAction,
    required this.canAct,
  });

  @override
  State<_IncidentRow> createState() => _IncidentRowState();
}

class _IncidentRowState extends State<_IncidentRow> {
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
    final text = Theme.of(context).textTheme;
    final tone = incidentSeverityTone(incident.severity);
    final style = DashboardColors.status(context, tone);

    final tripContext = [
      incident.routeName,
      incident.driverName,
      incident.vehicleLabel,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The only colour on the row. A whole row tinted by severity turns a
        // queue of ordinary reports into a wall of alarms — the console spends
        // its colour budget on the category mark instead.
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.tint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: DashboardColors.statusLine(context, tone),
            ),
          ),
          child: Icon(
            incidentTypeIcon(incident.type),
            size: 18,
            color: style.ink,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      incident.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    liveOpsAgo(incident.ageAt(widget.now)),
                    maxLines: 1,
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.faintInk(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.xSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusChip(status: incident.status),
                  if (tripContext.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(
                        tripContext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                    ),
                ],
              ),
              if (incident.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  incident.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ],
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
      ],
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
    final (tone, icon) = switch (status) {
      IncidentStatus.pending => (AppStatusTone.error, Icons.fiber_new_rounded),
      IncidentStatus.acknowledged => (
        AppStatusTone.info,
        Icons.engineering_rounded,
      ),
      IncidentStatus.resolved => (
        AppStatusTone.success,
        Icons.check_circle_rounded,
      ),
      IncidentStatus.dismissed => (
        AppStatusTone.neutral,
        Icons.do_not_disturb_on_rounded,
      ),
    };
    final style = DashboardColors.status(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DashboardColors.statusLine(context, tone)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: style.ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: style.ink,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
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
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.small),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final canAcknowledge = status.canTransitionTo(IncidentStatus.acknowledged);
    final canResolve = status.canTransitionTo(IncidentStatus.resolved);
    final canDismiss = status.canTransitionTo(IncidentStatus.dismissed);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xSmall),
      child: Align(
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
      ),
    );
  }
}
