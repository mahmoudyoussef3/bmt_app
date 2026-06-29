import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../../../core/theme/dashboard_theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        const DashboardModuleHeader(
          icon: Icons.settings_outlined,
          title: 'الإعدادات',
          subtitle: 'إعدادات عامة للوحة التشغيل وتجربة المستخدم.',
        ),
        const SizedBox(height: AppSpacing.large),
        AppCard(
          child: BlocBuilder<DashboardThemeCubit, DashboardThemeState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مظهر اللوحة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('فاتح'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                    ],
                    selected: {
                      state.themeMode == ThemeMode.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                    },
                    onSelectionChanged: (selection) {
                      context.read<DashboardThemeCubit>().setThemeMode(
                        selection.first,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          child: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صلاحيات التشغيل',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          'إعدادات الصلاحيات وتبديل التطبيقات الداخلية لا تظهر في واجهة الإنتاج. يتم التحكم بها من إعدادات النشر والإدارة.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          child: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return ListTile(
                leading: Icon(Icons.logout_rounded, color: scheme.error),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('إنهاء الجلسة الحالية'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل تريد إنهاء جلستك الحالية؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('خروج'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await dashboardDi<DashboardAuthCubit>().signOut();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
