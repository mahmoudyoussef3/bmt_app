import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';

/// The stub of the ticket: the facts a rider checks at the door — which
/// vehicle pulls up, and who is driving it.
class CheckoutTicketFacts extends StatelessWidget {
  const CheckoutTicketFacts({super.key, required this.data});

  final PaymentCheckoutData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Fact(
          icon: Icons.airport_shuttle_rounded,
          label: 'Vehicle',
          value: data.vehicleNumber,
        ),
        _Fact(
          icon: Icons.person_rounded,
          label: 'Driver',
          value: data.driverName,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          const SizedBox(height: 4),
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
    );
  }
}
