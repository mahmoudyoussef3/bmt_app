import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

class HomeTripCta extends StatelessWidget {
  const HomeTripCta({super.key, required this.trip, required this.onBook});

  final UpcomingTripData trip;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Expanded(child: _Fare(price: trip.price))],
    );
  }
}

class _Fare extends StatelessWidget {
  const _Fare({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    if (price.isEmpty) {
      return Text(
        context.l10n.home_fareNotPublished,
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      //   mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.home_fareFrom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,

          style: ClientTypography.priceMedium(context)
              .copyWith(color: ClientColors.primaryFor(context))
              .copyWith(
                color: ClientColors.textTertiaryFor(context),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
        ),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.priceMedium(
            context,
          ).copyWith(color: ClientColors.primaryFor(context)),
        ),
      ],
    );
  }
}
