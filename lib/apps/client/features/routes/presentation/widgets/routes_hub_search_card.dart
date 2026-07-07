import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// The primary "search trips" call to action on the Routes tab.
class RoutesHubSearchCard extends StatelessWidget {
  const RoutesHubSearchCard({
    super.key,
    required this.title,
    required this.description,
    required this.onSearch,
  });

  final String title;
  final String description;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ClientColors.primaryFor(context).withAlpha(18),
                  borderRadius: BorderRadius.circular(ClientRadius.sm),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: ClientColors.primaryFor(context),
                ),
              ),
              const SizedBox(width: ClientSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ClientTypography.headingSmall(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClientSpacing.lg),
          ClientButton(label: 'Search trips', onPressed: onSearch),
        ],
      ),
    );
  }
}
