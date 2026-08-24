import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_card_body.dart';

/// One operator, as a smaller printing of the same card the offices directory
/// uses ([OfficeCardBody]) — Home is a shortcut into the marketplace, not a
/// different catalogue of it, so a rider who trusts one operator here should
/// recognise it instantly in the full directory too.
class HomeOfficeTile extends StatelessWidget {
  const HomeOfficeTile({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  static const double width = 252;
  static const double height = 196;
  static const double _heroHeight = 84;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClientCard(
        onTap: onTap,
        padding: const EdgeInsets.all(ClientSpacing.xxs),
        child: OfficeCardBody(
          office: office,
          heroHeight: _heroHeight,
          dense: true,
        ),
      ),
    );
  }
}
