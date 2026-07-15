import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The stub of the ticket: the facts a rider checks at the door — which
/// vehicle pulls up, and who is driving it, with a photo of each when the
/// operator has one on file and the captain's star rating alongside the name.
class CheckoutTicketFacts extends StatelessWidget {
  const CheckoutTicketFacts({super.key, required this.data});

  final PaymentCheckoutData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Fact(
          media: _VehicleThumb(imageUrl: data.vehicleImageUrl),
          icon: Icons.airport_shuttle_rounded,
          label: context.l10n.payments_vehicle,
          value: data.vehicleLabel,
        ),
        const SizedBox(height: 14),
        _Fact(
          media: _DriverAvatar(
            imageUrl: data.driverImageUrl,
            name: data.driverName,
          ),
          icon: Icons.person_rounded,
          label: context.l10n.payments_driver,
          value: data.driverName,
          trailing: data.driverRating > 0
              ? _RatingPill(rating: data.driverRating)
              : null,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.media,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final Widget media;
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        media,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: ClientColors.textTertiaryFor(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.textTertiaryFor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// A rounded thumbnail of the vehicle, falling back to a shuttle glyph while
/// the image loads or when the operator has no photo on file.
class _VehicleThumb extends StatelessWidget {
  const _VehicleThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
      child: Icon(
        Icons.airport_shuttle_rounded,
        size: 22,
        color: ClientColors.textTertiaryFor(context),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl.trim().isEmpty
            ? placeholder
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              ),
      ),
    );
  }
}

/// A circular portrait of the captain, falling back to their initial.
class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final placeholder = _Placeholder(
      child: Text(
        initial,
        style: ClientTypography.bodyMedium(context).copyWith(
          fontWeight: FontWeight.w800,
          color: ClientColors.primaryFor(context),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl.trim().isEmpty
            ? placeholder
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ClientColors.surfaceMutedFor(context),
      child: Center(child: child),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.primaryFor(context).withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: ClientColors.primaryFor(context),
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: ClientTypography.labelMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: ClientColors.primaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
