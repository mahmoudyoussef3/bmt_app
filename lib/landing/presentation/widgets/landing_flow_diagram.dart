import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'landing_container.dart';

/// One labelled node in a [LandingFlowDiagram].
class LandingFlowStep {
  const LandingFlowStep({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A vertical (mobile) / horizontal (desktop) chain of steps connected by
/// arrows — used for both the "unified platform" data flow and the
/// "operate → understand → grow" story. One widget, two stories, so the page
/// doesn't invent a second diagram shape for the same idea.
class LandingFlowDiagram extends StatelessWidget {
  const LandingFlowDiagram({super.key, required this.steps});

  final List<LandingFlowStep> steps;

  @override
  Widget build(BuildContext context) {
    final vertical = LandingContainer.isMobile(context);
    return vertical ? _buildVertical(context) : _buildHorizontal(context);
  }

  Widget _buildHorizontal(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      children.add(Expanded(child: _StepNode(step: steps[i])));
      if (i != steps.length - 1) {
        children.add(_Arrow(horizontal: true));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildVertical(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      children.add(_StepNode(step: steps[i]));
      if (i != steps.length - 1) {
        children.add(_Arrow(horizontal: false));
      }
    }
    return Column(children: children);
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({required this.step});

  final LandingFlowStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(18),
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withAlpha(70)),
          ),
          child: Icon(step.icon, color: scheme.primary, size: 26),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      // Deliberately not a directional glyph Material would mirror under
      // RTL for the wrong reason — "next stage in the story" always points
      // toward the reading direction's forward, so it must stay logical.
      horizontal ? Icons.arrow_back_ios_new_rounded : Icons.arrow_downward_rounded,
      size: 18,
      color: scheme.onSurfaceVariant,
    );
    if (horizontal) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: icon,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: icon,
    );
  }
}
