import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Builds the standard invite copy + deep link for a referral code, and shares
/// it through WhatsApp / Facebook / Messenger / Instagram / the native sheet.
class ReferralShareService {
  const ReferralShareService._();

  static const _appLinkBase = 'https://easyway.app/r/';

  static String inviteLink(String code) => '$_appLinkBase$code';

  static String inviteMessage(BuildContext context, String code) =>
      context.l10n.referral_inviteMessage(code, inviteLink(code));

  static Future<void> shareNative(BuildContext context, String code) async {
    await Share.share(
      inviteMessage(context, code),
      subject: context.l10n.referral_shareYourInvite,
    );
  }

  static Future<bool> shareWhatsApp(BuildContext context, String code) {
    final text = Uri.encodeComponent(inviteMessage(context, code));
    return _launch('https://wa.me/?text=$text');
  }

  static Future<bool> shareFacebook(String code) {
    final url = Uri.encodeComponent(inviteLink(code));
    return _launch('https://www.facebook.com/sharer/sharer.php?u=$url');
  }

  static Future<bool> shareMessenger(String code) {
    final link = Uri.encodeComponent(inviteLink(code));
    return _launch('fb-messenger://share?link=$link');
  }

  /// Instagram has no public text-share URL, so we copy the invite and open the
  /// app for the user to paste into a story or DM.
  static Future<bool> shareInstagram(BuildContext context, String code) async {
    await Clipboard.setData(
      ClipboardData(text: inviteMessage(context, code)),
    );
    if (await _launch('instagram://app')) return true;
    return _launch('https://www.instagram.com');
  }

  static Future<bool> _launch(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Premium bottom sheet listing the referral share channels.
class ReferralShareSheet extends StatelessWidget {
  const ReferralShareSheet({super.key, required this.code});

  final String code;

  static Future<void> show(BuildContext context, String code) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReferralShareSheet(code: code),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await action();
    if (!ok && context.mounted) {
      await ReferralShareService.shareNative(context, code);
    }
    if (navigator.canPop()) navigator.pop();
    messenger.hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channels = <_ShareChannel>[
      _ShareChannel(
        icon: Icons.chat_rounded,
        label: l10n.referral_channelWhatsapp,
        color: const Color(0xFF25D366),
        onTap: () => _run(
          context,
          () => ReferralShareService.shareWhatsApp(context, code),
        ),
      ),
      _ShareChannel(
        icon: Icons.facebook_rounded,
        label: l10n.referral_channelFacebook,
        color: const Color(0xFF1877F2),
        onTap: () =>
            _run(context, () => ReferralShareService.shareFacebook(code)),
      ),
      _ShareChannel(
        icon: Icons.send_rounded,
        label: l10n.referral_channelMessenger,
        color: const Color(0xFF0084FF),
        onTap: () =>
            _run(context, () => ReferralShareService.shareMessenger(code)),
      ),
      _ShareChannel(
        icon: Icons.camera_alt_rounded,
        label: l10n.referral_channelInstagram,
        color: const Color(0xFFE1306C),
        onTap: () => _run(
          context,
          () => ReferralShareService.shareInstagram(context, code),
        ),
      ),
      _ShareChannel(
        icon: Icons.copy_rounded,
        label: l10n.referral_copyLink,
        color: ClientColors.journeySlate,
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          await Clipboard.setData(
            ClipboardData(
              text: ReferralShareService.inviteMessage(context, code),
            ),
          );
          if (navigator.canPop()) navigator.pop();
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.referral_inviteCopiedSnack)),
          );
        },
      ),
      _ShareChannel(
        icon: Icons.ios_share_rounded,
        label: l10n.referral_more,
        color: ClientColors.primary,
        onTap: () => _run(context, () async {
          await ReferralShareService.shareNative(context, code);
          return true;
        }),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: ClientColors.borderStrongFor(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.referral_shareYourInvite,
              style: ClientTypography.headingMedium(context),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.referral_shareSheetSubtitle(code),
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
              children: [for (final c in channels) _ChannelButton(channel: c)],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareChannel {
  const _ShareChannel({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({required this.channel});

  final _ShareChannel channel;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: channel.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: channel.color.withAlpha(28),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(channel.icon, color: channel.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            channel.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}
