import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// A small banner that appears only while the device has no network
/// connection, so a captain mid-trip knows why an action might be stalling
/// instead of wondering whether the app itself is broken.
class CaptainConnectivityBanner extends StatefulWidget {
  const CaptainConnectivityBanner({super.key});

  @override
  State<CaptainConnectivityBanner> createState() =>
      _CaptainConnectivityBannerState();
}

class _CaptainConnectivityBannerState extends State<CaptainConnectivityBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) setState(() => _offline = _isOffline(results));
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _offline = _isOffline(results));
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.none) ||
        (results.length == 1 && results.first == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();

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
