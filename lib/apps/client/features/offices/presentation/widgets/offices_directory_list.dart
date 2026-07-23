import 'package:flutter/material.dart';

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
      itemCount: offices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
