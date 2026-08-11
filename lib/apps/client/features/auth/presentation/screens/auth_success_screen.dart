import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../routes/auth_routes.dart';
import '../widgets/auth_brand_logo.dart';
import '../widgets/auth_success_badge.dart';
import '../widgets/auth_success_content.dart';
import '../widgets/auth_success_cta.dart';

class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({super.key, this.email});

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
    final route = _hasSession ? ClientRoutes.home : AuthRoutes.signIn;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
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
                  child: AuthSuccessBadge(created: created),
                ),
                const SizedBox(height: 28),
                AuthSuccessContent(
                  created: created,
                  email: widget.email,
                  fade: _fade,
                ),
                const Spacer(),
                AuthSuccessCta(created: created, onContinue: _continue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
