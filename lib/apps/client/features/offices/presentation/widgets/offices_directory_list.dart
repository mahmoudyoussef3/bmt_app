import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import '../../domain/entities/office_summary.dart';
import '../routes/offices_routes.dart';
import 'office_card.dart';

/// The scrollable list of offices, best-rated first.
class OfficesDirectoryList extends StatelessWidget {
  const OfficesDirectoryList({super.key, required this.offices});

  final List<OfficeSummary> offices;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: offices.length,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.md),
      itemBuilder: (context, index) => OfficeCard(
        office: offices[index],
        onTap: () => Navigator.pushNamed(
          context,
          OfficesRoutes.profile,
          arguments: offices[index],
        ),
      ),
    );
  }
}
