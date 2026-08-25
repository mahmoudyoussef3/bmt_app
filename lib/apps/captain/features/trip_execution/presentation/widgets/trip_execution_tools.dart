import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';

class TripExecutionTools extends StatelessWidget {
  const TripExecutionTools({
    super.key,
    required this.tripId,
    required this.stage,
  });

  final String tripId;
  final CaptainTripStage stage;

  @override
  Widget build(BuildContext context) {
    return CaptainListGroup(
      children: [
        _Tool(
          label: 'كشف الركاب',
          detail: 'من صعد ومن لم يصعد بعد',
          icon: Icons.people_alt_rounded,
          onTap: () => context.openPassengerManifest(tripId),
        ),
        // Nothing here sends the captain's position: publishing is automatic
        // for the whole live trip (`TripLocationAutoShare`), and a manual
        // "send my location" entry alongside it only invites the captain to
        // believe the riders' map depends on them remembering to tap it.
        if (stage.isLive)
          _Tool(
            label: 'إبلاغ العمليات',
            detail: 'رسالة بموقفك الحالي',
            icon: Icons.sync_rounded,
            onTap: () => context.openStatusUpdate(tripId),
          ),
        if (!stage.isWaiting)
          _Tool(
            label: 'بلاغ طارئ',
            detail: 'عطل أو تأخير أو حادث',
            icon: Icons.report_problem_outlined,
            destructive: true,
            onTap: () => context.openReportIncident(tripId),
          ),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.label,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return CaptainListRow(
      icon: icon,
      label: label,
      detail: detail,
      accentColor: destructive ? CaptainColors.dangerFor(context) : null,
      iconColor: CaptainColors.primaryInkFor(context),
      showChevron: true,
      onTap: onTap,
    );
  }
}
