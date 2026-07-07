import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/passenger.dart';
import '../cubit/passenger_manifest_cubit.dart';

class PassengerCard extends StatelessWidget {
  const PassengerCard({
    super.key,
    required this.passenger,
    required this.onCall,
    required this.onChat,
  });

  final Passenger passenger;
  final VoidCallback onCall;
  final VoidCallback onChat;

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _StatusSheet(
        passenger: passenger,
        onSelect: (status) {
          Navigator.pop(sheetCtx);
          context.read<PassengerManifestCubit>().updateStatus(
            tripPassengerId: passenger.id,
            status: status,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(passenger.status);

    return AppCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      initials: passenger.name.isNotEmpty
                          ? passenger.name[0]
                          : '?',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  passenger.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              _StatusBadge(status: passenger.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مقعد ${passenger.seat}  •  ${passenger.pickupPoint}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(170),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (passenger.destination.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(170),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  passenger.destination,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(170),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ],
                          if (passenger.pickupTime.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  passenger.pickupTime,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          tooltip: 'تغيير الحالة',
                          color: Colors.blue,
                          onPressed: () => _showStatusSheet(context),
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.call_rounded,
                          tooltip: 'اتصال',
                          color: Colors.green,
                          onPressed: onCall,
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          tooltip: 'مراسلة',
                          color: Colors.blue,
                          onPressed: onChat,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PassengerBoardingStatus s) => switch (s) {
    PassengerBoardingStatus.boarded => Colors.green,
    PassengerBoardingStatus.pending => Colors.blue,
    PassengerBoardingStatus.absent => Colors.red,
    PassengerBoardingStatus.late => Colors.orange,
    PassengerBoardingStatus.cancelled => Colors.grey,
  };
}

class _StatusSheet extends StatelessWidget {
  const _StatusSheet({required this.passenger, required this.onSelect});

  final Passenger passenger;
  final void Function(PassengerBoardingStatus) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: CaptainDesignTokens.r32),
      ),
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: CaptainColors.dividerFor(context),
                borderRadius: CaptainDesignTokens.br8,
              ),
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Text(
            passenger.name,
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'مقعد ${passenger.seat}',
            style: CaptainTypography.labelMedium(
              context,
            ).copyWith(color: CaptainColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Text(
            'تحديث الحالة',
            style: CaptainTypography.labelSmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          ..._statusOptions().map(
            (opt) => _StatusOption(
              label: opt.$1,
              icon: opt.$2,
              color: opt.$3,
              status: opt.$4,
              isActive: passenger.status == opt.$4,
              onTap: () => onSelect(opt.$4),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, IconData, Color, PassengerBoardingStatus)> _statusOptions() => [
    (
      'صعد',
      Icons.check_circle_rounded,
      CaptainColors.success,
      PassengerBoardingStatus.boarded,
    ),
    (
      'بانتظار',
      Icons.hourglass_top_rounded,
      CaptainColors.primary,
      PassengerBoardingStatus.pending,
    ),
    (
      'متأخر',
      Icons.timer_rounded,
      CaptainColors.warning,
      PassengerBoardingStatus.late,
    ),
    (
      'غائب',
      Icons.person_off_rounded,
      CaptainColors.error,
      PassengerBoardingStatus.absent,
    ),
    (
      'ملغي',
      Icons.cancel_rounded,
      CaptainColors.offline,
      PassengerBoardingStatus.cancelled,
    ),
  ];
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.status,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final PassengerBoardingStatus status;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CaptainDesignTokens.s12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : onTap,
          borderRadius: CaptainDesignTokens.br16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s16,
              vertical: CaptainDesignTokens.s16,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withAlpha(20)
                  : CaptainColors.surfaceFor(context),
              borderRadius: CaptainDesignTokens.br16,
              border: Border.all(
                color: isActive ? color : CaptainColors.dividerFor(context),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? color
                      : CaptainColors.textSecondaryFor(context),
                  size: 24,
                ),
                const SizedBox(width: CaptainDesignTokens.s12),
                Text(
                  label,
                  style: CaptainTypography.labelLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? color
                        : CaptainColors.textPrimaryFor(context),
                  ),
                ),
                const Spacer(),
                if (isActive) Icon(Icons.check_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PassengerBoardingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PassengerBoardingStatus.boarded => ('صعد', CaptainColors.success),
      PassengerBoardingStatus.pending => ('بانتظار', CaptainColors.primary),
      PassengerBoardingStatus.absent => ('غائب', CaptainColors.error),
      PassengerBoardingStatus.late => ('متأخر', CaptainColors.warning),
      PassengerBoardingStatus.cancelled => ('ملغي', CaptainColors.offline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: CaptainDesignTokens.br8,
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: CaptainDesignTokens.br12,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: CaptainDesignTokens.br12,
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
