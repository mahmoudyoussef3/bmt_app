import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'support_category_card.dart';

/// Horizontal rail of support categories shown at the top of the Support
/// Center. Lets the client jump straight into a pre-filled ticket instead of
/// always landing on the generic "Create Ticket" FAB and picking a category
/// from a dropdown.
class SupportQuickCategories extends StatelessWidget {
  const SupportQuickCategories({super.key, required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you need help with?',
          style: ClientTypography.labelMedium(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return SupportCategoryCard(
                title: category,
                onTap: () => Navigator.pushNamed(
                  context,
                  ClientRoutes.createTicket,
                  arguments: category,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
