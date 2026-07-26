import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../../domain/entities/package_plan.dart';
import '../../cubit/packages_cubit.dart';
import '../../routes/subscription_arguments.dart';
import 'package_card_backdrop.dart';
import 'package_card_body.dart';

class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    required this.arguments,
  });

  final PackagePlan package;
  final SubscriptionArguments arguments;

  /// Details are pure discovery — what the package is, who sells it, what it
  /// costs — so a rider can open them with or without a trip in hand. The
  /// subscribe CTA inside the details pane is where a trip becomes required.
  void _onTap(BuildContext context) {
    context.read<PackagesCubit>().openDetails(package);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: () => _onTap(context),
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [scheme.surfaceContainerHighest, scheme.surfaceContainer]
                : [scheme.surface, scheme.surfaceContainerLow.withAlpha(100)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ClientRadius.xl),
          border: Border.all(color: scheme.outline.withAlpha(isDark ? 40 : 80)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withAlpha(isDark ? 10 : 15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ClientRadius.xl),
          child: Stack(
            children: [
              // Decoration only — must not size the card, or the all-positioned
              // Stack inside it would take the list's unbounded height.
              const Positioned.fill(child: PackageCardBackdrop()),
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PackageCardBody(package: package),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
