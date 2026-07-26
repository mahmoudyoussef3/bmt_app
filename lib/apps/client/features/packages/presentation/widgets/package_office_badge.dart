import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';

import '../../domain/entities/package_plan.dart';

/// The provider identity a package card wears: seller logo, name and rating, so
/// a mixed catalogue always says whose offer each card is. Renders nothing when
/// the package carries no office — the repository already drops those, so this
/// is belt-and-braces for a hand-built entity.
class PackageOfficeBadge extends StatelessWidget {
  const PackageOfficeBadge({
    super.key,
    required this.package,
    this.logoSize = 22,
  });

  final PackagePlan package;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    if (!package.hasOffice) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        OfficeLogoAvatar(logoUrl: package.officeLogoUrl, size: logoSize),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            package.officeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
        ),
        if (package.hasOfficeRating) ...[
          const SizedBox(width: 8),
          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            package.officeRating.toStringAsFixed(1),
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
        ],
      ],
    );
  }
}
