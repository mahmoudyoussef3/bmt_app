import 'package:flutter/material.dart';

class SupportCategoryCard extends StatelessWidget {
  const SupportCategoryCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  IconData _getIconForCategory(String cat) {
    if (cat.contains('Booking')) return Icons.book_online;
    if (cat.contains('Driver')) return Icons.person_pin;
    if (cat.contains('Vehicle')) return Icons.directions_bus;
    if (cat.contains('Route')) return Icons.map;
    if (cat.contains('Technical')) return Icons.computer;
    if (cat.contains('Refund')) return Icons.attach_money;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForCategory(title), color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
