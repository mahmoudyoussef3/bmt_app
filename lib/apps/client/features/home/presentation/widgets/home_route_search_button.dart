import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// The route search card's call to action.
///
/// Deliberately not a [ClientButton]: inside the card the CTA is the third
/// element of a stack, so it takes the fields' corner radius instead of the
/// app's pill. Every CTA outside this card stays a [ClientButton].
class HomeRouteSearchButton extends StatelessWidget {
  const HomeRouteSearchButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ClientColors.primaryFillFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(context).copyWith(
                  color: ClientColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: ClientColors.textInverse,
            ),
          ],
        ),
      ),
    );
  }
}
