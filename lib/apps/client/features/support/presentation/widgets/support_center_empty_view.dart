import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'support_home_header.dart';
import 'support_quick_categories.dart';

/// Shown when the client has zero support tickets. Rather than a bare
/// illustration, it still surfaces the category rail so a first-time visitor
/// can go straight into filing a ticket for their actual issue.
class SupportCenterEmptyView extends StatelessWidget {
  const SupportCenterEmptyView({super.key, required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        const SupportHomeHeader(),
        const SizedBox(height: 28),
        SupportQuickCategories(categories: categories),
        const SizedBox(height: 36),
        Column(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 56,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No support tickets yet',
              textAlign: TextAlign.center,
              style: ClientTypography.headingSmall(context).copyWith(
                color: ClientColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a topic above, or create a ticket for anything else '
              'and our team will get back to you shortly.',
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ClientButton.secondary(
              label: 'Create a ticket',
              expand: false,
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => Navigator.pushNamed(
                context,
                ClientRoutes.createTicket,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
