import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «الحجوزات» — the booking board, filter chips and all.
class BookingsSection extends StatelessWidget {
  const BookingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'الحجوزات',
            headline: 'الحجوزات تحت سيطرتك',
            lead: 'تعرف مين حجز، على أي رحلة، وأي مقعد، وحالة الدفع.',
            maxWidth: 620,
            headlineMax: 38,
          ),
          SizedBox(height: landingClamp(context, min: 24, vw: 3, max: 38)),
          const _BookingBoard(),
        ],
      ),
    );
  }
}

class _BookingBoard extends StatelessWidget {
  const _BookingBoard();

  static const _seatWidth = 70.0;
  static const _payWidth = 96.0;
  static const _statusWidth = 92.0;
  static const _minCustomerWidth = 130.0;
  static const _minTripWidth = 160.0;
  static const _minWidth =
      _seatWidth + _payWidth + _statusWidth + _minCustomerWidth + _minTripWidth;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: EdgeInsets.zero,
      clip: true,
      shadow: const [
        BoxShadow(
          color: Color(0x4D0B1B34),
          offset: Offset(0, 26),
          blurRadius: 54,
          spreadRadius: -34,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BookingToolbar(),
          LayoutBuilder(
            builder: (context, constraints) {
              final table = SizedBox(
                width: constraints.maxWidth < _minWidth + 32
                    ? _minWidth + 32
                    : constraints.maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BookingHeaderRow(),
                    for (final booking in LandingContent.bookings)
                      _BookingRow(booking: booking),
                  ],
                ),
              );
              if (constraints.maxWidth >= _minWidth + 32) return table;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BookingToolbar extends StatelessWidget {
  const _BookingToolbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('حجوزات اليوم · 186 حجز', style: LandingType.cardTitle(13.5)),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final filter in LandingContent.bookingFilters)
                _FilterChip(label: filter.label, tone: filter.tone),
            ],
          ),
        ],
      ),
    );
  }
}

/// The filter row's chips. `الكل` is the selected one and takes the brand
/// fill; the rest wear the tone of the status they filter to, so the row
/// doubles as the table's legend.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.tone});

  final String label;
  final LandingTone? tone;

  @override
  Widget build(BuildContext context) {
    final selected = tone == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? LandingPalette.brand : tone!.background,
        borderRadius: BorderRadius.circular(999),
        border: selected ? null : Border.all(color: tone!.line),
      ),
      child: Text(
        label,
        style: LandingType.label(
          11.5,
          color: selected ? Colors.white : tone!.foreground,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BookingHeaderRow extends StatelessWidget {
  const _BookingHeaderRow();

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, {double? width, int? flex}) {
      final text = Text(
        label,
        style: LandingType.label(11, weight: FontWeight.w800),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      return width != null
          ? SizedBox(width: width, child: text)
          : Expanded(flex: flex ?? 1, child: text);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: LandingPalette.raised,
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Row(
        children: [
          cell('العميل', flex: 10),
          cell('الرحلة', flex: 12),
          cell('المقعد', width: _BookingBoard._seatWidth),
          cell('الدفع', width: _BookingBoard._payWidth),
          cell('الحالة', width: _BookingBoard._statusWidth),
        ],
      ),
    );
  }
}

class _BookingRow extends StatefulWidget {
  const _BookingRow({required this.booking});

  final LandingBookingRow booking;

  @override
  State<_BookingRow> createState() => _BookingRowState();
}

class _BookingRowState extends State<_BookingRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered ? LandingPalette.surface2 : LandingPalette.surface,
          border: const Border(
            bottom: BorderSide(color: LandingPalette.borderSoft),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: Row(
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
                      style: LandingType.label(
                        12,
                        color: LandingPalette.brandInk,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      booking.name,
                      style: LandingType.label(
                        12.5,
                        color: LandingPalette.ink,
                        weight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 12,
              child: Text(
                booking.trip,
                style: LandingType.label(12.5, weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: _BookingBoard._seatWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    booking.seat,
                    style: LandingType.label(
                      12.5,
                      color: LandingPalette.ink,
                      weight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _BookingBoard._payWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LandingBadge(label: booking.pay, tone: booking.payTone),
              ),
            ),
            SizedBox(
              width: _BookingBoard._statusWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LandingBadge(
                  label: booking.status,
                  tone: booking.statusTone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
