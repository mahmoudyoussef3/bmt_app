import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/profile/data/datasources/legal_content.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/legal_document_data.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/legal_section_card.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Renders Terms or Privacy. Both documents are the same reading experience —
/// only the content differs — so they share one screen rather than two
/// near-identical ones.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = switch (document) {
      LegalDocument.terms => LegalContent.terms,
      LegalDocument.privacy => LegalContent.privacy,
    };
    final title = switch (document) {
      LegalDocument.terms => l10n.profile_terms,
      LegalDocument.privacy => l10n.profile_privacy,
    };
    final maxW = AppLayout.maxContentWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: ClientAppBar(
        title: title,
        backgroundColor: ClientColors.backgroundFor(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: ListView.separated(
              padding: AppLayout.pagePaddingWithTop,
              itemCount: sections.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppLayout.spaceMd),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _LastUpdated(
                    label: l10n.profile_lastUpdated(
                      FormatUtil.date(context, LegalContent.lastUpdated),
                    ),
                  );
                }
                final section = sections[index - 1];
                return LegalSectionCard(number: index, section: section);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  const _LastUpdated({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.spaceXs),
      child: Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 16,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(width: AppLayout.spaceXs),
          Text(
            label,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}
