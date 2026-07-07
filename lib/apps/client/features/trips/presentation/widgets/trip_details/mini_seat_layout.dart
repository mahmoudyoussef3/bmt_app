import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/full_screen_seat_map_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/mini_seat_box.dart';

/// A compact seat-map preview highlighting the passenger's own seat(s)
/// against a plausible total (real vehicle capacity isn't modeled on
/// [TripData], so the total is inferred from the highest selected seat
/// number, floored at 12).
class MiniSeatLayout extends StatelessWidget {
  const MiniSeatLayout({
    super.key,
    required this.selectedSeats,
    required this.vehicleName,
  });

  final List<String> selectedSeats;
  final String vehicleName;

  @override
  Widget build(BuildContext context) {
    final seats = List.generate(_safeTotalSeats(), (index) => '${index + 1}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 34,
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.airline_seat_recline_normal_rounded,
              color: ClientColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: seats.map((seat) {
              final selected = selectedSeats.contains(seat);
              return MiniSeatBox(number: seat, selected: selected);
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              const SeatLegend(
                color: ClientColors.journeyGreen,
                label: 'Your seat',
              ),
              SeatLegend(
                color: ClientColors.primary.withAlpha(100),
                label: 'Other seat',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FullScreenSeatMapScreen(
                      selectedSeats: selectedSeats,
                      vehicleName: vehicleName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fullscreen_rounded, size: 20),
              label: const Text('View Full Seat Map'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: ClientColors.primary,
                side: BorderSide(color: ClientColors.borderFor(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _safeTotalSeats() {
    final numbers = selectedSeats.map(int.tryParse).whereType<int>().toList();
    final maxSelected = numbers.isEmpty
        ? 6
        : numbers.reduce((a, b) => a > b ? a : b);
    return maxSelected < 12 ? 12 : maxSelected;
  }
}
