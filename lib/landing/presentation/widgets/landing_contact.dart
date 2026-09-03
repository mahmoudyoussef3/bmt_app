import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import 'landing_atoms.dart';

/// The two channels the site can actually hand a reader.
///
/// The page has no sign-up flow behind its CTAs, so an email address and a
/// phone number are the only real destinations it owns. They are modelled
/// once here because three surfaces now offer them — the contact dialog, the
/// closing band and the footer — and a phone number that disagrees with
/// itself across a page is the fastest way to look unserious.
enum LandingChannel { email, phone }

extension LandingChannelInfo on LandingChannel {
  String get label => switch (this) {
    LandingChannel.email => 'البريد الإلكتروني',
    LandingChannel.phone => 'الهاتف',
  };

  String get value => switch (this) {
    LandingChannel.email => LandingContent.contactEmail,
    LandingChannel.phone => LandingContent.contactPhone,
  };

  IconData get icon => switch (this) {
    LandingChannel.email => Icons.mail_outline_rounded,
    LandingChannel.phone => Icons.call_outlined,
  };

  Uri get uri => switch (this) {
    LandingChannel.email => Uri(scheme: 'mailto', path: value),
    LandingChannel.phone => Uri(scheme: 'tel', path: value),
  };
}

/// Opens [uri], reporting a refusal in place rather than doing nothing.
///
/// The messenger is resolved before the await so nothing reads a
/// [BuildContext] across an async gap.
Future<void> launchLandingUri(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var launched = false;
  try {
    launched = await launchUrl(uri);
  } catch (_) {
    launched = false;
  }
  if (!launched) {
    messenger?.showSnackBar(SnackBar(content: Text('تعذر فتح ${uri.scheme}')));
  }
}

/// One contact channel as a tappable tile on a navy band — the shape used in
/// the closing band, where the channels are an action rather than a footnote.
class LandingChannelTile extends StatefulWidget {
  const LandingChannelTile({super.key, required this.channel});

  final LandingChannel channel;

  @override
  State<LandingChannelTile> createState() => _LandingChannelTileState();
}

class _LandingChannelTileState extends State<LandingChannelTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    return Semantics(
      button: true,
      label: '${channel.label} ${channel.value}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => launchLandingUri(context, channel.uri),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _hovered ? 0.13 : 0.06),
              borderRadius: BorderRadius.circular(LandingRadii.card - 2),
              border: Border.all(
                color: Colors.white.withValues(alpha: _hovered ? 0.34 : 0.16),
              ),
            ),
            child: Row(
              children: [
                LandingIconSquare(
                  icon: channel.icon,
                  size: 34,
                  iconSize: 17,
                  radius: 10,
                  background: Colors.white.withValues(alpha: 0.10),
                  borderColor: Colors.white.withValues(alpha: 0.18),
                  iconColor: LandingPalette.onNavyAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.label,
                        style: LandingType.label(
                          11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // An address and a number read left-to-right even here,
                      // and neither may be clipped: the tile scales the run
                      // down before it would run out of room.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          channel.value,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: LandingType.label(
                            13.5,
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: _hovered ? 0.8 : 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
