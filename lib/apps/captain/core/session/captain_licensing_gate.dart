import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/captain_di.dart';
import 'captain_identity_provider.dart';
import 'captain_office_session.dart';

/// Stands between the auth gate and the operational shell, for one case:
/// the office's platform licence no longer covers the captain app.
///
/// ── The mid-trip rule ────────────────────────────────────────────────────────
///
/// A captain who is **already driving is never cut off**, whatever the office
/// owes. The exemption is computed server-side in `captain_session_context`
/// (a trip in `boarding` or `in_progress` clears the block outright), so the
/// app cannot get it wrong and an out-of-date build cannot bypass it either.
///
/// ── Why a message and not a null session ─────────────────────────────────────
///
/// Returning no identity would land the captain on the "you are not registered
/// as a driver" path — an explanation that is both wrong and unactionable. A
/// licensing block is a fact about the office, so it says so, names who to ask,
/// and offers the sign-out the captain would otherwise hunt for.
class CaptainLicensingGate extends StatefulWidget {
  const CaptainLicensingGate({super.key, required this.child});

  final Widget child;

  @override
  State<CaptainLicensingGate> createState() => _CaptainLicensingGateState();
}

class _CaptainLicensingGateState extends State<CaptainLicensingGate> {
  final _identity = captainGetIt<CaptainIdentityProvider>();
  late Future<CaptainIdentity?> _future = _identity.ensure();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CaptainIdentity?>(
      future: _future,
      builder: (context, snapshot) {
        // Still resolving, or no identity at all: hand straight over. The shell
        // already handles both — a spinner for the first, its own explanation
        // for the second — and duplicating either here would fork that logic.
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.child;
        }

        final licensing = snapshot.data?.licensing;
        if (licensing == null || !licensing.blocked) return widget.child;

        return _LicensingBlockedScreen(
          message:
              licensing.messageAr ??
              'خدمة تطبيق الكابتن متوقفة حاليًا لهذا المكتب.',
          onRetry: () => setState(() => _future = _identity.refresh()),
        );
      },
    );
  }
}

class _LicensingBlockedScreen extends StatelessWidget {
  const _LicensingBlockedScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: scheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'الخدمة متوقفة مؤقتًا',
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    // The reassurance that matters most to the person holding
                    // the phone: this is not about them, and a trip they have
                    // already started is never interrupted by it.
                    'هذا إجراء يخص اشتراك المكتب في المنصة ولا علاقة له بحسابك. '
                    'الرحلات التي بدأت بالفعل تكمل كالمعتاد.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
