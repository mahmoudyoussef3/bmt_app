import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/captain_di.dart';
import 'captain_identity_provider.dart';
import 'captain_office_session.dart';

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
