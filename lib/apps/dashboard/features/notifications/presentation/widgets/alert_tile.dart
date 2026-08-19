import 'package:flutter/material.dart';

import '../../domain/entities/operational_alert.dart';
import 'alert_icon_resolver.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/theme/colors.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onMarkRead,
  });

  final OperationalAlert alert;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (tone, icon) = AlertIconResolver.resolve(alert.type);
    final status = AppStatusStyle.of(context, tone);
    final iconColor = status.ink;
    final iconBg = status.tint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: alert.isRead ? cs.surface : cs.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(
                color: alert.isRead
                    ? cs.outlineVariant.withAlpha(60)
                    : cs.primary.withAlpha(50),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    if (!alert.isRead)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.body,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${alert.type.label} · ${_relative(alert.createdAt)}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!alert.isRead) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'تعليم كمقروء',
                    onPressed: onMarkRead,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surface,
                      side: BorderSide(color: cs.outlineVariant.withAlpha(50)),
                    ),
                    icon: Icon(Icons.check_rounded, size: 20, color: cs.primary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
  }
}
