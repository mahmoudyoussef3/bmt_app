import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../domain/entities/office_summary.dart';
import 'office_card_body.dart';

/// One operator in the marketplace directory: the office's own photo framed
/// at the top with its name lettered across the foot, then where it drives
/// and how riders rate it, its own words, and the size of its network.
///
/// Shares its content with [HomeOfficeTile] via [OfficeCardBody] so an
/// operator looks like the same company whether a rider meets it on Home or
/// here — only the card's overall size differs.
class OfficeCard extends StatelessWidget {
  const OfficeCard({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  static const double heroHeight = 112;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.xxs),
      child: OfficeCardBody(office: office, heroHeight: heroHeight),
    );
  }
}
