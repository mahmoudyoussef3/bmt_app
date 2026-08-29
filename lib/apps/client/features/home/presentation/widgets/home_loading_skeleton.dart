import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Branded loading state mirroring the real home layout: the same deepening
/// hero fill as the real header renders immediately with placeholder shapes,
/// so the screen never feels blank while Supabase data loads.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final maxWidth = AppLayout.maxContentWidth(width);

    return ColoredBox(
      color: ClientColors.backgroundFor(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ClientColors.homeHeroGradientFor(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(ClientRadius.xl),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              ClientSpacing.md,
              topInset + ClientSpacing.md,
              ClientSpacing.md,
              ClientSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _GlassBox(width: 46, height: 46, radius: 23),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _GlassBox(width: 90, height: 11, radius: 6),
                              SizedBox(height: 8),
                              _GlassBox(width: 140, height: 18, radius: 6),
                            ],
                          ),
                        ),
                        _GlassBox(width: 44, height: 44, radius: 14),
                      ],
                    ),
                    SizedBox(height: ClientSpacing.lg),
                    _GlassBox(height: 66, radius: 33),
                    SizedBox(height: ClientSpacing.md),
                    Row(
                      children: [
                        _GlassBox(width: 110, height: 34, radius: 17),
                        SizedBox(width: 8),
                        _GlassBox(width: 96, height: 34, radius: 17),
                        SizedBox(width: 8),
                        _GlassBox(width: 104, height: 34, radius: 17),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(ClientSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: index == 3 ? 0 : 10,
                            ),
                            child: const ClientSkeleton(
                              height: 102,
                              borderRadius: ClientRadius.lg,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: ClientSpacing.lg),
                    const ClientSkeleton(
                      height: 264,
                      borderRadius: ClientRadius.lg,
                    ),
                    const SizedBox(height: ClientSpacing.sm),
                    const ClientSkeleton(
                      height: 264,
                      borderRadius: ClientRadius.lg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
