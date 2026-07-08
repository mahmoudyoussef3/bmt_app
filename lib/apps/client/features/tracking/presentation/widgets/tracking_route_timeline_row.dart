import 'package:flutter/material.dart';

/// One pickup/destination row in [TrackingRouteInfoCard]: an icon, a role
/// label, the place name, and a scheduled/expected time caption.
class TrackingRouteTimelineRow extends StatelessWidget {
  const TrackingRouteTimelineRow({
    super.key,
    required this.icon,
    required this.color,
    required this.type,
    required this.location,
    required this.timeInfo,
  });

  final IconData icon;
  final Color color;
  final String type;
  final String location;
  final String timeInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                timeInfo,
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
