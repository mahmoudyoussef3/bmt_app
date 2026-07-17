import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../routes/auth_routes.dart';
import '../widgets/auth_brand_logo.dart';

/// Shown right after account creation. Adapts to the two Supabase outcomes:
/// a live session (auto sign-in) → celebratory "You're all set"; or no session
/// (email confirmation required) → "Verify your email".
class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({super.key, this.email});

  /// Email used for the "verify your email" message when there is no session.
  final String? email;

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasSession => Supabase.instance.client.auth.currentSession != null;

  void _continue() {
    if (_hasSession) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(ClientRoutes.home, (_) => false);
    } else {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.signIn, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final created = _hasSession;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.1,
            colors: [ClientColors.primary.withAlpha(28), scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthBrandLogo(),
                const Spacer(),
                ScaleTransition(
                  scale: _scale,
                  child: _SuccessBadge(created: created),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      Text(
                        created
                            ? l10n.authSuccess_createdTitle
                            : l10n.authSuccess_verifyTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        created
                            ? l10n.authSuccess_createdSubtitle
                            : l10n.authSuccess_verifySubtitle(
                                widget.email ?? '',
                              ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (created) ...[
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        _PerkRow(
                          icon: Icons.event_seat_rounded,
                          label: l10n.authSuccess_perkBooking,
                        ),
                        _PerkRow(
                          icon: Icons.location_on_rounded,
                          label: l10n.authSuccess_perkTracking,
                        ),
                        _PerkRow(
                          icon: Icons.card_membership_rounded,
                          label: l10n.authSuccess_perkPasses,
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                PressableScale(
                  onTap: _continue,
                  child: FilledButton(
                    onPressed: _continue,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      created
                          ? l10n.authSuccess_getStarted
                          : l10n.authSuccess_backToSignIn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.created});

  final bool created;

  @override
  Widget build(BuildContext context) {
    final color = created ? ClientColors.journeyCyan : ClientColors.primary;
    return Container(
      height: 116,
      width: 116,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 78,
          width: 78,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            created ? Icons.check_rounded : Icons.mark_email_read_outlined,
            size: 42,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: ClientColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
