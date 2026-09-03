import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import 'landing_atoms.dart';

/// A short, honest dialog for CTAs that have no real destination yet
/// (sign-in, "start with EWT", contact). Used instead of linking to a page
/// that doesn't exist — the marketing site is a standalone entry point with
/// no signed-in state to hand off to.
class LandingInfoDialog extends StatelessWidget {
  const LandingInfoDialog({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierColor: LandingPalette.navy.withValues(alpha: 0.42),
      builder: (_) => LandingInfoDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LandingPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LandingRadii.card + 4),
        side: const BorderSide(color: LandingPalette.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LandingIconSquare(
                    icon: Icons.info_outline_rounded,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: LandingType.cardTitle(17)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message, style: LandingType.cardBody(13.5)),
              const SizedBox(height: 22),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LandingButton(
                  label: 'إغلاق',
                  height: 42,
                  style: LandingButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "تواصل معنا" dialog — real, tappable contact details instead of the
/// generic [LandingInfoDialog] message, since a reader who reaches this
/// point wants an email or a phone number, not more copy.
class LandingContactDialog extends StatelessWidget {
  const LandingContactDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: LandingPalette.navy.withValues(alpha: 0.42),
      builder: (_) => const LandingContactDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LandingPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LandingRadii.card + 4),
        side: const BorderSide(color: LandingPalette.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LandingIconSquare(
                    icon: Icons.support_agent_rounded,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('تواصل معنا', style: LandingType.cardTitle(17)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'يسعدنا تواصلك معنا لمعرفة الخطة المناسبة لمكتبك أو لأي '
                'استفسار.',
                style: LandingType.cardBody(13.5),
              ),
              const SizedBox(height: 20),
              _ContactRow(
                icon: Icons.mail_outline_rounded,
                label: LandingContent.contactEmail,
                onTap: () => _launch(
                  context,
                  Uri(scheme: 'mailto', path: LandingContent.contactEmail),
                ),
              ),
              const SizedBox(height: 10),
              _ContactRow(
                icon: Icons.call_outlined,
                label: LandingContent.contactPhone,
                onTap: () => _launch(
                  context,
                  Uri(scheme: 'tel', path: LandingContent.contactPhone),
                ),
              ),
              const SizedBox(height: 22),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LandingButton(
                  label: 'إغلاق',
                  height: 42,
                  style: LandingButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر فتح ${uri.scheme}')));
    }
  }
}

/// One tappable row: an icon square and a value pinned to LTR, since an
/// email address or a phone number reads left-to-right even on this
/// right-to-left page.
class _ContactRow extends StatefulWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? LandingPalette.brandTint : LandingPalette.well,
            borderRadius: BorderRadius.circular(LandingRadii.card - 4),
            border: Border.all(
              color: _hovered
                  ? LandingPalette.brandLine
                  : LandingPalette.border,
            ),
          ),
          child: Row(
            children: [
              LandingIconSquare(
                icon: widget.icon,
                size: 32,
                iconSize: 16,
                radius: 9,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: LandingType.cardTitle(13.5),
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: LandingPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
