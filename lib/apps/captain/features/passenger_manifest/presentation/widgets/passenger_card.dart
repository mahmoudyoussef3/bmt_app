import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_action_button.dart';
import 'passenger_card_details.dart';
import 'passenger_status_presentation.dart';
import 'passenger_status_sheet.dart';

/// One passenger on the manifest: who they are, where they board, and the three
/// things a captain does about them — set status, call, message.
class PassengerCard extends StatelessWidget {
  const PassengerCard({
    super.key,
    required this.passenger,
    required this.onCall,
    required this.onChat,
  });

  final Passenger passenger;

  /// Null when the booking carries no phone number — the button then renders
  /// disabled instead of pretending a call is possible.
  final VoidCallback? onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The status rail: readable at a glance down a scrolling list,
            // before any text is.
            Container(width: 6, color: passenger.status.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      initials: passenger.name.isNotEmpty
                          ? passenger.name[0]
                          : '?',
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: PassengerCardDetails(passenger: passenger)),
                    const SizedBox(width: 12),
                    _Actions(
                      passenger: passenger,
                      onCall: onCall,
                      onChat: onChat,
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

class _Actions extends StatelessWidget {
  const _Actions({
    required this.passenger,
    required this.onCall,
    required this.onChat,
  });

  final Passenger passenger;
  final VoidCallback? onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    // A cancelled booking is a record, not a passenger to board — offering a
    // status change on it invites the captain to un-cancel a seat the booking
    // flow has already released.
    final canChangeStatus =
        passenger.status != PassengerBoardingStatus.cancelled;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PassengerActionButton(
          icon: Icons.edit_rounded,
          tooltip: 'تغيير الحالة',
          color: CaptainColors.primary,
          onPressed: canChangeStatus
              ? () => showPassengerStatusSheet(context, passenger)
              : null,
        ),
        const SizedBox(height: 8),
        PassengerActionButton(
          icon: Icons.call_rounded,
          tooltip: onCall == null ? 'لا يوجد رقم هاتف' : 'اتصال',
          color: CaptainColors.primaryBright,
          onPressed: onCall,
        ),
        const SizedBox(height: 8),
        PassengerActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: 'مراسلة',
          color: CaptainColors.primaryDeep,
          onPressed: onChat,
        ),
      ],
    );
  }
}
