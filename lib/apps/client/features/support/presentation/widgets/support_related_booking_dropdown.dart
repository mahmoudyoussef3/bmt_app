import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/related_booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'support_input_decoration.dart';

/// "Which booking is this about?" — optional. Linking a booking is what routes
/// the ticket to the office that operated the trip; left empty, the ticket
/// stays with EWT platform support. The office itself is never selectable —
/// the backend derives it from the chosen booking.
class SupportRelatedBookingDropdown extends StatelessWidget {
  const SupportRelatedBookingDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<RelatedBookingOption> options;
  final RelatedBookingOption? value;
  final ValueChanged<RelatedBookingOption?> onChanged;

  String _label(RelatedBookingOption option) {
    final date = option.tripDate;
    final datePart = date == null ? '' : ' • ${date.day}/${date.month}';
    final seatPart = option.seat.isEmpty ? '' : ' • ${option.seat}';
    return '${option.route}$datePart$seatPart';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final itemStyle = ClientTypography.bodyMedium(
      context,
    ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600);

    return DropdownButtonFormField<RelatedBookingOption?>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
      decoration: supportInputDecoration(context),
      style: itemStyle,
      items: [
        DropdownMenuItem<RelatedBookingOption?>(
          value: null,
          child: Text(
            context.l10n.support_relatedBookingNone,
            style: itemStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        ...options.map(
          (option) => DropdownMenuItem<RelatedBookingOption?>(
            value: option,
            child: Text(
              _label(option),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: itemStyle,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
