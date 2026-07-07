import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/mini_seat_box.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

class FullScreenSeatMapScreen extends StatelessWidget {
  const FullScreenSeatMapScreen({
    super.key,
    required this.selectedSeats,
    required this.vehicleName,
  });

  final List<String> selectedSeats;
  final String vehicleName;

  @override
  Widget build(BuildContext context) {
    int totalSeats = _safeTotalSeats();
    int totalRows = ((totalSeats + 3) ~/ 4);

    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: AppBar(
        backgroundColor: ClientColors.surfaceFor(context),
        title: Text(
          'Seat Map - $vehicleName',
          style: ClientTypography.headingSmall(context).copyWith(
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.maxContentWidth(MediaQuery.sizeOf(context).width),
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  const SeatLegend(
                    color: ClientColors.journeyGreen,
                    label: 'Your seat',
                  ),
                  SeatLegend(
                    color: ClientColors.primary.withAlpha(50),
                    label: 'Available',
                  ),
                  SeatLegend(
                    color: ClientColors.primary.withAlpha(100),
                    label: 'Other passenger',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceFor(context),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: ClientColors.borderFor(context), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Steering wheel icon to indicate front of bus
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ClientColors.surfaceMutedFor(context),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_motorsports_rounded,
                          color: ClientColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          itemCount: totalRows,
                          itemBuilder: (context, rowIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left side (2 seats)
                                  Row(
                                    children: [
                                      _buildSeat(rowIndex * 4 + 1, context),
                                      const SizedBox(width: 12),
                                      _buildSeat(rowIndex * 4 + 2, context),
                                    ],
                                  ),
                                  // Aisle
                                  Container(
                                    width: 30,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: ClientColors.surfaceSubtleFor(context),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${rowIndex + 1}',
                                        style: ClientTypography.bodySmall(context).copyWith(
                                          color: ClientColors.textTertiaryFor(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right side (2 seats)
                                  Row(
                                    children: [
                                      _buildSeat(rowIndex * 4 + 3, context),
                                      const SizedBox(width: 12),
                                      _buildSeat(rowIndex * 4 + 4, context),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeat(int seatNumber, BuildContext context) {
    final seatStr = seatNumber.toString();
    final isSelected = selectedSeats.contains(seatStr);
    
    // For visual flavor, we'll pretend some seats are occupied by others
    // Realistically, we'd know this from the backend. 
    // Here we'll just show them as "Available" or "Your Seat" if we don't have other passengers.
    // In our case, the prompt just implies enhancing the UI.
    
    return LargeSeatBox(
      number: seatStr,
      selected: isSelected,
      status: isSelected ? SeatStatus.yours : SeatStatus.available,
    );
  }

  int _safeTotalSeats() {
    final numbers = selectedSeats.map(int.tryParse).whereType<int>().toList();
    final maxSelected = numbers.isEmpty ? 12 : numbers.reduce((a, b) => a > b ? a : b);
    // At least 36 seats for a realistic bus look
    return maxSelected < 36 ? 36 : maxSelected;
  }
}

enum SeatStatus { yours, available, occupied }

class LargeSeatBox extends StatelessWidget {
  const LargeSeatBox({
    super.key,
    required this.number,
    required this.selected,
    required this.status,
  });

  final String number;
  final bool selected;
  final SeatStatus status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case SeatStatus.yours:
        bgColor = ClientColors.journeyGreen;
        textColor = ClientColors.textInverse;
        break;
      case SeatStatus.available:
        bgColor = ClientColors.primary.withAlpha(30);
        textColor = ClientColors.primary;
        break;
      case SeatStatus.occupied:
        bgColor = ClientColors.primary.withAlpha(100);
        textColor = ClientColors.textInverse;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: status == SeatStatus.available 
            ? Border.all(color: ClientColors.primary.withAlpha(80), width: 1.5)
            : null,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: ClientColors.journeyGreen.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chair_alt_rounded,
              size: 20,
              color: textColor.withAlpha(status == SeatStatus.available ? 150 : 255),
            ),
            const SizedBox(height: 2),
            Text(
              number,
              style: ClientTypography.labelMedium(context).copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
