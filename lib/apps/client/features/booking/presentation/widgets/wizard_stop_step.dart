import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';

class WizardStopStep extends StatelessWidget {
  const WizardStopStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) {
        final stops = session.route.points
          ..sort((a, b) => a.order.compareTo(b.order));
        final cubit = context.read<BookingWizardCubit>();
        return Column(
          children: [
            _StopModeHeader(session: session),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: stops.length,
                separatorBuilder: (_, _) => _StopConnector(),
                itemBuilder: (_, i) => _StopTile(
                  stop: stops[i],
                  session: session,
                  onTap: () => _handleTap(cubit, session, stops[i]),
                ),
              ),
            ),
            _StopContinueBar(session: session, onNext: onNext),
          ],
        );
      },
    );
  }

  void _handleTap(
    BookingWizardCubit cubit,
    BookingWizardSession session,
    RoutePointData stop,
  ) {
    if (session.pickupStop == null) {
      if (stop.pickupAllowed) cubit.selectPickup(stop);
    } else if (session.dropoffStop == null) {
      if (stop.dropoffAllowed && stop.order > session.pickupStop!.order) {
        cubit.selectDropoff(stop);
      } else if (stop.pickupAllowed &&
          stop.order < (session.dropoffStop?.order ?? 999)) {
        cubit.selectPickup(stop);
      }
    } else {
      cubit.selectPickup(stop);
    }
  }
}

class _StopModeHeader extends StatelessWidget {
  const _StopModeHeader({required this.session});
  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final picking = session.pickupStop == null || session.dropoffStop == null;
    final label = session.pickupStop == null
        ? 'Tap your pickup stop'
        : session.dropoffStop == null
        ? 'Now tap your dropoff stop'
        : 'Stops selected — review or change below';
    return Container(
      width: double.infinity,
      color: picking
          ? ClientColors.primaryLight
          : ClientColors.journeyGreenLight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        label,
        style: ClientTypography.bodySmall(context).copyWith(
          color: picking ? ClientColors.primary : ClientColors.journeyGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StopConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 31),
      child: Container(
        width: 2,
        height: 20,
        color: ClientColors.borderFor(context),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.session,
    required this.onTap,
  });
  final RoutePointData stop;
  final BookingWizardSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPickup = session.pickupStop?.order == stop.order;
    final isDropoff = session.dropoffStop?.order == stop.order;
    final isInRange =
        session.pickupStop != null &&
        session.dropoffStop != null &&
        stop.order > session.pickupStop!.order &&
        stop.order < session.dropoffStop!.order;
    final color = isPickup
        ? ClientColors.primary
        : isDropoff
        ? ClientColors.journeyGreen
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              color?.withAlpha(20) ??
              (isInRange ? ClientColors.primaryLight.withAlpha(80) : null),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color ?? ClientColors.borderFor(context),
            width: (isPickup || isDropoff) ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? ClientColors.journeySlateLight,
              ),
              child: Center(
                child: isPickup
                    ? const Icon(
                        Icons.person_pin_circle_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : isDropoff
                    ? const Icon(
                        Icons.flag_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        '${stop.order}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stop.name,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: (isPickup || isDropoff)
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: color ?? ClientColors.textPrimaryFor(context),
                ),
              ),
            ),
            if (isPickup) _badge('Pickup', ClientColors.primary),
            if (isDropoff) _badge('Dropoff', ClientColors.journeyGreen),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _StopContinueBar extends StatelessWidget {
  const _StopContinueBar({required this.session, required this.onNext});
  final BookingWizardSession session;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.stopsValid) ...[
              Row(
                children: [
                  Expanded(
                    child: _stopChip(
                      context,
                      'Pickup',
                      session.pickupStop!.name,
                      ClientColors.primary,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                  Expanded(
                    child: _stopChip(
                      context,
                      'Dropoff',
                      session.dropoffStop!.name,
                      ClientColors.journeyGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ClientButton(
              label: 'Continue',
              onPressed: session.stopsValid ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stopChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: ClientColors.textSecondaryFor(context),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
