import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A standardized wrapper for all Bottom Sheets in the client app.
/// Ensures consistent drag handles, padding, and corner radii.
class ClientBottomSheet extends StatelessWidget {
  const ClientBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.sheet), 
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? EdgeInsets.fromLTRB(24, showDragHandle ? 12 : 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ClientColors.borderStrongFor(context),
                      borderRadius: BorderRadius.circular(ClientRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (title != null) ...[
                Text(
                  title!,
                  style: ClientTypography.headingMedium(context)
                      .copyWith(color: ClientColors.textPrimaryFor(context)),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: ClientTypography.bodyMedium(context)
                        .copyWith(color: ClientColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper method to show a premium bottom sheet.
Future<T?> showClientBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: builder,
  );
}
