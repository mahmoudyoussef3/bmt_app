import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_spacing.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';

/// Landing home for a freshly-approved captain (local session). They have no
/// assignments yet, so this greets them and sets expectations until operations
/// assign their first trip.
class CaptainWelcomeHomeScreen extends StatelessWidget {
  final CaptainLocalSession session;
  final Future<void> Function() onSignOut;

  const CaptainWelcomeHomeScreen({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first =
        session.name.trim().isEmpty ? '' : session.name.trim().split(' ').first;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: CaptainColors.backgroundFor(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('حسابي'),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(CaptainSpacing.lg),
            children: [
              CaptainCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primary.withAlpha(28),
                      child: Text(
                        first.isEmpty ? '؟' : first.characters.first,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: CaptainSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أهلاً${first.isEmpty ? '' : '، $first'} 👋',
                            style: CaptainTypography.titleLarge(context)
                                .copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              session.phone,
                              style: CaptainTypography.bodyMedium(context)
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          if (session.employeeCode.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'كود الكابتن: ${session.employeeCode}',
                              style: CaptainTypography.labelSmall(context)
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CaptainSpacing.xl),
              const CaptainEmptyState(
                icon: Icons.route_rounded,
                title: 'لا توجد رحلات بعد',
                subtitle:
                    'تم تفعيل حسابك بنجاح. سيقوم فريق العمليات بإسناد رحلاتك '
                    'قريباً وستظهر هنا فور توفرها.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
