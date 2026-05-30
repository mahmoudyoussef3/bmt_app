import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  final void Function(String route) onOpenRoute;

  const ProfileScreen({super.key, required this.onOpenRoute});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppAvatar(initials: 'AH', radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ahmed Hassan',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Employee commute account',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurface.withAlpha(170),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const AppBadge(text: 'Premium access'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Access', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Driver Dashboard',
                outline: true,
                onPressed: () => onOpenRoute('/driver'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Admin Dashboard',
                outline: true,
                onPressed: () => onOpenRoute('/admin'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: const [
              _InfoRow(title: 'Employee ID', value: 'EMP-2047'),
              AppSeparator(),
              _InfoRow(title: 'Department', value: 'Operations'),
              AppSeparator(),
              _InfoRow(title: 'Route', value: 'Banha → Smart Village'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
