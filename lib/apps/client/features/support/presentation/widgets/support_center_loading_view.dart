import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';

/// Shimmer skeleton shown while the Support Center's first load (categories
/// + tickets) is in flight. Mirrors the shape of the loaded content so the
/// layout doesn't jump once real data arrives.
class SupportCenterLoadingView extends StatelessWidget {
  const SupportCenterLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const ClientSkeleton(height: 14, width: 180, borderRadius: 6),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) =>
                const ClientSkeleton(height: 96, width: 92, borderRadius: 12),
          ),
        ),
        const SizedBox(height: 28),
        const ClientSkeleton(height: 14, width: 100, borderRadius: 6),
        const SizedBox(height: 16),
        for (int i = 0; i < 3; i++) ...[
          _SkeletonTicketCard(),
          if (i < 2) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SkeletonTicketCard extends StatelessWidget {
  const _SkeletonTicketCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ClientSkeleton(height: 22, width: 90, borderRadius: 10),
              ClientSkeleton(height: 14, width: 70, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 16),
          const ClientSkeleton(height: 18, width: 200, borderRadius: 6),
          const SizedBox(height: 8),
          const ClientSkeleton(height: 13, width: double.infinity, borderRadius: 6),
          const SizedBox(height: 6),
          const ClientSkeleton(height: 13, width: 160, borderRadius: 6),
        ],
      ),
    );
  }
}
