import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One segment of a [ClientSegmentedTabs].
@immutable
class ClientSegment {
  const ClientSegment({required this.label, this.trailing});

  final String label;

  /// Optional badge drawn after the label — a count, usually.
  final Widget? trailing;
}

/// The design's segmented control: a `--surface-2` track carrying one raised
/// `--surface` thumb under the selected label.
///
/// Used where a small, fixed set of views splits one list — My Trips'
/// upcoming/active/completed/cancelled being the case it was drawn for. The
/// thumb slides rather than cutting, so the eye follows the selection instead
/// of re-finding it, and every segment keeps an equal share of the width so the
/// control does not reflow when a count appears.
class ClientSegmentedTabs extends StatelessWidget {
  const ClientSegmentedTabs({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ClientSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final active = selectedIndex.clamp(0, segments.length - 1);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: ClientMotion.base,
                curve: ClientMotion.curve,
                start: active * slot,
                top: 0,
                bottom: 0,
                width: slot,
                child: Container(
                  decoration: BoxDecoration(
                    color: ClientColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(ClientRadius.xs),
                    boxShadow: ClientElevation.sm(context),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: _Segment(
                        segment: segments[i],
                        isActive: i == active,
                        onTap: () {
                          if (i == active) return;
                          HapticFeedback.selectionClick();
                          onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.isActive,
    required this.onTap,
  });

  final ClientSegment segment;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: ClientTypography.labelMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? ClientColors.textPrimaryFor(context)
                        : ClientColors.textSecondaryFor(context),
                  ),
                ),
              ),
              if (segment.trailing case final trailing?) ...[
                const SizedBox(width: 5),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
