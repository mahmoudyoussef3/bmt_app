import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

class SubscriptionConfirmationScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final String time;
  final String planName;
  final String price;

  const SubscriptionConfirmationScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.time,
    required this.planName,
    required this.price,
  });

  @override
  State<SubscriptionConfirmationScreen> createState() =>
      _SubscriptionConfirmationScreenState();
}

class _SubscriptionConfirmationScreenState
    extends State<SubscriptionConfirmationScreen>
    with TickerProviderStateMixin {
  bool _processing = true;
  late final String _subscriptionId;
  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _subscriptionId = _generateId();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _processing = false);
      _checkController.forward();
    });
  }

  String _generateId() {
    final rng = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return 'SUB-${List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join()}';
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Subscription',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: _processing
                      ? _processingView(context)
                      : _successView(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ClientButton.secondary(
                      label: 'Back to Home',
                      expand: true,
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClientButton(
                      label: 'Done',
                      expand: true,
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingView(BuildContext context) {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: 18),
        Text(
          'Activating your subscription...',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'We are locking your monthly route now',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _successView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _checkController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withAlpha(180)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Subscription Confirmed',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Your monthly commute is now active',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subscription ID',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _subscriptionId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destination,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.planName} plan',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Starts',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          widget.time,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Pickup: ${widget.pickup}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan price: ${widget.price}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
