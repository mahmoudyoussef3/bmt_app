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
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(passenger.status);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status indicator strip
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppAvatar(initials: passenger.name.isNotEmpty ? passenger.name[0] : '?'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    passenger.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                _StatusBadge(status: passenger.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'مقعد ${passenger.seat}  •  ${passenger.pickupPoint}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                            if (passenger.destination.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 12, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    passenger.destination,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                            if (passenger.pickupTime.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 12, color: scheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    passenger.pickupTime,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          _ActionButton(
                            icon: Icons.edit_rounded,
                            tooltip: 'تغيير الحالة',
                            color: scheme.primary,
                            onPressed: () => _showStatusSheet(context),
                          ),
                          const SizedBox(height: 6),
                          _ActionButton(
                            icon: Icons.call_rounded,
                            tooltip: 'اتصال',
                            color: Colors.green,
                            onPressed: onCall,
                          ),
                          const SizedBox(height: 6),
                          _ActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            tooltip: 'مراسلة',
                            color: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            passenger.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'مقعد ${passenger.seat}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'تحديث الحالة',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
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
        ('صعد', Icons.check_circle_rounded, Colors.green, PassengerBoardingStatus.boarded),
        ('بانتظار', Icons.hourglass_top_rounded, Colors.blue, PassengerBoardingStatus.pending),
        ('متأخر', Icons.timer_rounded, Colors.orange, PassengerBoardingStatus.late),
        ('غائب', Icons.person_off_rounded, Colors.red, PassengerBoardingStatus.absent),
        ('ملغي', Icons.cancel_rounded, Colors.grey, PassengerBoardingStatus.cancelled),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? color.withAlpha(20) : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? color : Colors.transparent,
                width: isActive ? 1.5 : 0,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isActive ? color : scheme.onSurfaceVariant, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive ? color : scheme.onSurface,
                      ),
                ),
                const Spacer(),
                if (isActive)
                  Icon(Icons.check_rounded, color: color, size: 20),
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
      PassengerBoardingStatus.boarded => ('صعد', Colors.green),
      PassengerBoardingStatus.pending => ('بانتظار', Colors.blue),
      PassengerBoardingStatus.absent => ('غائب', Colors.red),
      PassengerBoardingStatus.late => ('متأخر', Colors.orange),
      PassengerBoardingStatus.cancelled => ('ملغي', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
