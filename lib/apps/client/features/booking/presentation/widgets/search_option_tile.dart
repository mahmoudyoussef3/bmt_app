import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// A secondary "other ways to search" entry point row on [SearchTripScreen]
/// (e.g. Popular Routes, Select on Map).
class SearchOptionTile extends StatelessWidget {
  const SearchOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(4),
      useShadow: true,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const DirectionalIcon(Icons.chevron_right_rounded),
      ),
    );
  }
}
