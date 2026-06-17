import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import '../../domain/entities/support_timeline_event.dart';

class SupportTimeline extends StatelessWidget {
  final List<SupportTimelineEvent> events;

  const SupportTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No timeline events available.',
          style: ClientTypography.bodySmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.done
                        ? ClientColors.primary
                        : ClientColors.surfaceMutedFor(context),
                    border: Border.all(
                      color: event.done
                          ? ClientColors.primary
                          : ClientColors.borderFor(context),
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: event.done
                        ? ClientColors.primaryMuted
                        : ClientColors.borderFor(context),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.title,
                        style: ClientTypography.bodySmall(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: event.done
                              ? ClientColors.textPrimaryFor(context)
                              : ClientColors.textTertiaryFor(context),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(event.createdAt),
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
