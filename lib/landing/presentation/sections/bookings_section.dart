import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_table.dart';

/// «الحجوزات» — who booked, on which trip, in which seat, and whether they
/// have paid: the day's register as the office sees it.
class BookingsSection extends StatelessWidget {
  const BookingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: LandingContent.bookingsEyebrow,
            headline: LandingContent.bookingsHeadline,
            lead: LandingContent.bookingsLead,
            maxWidth: 620,
            headlineMax: 38,
          ),
          SizedBox(height: landingClamp(context, min: 24, vw: 3, max: 38)),
          LandingTable(
            minWidth: 620,
            radius: LandingRadii.card,
            shadow: const [
              BoxShadow(
                color: Color(0x4D0B1B34),
                offset: Offset(0, 26),
                blurRadius: 54,
                spreadRadius: -34,
              ),
            ],
            headerPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            rowPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            toolbar: const _BookingsToolbar(),
            header: [
              LandingTableHeaderCell(
                LandingContent.bookingHeaders[0],
                flex: 10,
              ),
              LandingTableHeaderCell(
                LandingContent.bookingHeaders[1],
                flex: 12,
              ),
              LandingTableHeaderCell(
                LandingContent.bookingHeaders[2],
                width: 70,
              ),
              LandingTableHeaderCell(
                LandingContent.bookingHeaders[3],
                width: 96,
              ),
              LandingTableHeaderCell(
                LandingContent.bookingHeaders[4],
                width: 88,
              ),
            ],
            rows: [
              for (final booking in LandingContent.bookings)
                [
                  Expanded(flex: 10, child: _Customer(booking: booking)),
                  Expanded(
                    flex: 12,
                    child: Text(
                      booking.trip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LandingType.label(12.5, weight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        booking.seat,
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                        style: LandingType.label(
                          12.5,
                          color: LandingPalette.ink,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: LandingBadge(
                        label: booking.pay,
                        tone: booking.payTone,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: LandingBadge(
                        label: booking.status,
                        tone: booking.statusTone,
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingsToolbar extends StatelessWidget {
  const _BookingsToolbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Text(
            LandingContent.bookingsPanelTitle,
            style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
          ),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final filter in LandingContent.bookingFilters)
                LandingPill(
                  label: filter.label,
                  tone: filter.tone,
                  selected: filter.solid,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Customer extends StatelessWidget {
  const _Customer({required this.booking});

  final LandingBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LandingPalette.brandTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LandingPalette.brandLine),
          ),
          child: Text(
            booking.initial,
            style: LandingType.metric(
              12,
              color: LandingPalette.brandInk,
            ).copyWith(letterSpacing: 0),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            booking.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              12.5,
              color: LandingPalette.ink,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
