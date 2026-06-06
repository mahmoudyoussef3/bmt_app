import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';

/// Promotional banner for home booking screen.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                scheme.tertiary.withAlpha(200),
                scheme.primary.withAlpha(180),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'LIMITED OFFER',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '20% off your first\nmonthly package',
                      style: AppTextThemes.headlineStrong(
                        scheme,
                      ).copyWith(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use code COMMUTE20 at checkout',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
