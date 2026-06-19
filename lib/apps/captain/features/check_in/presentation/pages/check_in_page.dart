import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/check_in_result.dart';
import '../cubit/check_in_cubit.dart';
import '../cubit/check_in_state.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late final MobileScannerController _scanner;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(autoStart: true);
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckInCubit>(
      create: (ctx) {
        final cubit = captainGetIt<CheckInCubit>();
        cubit.loadQueueCount();
        cubit.flushOfflineQueue();
        return cubit;
      },
      child: BlocConsumer<CheckInCubit, CheckInState>(
        listener: (context, state) {
          if (state is CheckInReady || state is CheckInError) {
            // Re-enable scanner after 2 s so driver can see result
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _lastScanned = null;
                _scanner.start();
              }
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('تسجيل دخول الركاب'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on_rounded),
                  onPressed: _scanner.toggleTorch,
                ),
              ],
            ),
            body: Column(
              children: [
                if (state is CheckInReady && state.offlineQueueCount > 0)
                  MaterialBanner(
                    content: Text(
                      'وضع بلا إنترنت — ${state.offlineQueueCount} تسجيل في الانتظار',
                    ),
                    leading: const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.orange,
                    ),
                    backgroundColor: Colors.orange.shade50,
                    actions: [
                      TextButton(
                        onPressed: () =>
                            context.read<CheckInCubit>().flushOfflineQueue(),
                        child: const Text('إرسال الآن'),
                      ),
                    ],
                  ),
                SizedBox(
                  height: 300,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scanner,
                        onDetect: (capture) {
                          final code = capture.barcodes.firstOrNull?.rawValue;
                          if (code != null &&
                              code.isNotEmpty &&
                              code != _lastScanned &&
                              state is! CheckInLoading) {
                            _lastScanned = code;
                            _scanner.stop();
                            _board(context, code);
                          }
                        },
                      ),
                      // Scanning overlay
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _ResultPanel(state: state, scanner: _scanner),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _board(BuildContext context, String bookingId) {
    context.read<CheckInCubit>().check(
      tripId: widget.tripId,
      bookingId: bookingId,
      status: CheckInStatus.boarded,
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.state, required this.scanner});

  final CheckInState state;
  final MobileScannerController scanner;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        if (state is CheckInLoading) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          const Center(child: Text('جاري التحقق...')),
        ] else if (state is CheckInReady &&
            (state as CheckInReady).result != null) ...[
          _ScanResult(result: (state as CheckInReady).result!),
        ] else if (state is CheckInError) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  (state as CheckInError).message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ] else ...[
          const Center(
            child: Text(
              'وجّه الكاميرا نحو كود QR الخاص بالراكب',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScanResult extends StatelessWidget {
  const _ScanResult({required this.result});

  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.status == CheckInStatus.boarded;
    final color = isSuccess
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          if (result.passengerName != null)
            Text(
              result.passengerName!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (result.seatLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              'المقعد ${result.seatLabel}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          StatusChip(label: _statusLabel(result.status)),
          if (result.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              result.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(CheckInStatus s) => switch (s) {
    CheckInStatus.boarded => 'تم الصعود',
    CheckInStatus.absent => 'غائب',
    CheckInStatus.cancelled => 'ملغي',
    CheckInStatus.alreadyCheckedIn => 'تم التسجيل مسبقاً',
  };
}
