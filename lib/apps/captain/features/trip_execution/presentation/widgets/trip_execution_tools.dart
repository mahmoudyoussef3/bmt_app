import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';

/// Everything else the captain can do on this trip, scoped to its [stage].
///
/// These were a two-column `GridView` of square tiles, each with a tinted
/// circular icon — the module grid an admin console opens on, and the single
/// most dashboard-like thing in the app. They are secondary tools, not the
/// screen's subject: as a list of rows they take a third of the height, say
/// what they do in full, and stop competing with the trip itself.
///
/// Boarding passengers is done from the manifest ("الركاب"), where a captain
/// taps a name and sets it to صعد. There is no ticket QR to scan — clients are
/// never issued one — so the scanner tile that used to sit here opened a camera
/// that could not succeed at anything.
///
/// The rest follow the stage: reporting a position or a status update before
/// operations has even released the trip describes a journey that isn't
/// happening.
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
        // The manifest is the boarding door: available from the moment there
        // are bookings to look at.
        _Tool(
          label: 'كشف الركاب',
          detail: 'من صعد ومن لم يصعد بعد',
          icon: Icons.people_alt_rounded,
          onTap: () => context.openPassengerManifest(tripId),
        ),
        _Tool(
          label: 'التواصل',
          detail: 'رسائل الركاب والعمليات',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => context.openChats(tripId),
        ),
        if (stage.isLive) ...[
          _Tool(
            label: 'إرسال الموقع',
            detail: 'تحديث موقعك يدوياً الآن',
            icon: Icons.my_location_rounded,
            onTap: () => context.openLocationUpdate(tripId),
          ),
          _Tool(
            label: 'تحديث الحالة',
            detail: 'إبلاغ العمليات بما يجري',
            icon: Icons.sync_rounded,
            onTap: () => context.openStatusUpdate(tripId),
          ),
        ],
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
      accentColor: destructive ? CaptainColors.error : null,
      iconColor: CaptainColors.primary,
      showChevron: true,
      onTap: onTap,
    );
  }
}
