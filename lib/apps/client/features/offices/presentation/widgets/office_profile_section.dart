import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import 'office_section_header.dart';

/// One titled block of an office profile — the heading and whatever list or
/// empty note answers it — plus the rule of space that separates it from the
/// next one.
///
/// It carries the `GlobalKey` the masthead's stat strip scrolls to, which is
/// why the spacing lives here rather than between siblings: the jump target
/// must be the heading, not the gap above it.
class OfficeProfileSectionBlock extends StatelessWidget {
  const OfficeProfileSectionBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.child,
  });

  final IconData icon;
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ClientSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OfficeSectionHeader(icon: icon, title: title, count: count),
          const SizedBox(height: ClientSpacing.sm),
          child,
        ],
      ),
    );
  }
}
