import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_frames.dart';
import '../widgets/landing_layout.dart';

/// «تجربة العميل» — the five things a rider can now do without ringing the
/// office, and the screen they do them on.
class ClientSection extends StatelessWidget {
  const ClientSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface,
      topBorder: true,
      bottomBorder: true,
      child: _ClientBand(
        gap: landingClamp(context, min: 28, vw: 4, max: 52),
        copy: const _ClientCopy(),
        phone: const Center(
          child: LandingPhoneShell(
            // Filling the 250px column the design fixes for it: a capture is
            // a denser screen than the board it replaces and wants the room.
            designWidth: _ClientBand._phoneColumn,
            bodyPadding: 9,
            outerRadius: 30,
            innerRadius: 23,
            screenColor: LandingPalette.surface2,
            shadow: [
              BoxShadow(
                color: Color(0x800B1B34),
                offset: Offset(0, 30),
                blurRadius: 60,
                spreadRadius: -30,
              ),
            ],
            // Booking a seat — the one thing on the list the rider
            // used to have to ring the office for.
            child: LandingShotScreen(asset: LandingShots.clientSeats),
          ),
        ),
      ),
    );
  }
}

/// The copy takes every pixel the 250px phone column leaves — the design's
/// `flex: 1 1 360px` beside a `flex: 0 1 250px`, which never grows.
class _ClientBand extends StatelessWidget {
  const _ClientBand({
    required this.gap,
    required this.copy,
    required this.phone,
  });

  final double gap;
  final Widget copy;
  final Widget phone;

  static const _phoneColumn = 250.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              SizedBox(height: gap),
              phone,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: copy),
            SizedBox(width: gap),
            SizedBox(width: _phoneColumn, child: phone),
          ],
        );
      },
    );
  }
}

class _ClientCopy extends StatelessWidget {
  const _ClientCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LandingSectionIntro(
          eyebrow: LandingContent.clientEyebrow,
          headline: LandingContent.clientHeadline,
          lead: LandingContent.clientLead,
          maxWidth: 520,
          headlineMin: 23,
          headlineVw: 2.8,
          headlineMax: 34,
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < LandingContent.clientPoints.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: LandingPalette.brand,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LandingContent.clientPoints[i],
                  style: LandingType.label(
                    14,
                    color: LandingPalette.ink,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
