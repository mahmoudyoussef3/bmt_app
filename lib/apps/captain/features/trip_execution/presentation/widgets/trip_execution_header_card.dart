import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_state.dart';
import 'trip_execution_primary_action.dart';
import 'trip_execution_status_badge.dart';

/// What this trip is, where it stands, and the next action on it.
class TripExecutionHeaderCard extends StatelessWidget {
  const TripExecutionHeaderCard({
    super.key,
    required this.trip,
    required this.snapshot,
    required this.state,
  });

  final AssignedTrip trip;
  final TripExecutionSnapshot snapshot;
  final TripExecutionCubitState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: CaptainDesignTokens.floatingShadow(context),
      ),
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: CaptainTypography.headlineSmall(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: CaptainColors.textPrimaryFor(context),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              TripExecutionStatusBadge(status: snapshot.status),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Text(
            'المركبة ${trip.vehicleNumber} • ${trip.plateNumber}',
            style: CaptainTypography.titleMedium(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Row(
            children: [
              _TripFact(
                icon: Icons.schedule_rounded,
                value: CaptainFormats.timeRange(
                  trip.departureTime,
                  trip.expectedArrivalTime,
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              _TripFact(
                icon: Icons.people_alt_rounded,
                value:
                    '${snapshot.boardedCount}/${snapshot.passengerCount} صعدوا',
              ),
            ],
          ),
          if (state case TripExecutionError(:final message)) ...[
            const SizedBox(height: CaptainDesignTokens.s16),
            _InlineError(message: message),
          ],
          const SizedBox(height: CaptainDesignTokens.s24),
          if (state is TripExecutionLoading)
            const Center(child: CircularProgressIndicator())
          else
            TripExecutionPrimaryAction(
              status: snapshot.status,
              tripId: trip.id,
            ),
        ],
      ),
    );
  }
}

class _TripFact extends StatelessWidget {
  const _TripFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(CaptainDesignTokens.s12),
        decoration: BoxDecoration(
          color: CaptainColors.primary.withValues(alpha: 0.05),
          borderRadius: CaptainDesignTokens.br16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: CaptainColors.primary),
            const SizedBox(width: CaptainDesignTokens.s12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: CaptainColors.textSecondaryFor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.error.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: CaptainColors.error),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              message,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
