import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Checkout while the methods load. It is laid out as the screen that is
/// coming — ticket, fare, then methods — so nothing jumps when the real
/// content lands. A centred spinner would tell the rider nothing about what
/// they are waiting for.
class CheckoutSkeleton extends StatelessWidget {
  const CheckoutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: const [
        ClientSkeleton(height: 210, borderRadius: ClientRadius.lg),
        SizedBox(height: 16),
        ClientSkeleton(height: 150, borderRadius: ClientRadius.lg),
        SizedBox(height: 20),
        ClientSkeleton(height: 16, width: 180, borderRadius: 6),
        SizedBox(height: 12),
        _MethodRow(),
        SizedBox(height: 10),
        _MethodRow(),
        SizedBox(height: 10),
        _MethodRow(),
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: const Row(
        children: [
          ClientSkeleton(height: 42, width: 42, borderRadius: 21),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientSkeleton(height: 14, width: 120, borderRadius: 6),
                SizedBox(height: 6),
                ClientSkeleton(height: 11, width: 170, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 8),
          ClientSkeleton(height: 22, width: 22, borderRadius: 11),
        ],
      ),
    );
  }
}
