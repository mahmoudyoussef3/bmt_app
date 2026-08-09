import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_brand_decor.dart';

/// The letterhead strip across the top of an operator tile.
///
/// It exists to give the card an anchor: without it the tile was a name
/// floating in white space, which read as an avatar rather than as a company.
///
/// The gradient and the discs cropped by the band's own edge are the same ones
/// the offices directory and an office's profile open with, so one operator
/// looks like one operator on all three surfaces.
class HomeOfficeBrandBand extends StatelessWidget {
  const HomeOfficeBrandBand({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
      ),
      child: const OfficeBrandDecor(scale: 0.5),
    );
  }
}
