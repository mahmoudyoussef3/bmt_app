import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

import 'dashboard_auth_brand_panel.dart';

/// The two-up frame both signed-out screens sit in: the brand sweep on the
/// leading side, the form on a plain console surface beside it.
///
/// Below [splitBreakpoint] the panel folds into a band above the form
/// ([DashboardAuthBrandBand]) instead of shrinking — a gradient column narrow
/// enough to fit next to a usable form is a stripe, not a brand statement.
class DashboardAuthLayout extends StatelessWidget {
  const DashboardAuthLayout({super.key, required this.form, this.action});

  /// The form column. Constrained to [formMaxWidth] and centred on its side.
  final Widget form;

  /// A single quiet control pinned to the outer corner of the form side — the
  /// theme toggle. Optional so a harness can mount the layout without one.
  final Widget? action;

  /// The console is a desktop product; this is the width below which a real
  /// side-by-side split stops being one.
  static const double splitBreakpoint = 1000;

  static const double formMaxWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.panel(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= splitBreakpoint) {
            return Row(
              children: [
                const Expanded(flex: 45, child: DashboardAuthBrandPanel()),
                Expanded(
                  flex: 55,
                  child: _FormSide(action: action, child: form),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DashboardAuthBrandBand(),
              Expanded(
                child: _FormSide(action: action, child: form),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormSide extends StatelessWidget {
  const _FormSide({required this.child, this.action});

  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DashboardColors.panel(context),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DashboardAuthLayout.formMaxWidth,
                ),
                child: child,
              ),
            ),
          ),
          if (action != null)
            PositionedDirectional(top: 12, end: 12, child: action!),
        ],
      ),
    );
  }
}
