import 'package:flutter/material.dart';

import '../network/captain_connectivity_watcher.dart';
import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

class CaptainConnectivityBanner extends StatefulWidget {
  const CaptainConnectivityBanner({super.key, this.watcher});

  final CaptainConnectivityWatcher? watcher;

  @override
  State<CaptainConnectivityBanner> createState() =>
      _CaptainConnectivityBannerState();
}

class _CaptainConnectivityBannerState extends State<CaptainConnectivityBanner>
    with WidgetsBindingObserver {
  late final CaptainConnectivityWatcher _watcher;
  late final bool _ownsWatcher;

  @override
  void initState() {
    super.initState();
    _ownsWatcher = widget.watcher == null;
    _watcher = widget.watcher ?? CaptainConnectivityWatcher();
    if (_ownsWatcher) _watcher.start();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _watcher.recheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsWatcher) _watcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _watcher,
      builder: (context, isOffline, _) =>
          isOffline ? const _OfflineBanner() : const SizedBox.shrink(),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.error.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: CaptainColors.error,
            size: 18,
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت حالياً',
              style: CaptainTypography.labelLarge(context).copyWith(
                color: CaptainColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
