import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';

class WizardStopStep extends StatelessWidget {
  const WizardStopStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) {
        final stops = [...session.route.points]
          ..sort((a, b) => a.order.compareTo(b.order));
        final cubit = context.read<BookingWizardCubit>();
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  BookingStepIntro(
                    icon: Icons.alt_route_rounded,
                    title: 'Where will you get on and off?',
                    subtitle:
                        'Choose your pickup first, then a stop further along the route.',
                    trailing: BookingCountPill(label: '${stops.length} stops'),
                  ),
                  const SizedBox(height: 18),
                  _StopModeHeader(session: session),
                  const SizedBox(height: 14),
                  BookingSurfaceCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: List.generate(stops.length, (index) {
                        return Column(
                          children: [
                            _StopTile(
                              stop: stops[index],
                              session: session,
                              isFirst: index == 0,
                              isLast: index == stops.length - 1,
                              onTap: () =>
                                  _handleTap(cubit, session, stops[index]),
                            ),
                            if (index != stops.length - 1)
                              _StopConnector(
                                active:
                                    session.pickupStop != null &&
                                    stops[index].order >=
                                        session.pickupStop!.order &&
                                    session.dropoffStop != null &&
                                    stops[index].order <
                                        session.dropoffStop!.order,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
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
    final label = session.pickupStop == null
        ? '1  Select your pickup stop'
        : session.dropoffStop == null
        ? '2  Now select your drop-off stop'
        : 'Route segment ready';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: session.stopsValid
            ? ClientColors.journeyCyanLight
            : ClientColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            session.stopsValid
                ? Icons.check_circle_rounded
                : Icons.touch_app_rounded,
            size: 18,
            color: session.stopsValid
                ? ClientColors.journeyCyan
                : ClientColors.primary,
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: ClientTypography.bodySmall(context).copyWith(
              color: session.stopsValid
                  ? ClientColors.journeyCyan
                  : ClientColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopConnector extends StatelessWidget {
  const _StopConnector({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 23),
        child: Container(
          width: 2,
          height: 12,
          color: active
              ? ClientColors.primary
              : ClientColors.borderFor(context),
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.session,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });
  final RoutePointData stop;
  final BookingWizardSession session;
  final bool isFirst;
  final bool isLast;
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
        ? ClientColors.journeyCyan
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color:
              color?.withAlpha(20) ??
              (isInRange ? ClientColors.primaryLight.withAlpha(80) : null),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color ?? ClientColors.borderFor(context),
            width: (isPickup || isDropoff) ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? ClientColors.journeySlateLight,
              ),
              child: Center(
                child: isPickup
                    ? const Icon(
                        Icons.person_pin_circle_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : isDropoff
                    ? const Icon(
                        Icons.flag_rounded,
                        size: 16,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: ClientTypography.bodyMedium(context).copyWith(
                      fontWeight: (isPickup || isDropoff)
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: color ?? ClientColors.textPrimaryFor(context),
                    ),
                  ),
                  if (!isPickup && !isDropoff)
                    Text(
                      isFirst
                          ? 'Route begins here'
                          : isLast
                          ? 'Final destination'
                          : 'Pickup and drop-off point',
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textTertiaryFor(context)),
                    ),
                ],
              ),
            ),
            if (isPickup) _badge('Pickup', ClientColors.primary),
            if (isDropoff) _badge('Dropoff', ClientColors.journeyCyan),
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
    return BookingBottomAction(
      summary: session.stopsValid
          ? Row(
              children: [
                Expanded(
                  child: _stopChip(
                    context,
                    'PICKUP',
                    session.pickupStop!.name,
                    ClientColors.primary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded, size: 18),
                ),
                Expanded(
                  child: _stopChip(
                    context,
                    'DROP-OFF',
                    session.dropoffStop!.name,
                    ClientColors.journeyCyan,
                  ),
                ),
              ],
            )
          : null,
      child: ClientButton(
        label: 'Find available trips',
        icon: const Icon(Icons.arrow_forward_rounded),
        onPressed: session.stopsValid ? onNext : null,
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
