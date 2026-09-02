import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/captain_request.dart';
import 'captain_request_status_badge.dart';
import 'captain_requests_format.dart';

/// One joining request, as the queue renders it below
/// [kDashboardTableBreakpoint].
///
/// Carries the same five readings as the table row it replaces — who, their
/// phone, their note, when they applied and where the request stands — so an
/// operator who narrows the window is not handed a thinner story than the one
/// they were reading a pixel earlier.
class CaptainRequestCard extends StatelessWidget {
  final CaptainRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const CaptainRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = request.fullName.isNotEmpty
        ? request.fullName.characters.first
        : '؟';
    final note = request.note?.trim() ?? '';
    final reason = request.rejectionReason?.trim() ?? '';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withAlpha(28),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // A first-strong isolate, not a forced direction: the
                    // dashboard's RTL guard bans that constant in feature code
                    // (and scans for the literal, so it cannot even be named
                    // here). An isolate reads the digits left-to-right anyway.
                    Text(
                      isolatedPlaceName(request.phone),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              CaptainRequestStatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _MetaRow(
            icon: Icons.event_outlined,
            label: 'قُدّم ${CaptainRequestsFormat.date(request.createdAt)}',
            detail: CaptainRequestsFormat.age(
              request.createdAt,
              DateTime.now(),
            ),
          ),
          if (request.reviewedAt != null) ...[
            const SizedBox(height: AppSpacing.xSmall),
            _MetaRow(
              icon: Icons.gavel_rounded,
              label: 'تقرّر ${CaptainRequestsFormat.date(request.reviewedAt!)}',
              detail: CaptainRequestsFormat.age(
                request.reviewedAt!,
                DateTime.now(),
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            _NotePanel(
              label: 'ملاحظة السائق',
              body: note,
              tone: AppStatusTone.neutral,
            ),
          ],
          if (request.status == CaptainRequestStatus.rejected &&
              reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            _NotePanel(
              label: 'سبب الرفض',
              body: reason,
              tone: AppStatusTone.error,
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('قبول واستكمال البيانات'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;

  /// The "ago" reading, dropped when there is no useful one — see
  /// [CaptainRequestsFormat.age].
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final age = detail;
    return Row(
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
        if (age != null) ...[
          const SizedBox(width: 6),
          Text(
            '· $age',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}

/// A short block of text the office needs to read before deciding — the
/// applicant's own note, or the reason a previous decision recorded.
class _NotePanel extends StatelessWidget {
  const _NotePanel({
    required this.label,
    required this.body,
    required this.tone,
  });

  final String label;
  final String body;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = context.status(tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.ink.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: style.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
