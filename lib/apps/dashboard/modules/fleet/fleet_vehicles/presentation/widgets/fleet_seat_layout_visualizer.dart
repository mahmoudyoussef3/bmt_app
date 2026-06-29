import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetSeatLayoutVisualizer extends StatelessWidget {
  final SeatConfiguration seatConfig;

  const FleetSeatLayoutVisualizer({super.key, required this.seatConfig});

  @override
  Widget build(BuildContext context) {
    if (seatConfig.seats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
        child: Text('لا يوجد تخطيط مقاعد مدخل للمركبة.'),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تخطيط المقاعد الداخلي',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.medium),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outline.withAlpha(50)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xSmall,
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                    ),
                    child: const Text(
                      'مقدمة الحافلة (التابلوه)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: seatConfig.rows,
                    itemBuilder: (context, rIndex) {
                      final row = rIndex + 1;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(seatConfig.columns, (cIndex) {
                            final col = cIndex + 1;
                            final seat = seatConfig.seats.firstWhere(
                              (s) => s.row == row && s.column == col,
                              orElse: () => const SeatLayoutItem(
                                seatNumber: '',
                                seatType: 'empty',
                                row: 0,
                                column: 0,
                              ),
                            );

                            if (seat.seatType == 'empty' || seat.row == 0) {
                              return const SizedBox(width: 48, height: 48);
                            }

                            final isDriver = seat.seatType == 'driver';

                            return Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? scheme.secondaryContainer
                                    : scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppTokens.radiusSmall,
                                ),
                                border: Border.all(
                                  color: isDriver
                                      ? scheme.secondary
                                      : scheme.primary,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDriver
                                        ? Icons.settings_accessibility_rounded
                                        : Icons.event_seat_rounded,
                                    size: 18,
                                    color: isDriver
                                        ? scheme.onSecondaryContainer
                                        : scheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    seat.seatNumber,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDriver
                                          ? scheme.onSecondaryContainer
                                          : scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
