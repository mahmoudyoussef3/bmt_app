import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import 'office_logo_avatar.dart';

/// An operator's logo on a raised, bordered tile.
///
/// The same object on every surface a rider meets the company — the Home rail,
/// the directory card, the profile masthead — so one operator is recognisable
/// as one operator rather than three differently framed images.
class OfficeLogoTile extends StatelessWidget {
  const OfficeLogoTile({
    super.key,
    required this.logoUrl,
    required this.size,
    this.raised = true,
  });

  final String? logoUrl;
  final double size;

  /// Whether the tile lifts off the surface behind it. False where the tile
  /// sits inside a card that already carries the elevation.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final inset = size * 0.11;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: raised ? ClientElevation.sm(context) : null,
      ),
      child: OfficeLogoAvatar(logoUrl: logoUrl, size: size - inset * 2),
    );
  }
}
