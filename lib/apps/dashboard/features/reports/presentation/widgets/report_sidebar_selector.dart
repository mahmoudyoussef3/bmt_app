import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../../domain/entities/report_entities.dart';

class ReportSidebarSelector extends StatelessWidget {
  final ReportType selectedType;
  final ValueChanged<ReportType> onSelect;

  const ReportSidebarSelector({
    super.key,
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final icons = {
      ReportType.trips: Icons.directions_bus_outlined,
      ReportType.bookings: Icons.book_online_outlined,
      ReportType.revenue: Icons.monetization_on_outlined,
      ReportType.drivers: Icons.badge_outlined,
      ReportType.vehicles: Icons.local_shipping_outlined,
      ReportType.subscriptions: Icons.workspace_premium_outlined,
      ReportType.complaints: Icons.support_agent_outlined,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('فئات التقارير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: ListView.separated(
              itemCount: ReportType.values.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xSmall),
              itemBuilder: (context, index) {
                final type = ReportType.values[index];
                final isSelected = type == selectedType;
                return Material(
                  color: isSelected ? scheme.primaryContainer.withValues(alpha: 0.47) : Colors.transparent, // ~120/255
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    selected: isSelected,
                    onTap: () => onSelect(type),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: Icon(icons[type] ?? Icons.insert_chart_outlined, size: 20),
                    title: Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
