import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/l10n/app_localizations.dart';

import '../routes/auth_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openTerms() {}

  void _openPrivacy() {}

  void _goToSignIn() {
    Navigator.pushNamed(context, AuthRoutes.signIn);
  }

  void _goToSignUp() {
    Navigator.pushNamed(context, AuthRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    final isCompactHeight = size.height < 720;
    final isWide = size.width >= 760;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            Positioned.fill(child: _WelcomeBackground(scheme: scheme)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 22,
                      vertical: isCompactHeight ? 16 : 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _HeroContent(
                                      scheme: scheme,
                                      compact: isCompactHeight,
                                    ),
                                  ),
                                  const SizedBox(width: 36),
                                  SizedBox(
                                    width: 390,
                                    child: _ActionPanel(
                                      l10n: l10n,
                                      scheme: scheme,
                                      onLogin: _goToSignIn,
                                      onCreateAccount: _goToSignUp,
                                      termsRecognizer: _termsRecognizer,
                                      privacyRecognizer: _privacyRecognizer,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: _HeroContent(
                                      scheme: scheme,
                                      compact: isCompactHeight,
                                    ),
                                  ),
                                  _ActionPanel(
                                    l10n: l10n,
                                    scheme: scheme,
                                    onLogin: _goToSignIn,
                                    onCreateAccount: _goToSignUp,
                                    termsRecognizer: _termsRecognizer,
                                    privacyRecognizer: _privacyRecognizer,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.scheme, required this.compact});

  final ColorScheme scheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(top: compact ? 4 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandHeader(scheme: scheme),
            SizedBox(height: compact ? 22 : 34),
            Text(
              'Your daily trip\nin one click',
              textAlign: TextAlign.start,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -0.7,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Book your trip, track buses in real-time, and manage your subscriptions easily from one place.',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.75,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? 22 : 30),
            _RouteVisualCard(scheme: scheme),
            SizedBox(height: compact ? 20 : 26),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FeaturePill(
                  scheme: scheme,
                  icon: Icons.route_rounded,
                  label: 'Smart Routes',
                ),
                _FeaturePill(
                  scheme: scheme,
                  icon: Icons.location_on_outlined,
                  label: 'Live Tracking',
                ),
                _FeaturePill(
                  scheme: scheme,
                  icon: Icons.card_membership_rounded,
                  label: 'Monthly Subscriptions',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withAlpha(45)),
          ),
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.directions_bus_rounded,
              color: scheme.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'EasyWay',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: scheme.primary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _RouteVisualCard extends StatelessWidget {
  const _RouteVisualCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary.withAlpha(36),
            scheme.secondary.withAlpha(20),
            scheme.surface.withAlpha(245),
          ],
        ),
        border: Border.all(color: scheme.outline.withAlpha(45)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(20),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RouteLinePainter(color: scheme.primary.withAlpha(135)),
            ),
          ),
          Positioned(
            top: 10,
            right: 8,
            child: _MiniStatusCard(
              scheme: scheme,
              icon: Icons.schedule_rounded,
              title: '08:40 AM',
              subtitle: 'Next Trip',
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: _MiniStatusCard(
              scheme: scheme,
              icon: Icons.verified_rounded,
              title: 'Seat Confirmed',
              subtitle: 'No. A12',
            ),
          ),
          Positioned(
            bottom: 16,
            right: 10,
            child: _RouteNamePill(scheme: scheme),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withAlpha(70),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus_filled_rounded,
                size: 42,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteNamePill extends StatelessWidget {
  const _RouteNamePill({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.near_me_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Cairo → Sheikh Zayed',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusCard extends StatelessWidget {
  const _MiniStatusCard({
    required this.scheme,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ColorScheme scheme;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(236),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.l10n,
    required this.scheme,
    required this.onLogin,
    required this.onCreateAccount,
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  final AppLocalizations? l10n;
  final ColorScheme scheme;
  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;

  @override
  Widget build(BuildContext context) {
    final loginText = l10n?.auth_login ?? 'Login';
    final createText = l10n?.auth_createAccount ?? 'Create new account';
    final termsPrefix = l10n?.auth_termsPrefix ?? 'By continuing you agree to ';
    final termsText = l10n?.auth_termsOfService ?? 'Terms of Service';
    final termsAnd = l10n?.auth_termsAnd ?? ' and ';
    final privacyText = l10n?.auth_privacyPolicy ?? 'Privacy Policy';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(248),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: scheme.outline.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Start your journey now',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log in or create a new account to benefit from all mobility services.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              loginText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCreateAccount,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              side: BorderSide(color: scheme.outline.withAlpha(90)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              createText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 18),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: termsPrefix),
                TextSpan(
                  text: termsText,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: termsRecognizer,
                ),
                TextSpan(text: termsAnd),
                TextSpan(
                  text: privacyText,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: privacyRecognizer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.scheme,
    required this.icon,
    required this.label,
  });

  final ColorScheme scheme;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withAlpha(38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.15,
          colors: [scheme.primary.withAlpha(30), scheme.surface],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -60,
            child: _SoftCircle(size: 210, color: scheme.primary),
          ),
          Positioned(
            bottom: 120,
            right: -90,
            child: _SoftCircle(size: 240, color: scheme.secondary),
          ),
          Positioned(
            top: 90,
            right: -80,
            child: Icon(
              Icons.map_outlined,
              size: 250,
              color: scheme.primary.withAlpha(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(18),
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withAlpha(35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.86, size.height * 0.78)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.34,
        size.width * 0.36,
        size.height * 0.84,
        size.width * 0.14,
        size.height * 0.22,
      );

    canvas.drawPath(path, linePaint);

    final points = [
      Offset(size.width * 0.86, size.height * 0.78),
      Offset(size.width * 0.50, size.height * 0.54),
      Offset(size.width * 0.14, size.height * 0.22),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 13, glowPaint);
      canvas.drawCircle(point, 7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
