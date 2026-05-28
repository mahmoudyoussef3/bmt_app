import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  final void Function(String route) onOpenRoute;

  const ProfileScreen({super.key, required this.onOpenRoute});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const AppAvatar(initials: 'AH', radius: 24),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahmed Hassan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Employee commute account',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Access', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        AppButton(
          label: 'Driver Dashboard',
          outline: true,
          onPressed: () => onOpenRoute('/driver'),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Admin Dashboard',
          outline: true,
          onPressed: () => onOpenRoute('/admin'),
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
