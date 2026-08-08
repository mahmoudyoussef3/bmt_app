import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'landing_section_header.dart';

/// A capability card used by the problem grid and the features grid — an
/// icon chip, a title and a short line of body copy. Hovers lift slightly on
/// desktop (mouse present); touch devices get no hover state to fake.
class LandingFeatureCard extends StatefulWidget {
  const LandingFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  State<LandingFeatureCard> createState() => _LandingFeatureCardState();
}

class _LandingFeatureCardState extends State<LandingFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = widget.iconColor ?? scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        offset: _hovered ? const Offset(0, -0.02) : Offset.zero,
        curve: Curves.easeOut,
        child: SizedBox(
          height: 190,
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.withAlpha(_hovered ? 30 : 18),
                    borderRadius: BorderRadius.circular(LandingRadius.card - 4),
                  ),
                  child: Icon(widget.icon, color: tint, size: 22),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    widget.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive 4/2/1-column grid for [LandingFeatureCard]s — mirrors
/// [DashboardKpiGrid]'s breakpoints so the whole product feels like one
/// system, without pulling the dashboard-scoped widget itself into this
/// standalone entry point.
class LandingCardGrid extends StatelessWidget {
  const LandingCardGrid({super.key, required this.children, this.maxColumns = 4});

  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final base = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final columns = base > maxColumns ? maxColumns : base;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.large,
            mainAxisSpacing: AppSpacing.large,
            mainAxisExtent: 190,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
