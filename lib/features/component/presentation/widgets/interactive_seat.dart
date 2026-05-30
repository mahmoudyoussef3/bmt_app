import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/seat_widget.dart';

/// An interactive seat wrapper that listens to a [ValueNotifier] so only
/// the seat widgets that need to update will rebuild when selection changes.
class InteractiveSeat extends StatefulWidget {
  final String id;
  final SeatStatus initialStatus;
  final ValueNotifier<String?> selectedNotifier;

  const InteractiveSeat({
    super.key,
    required this.id,
    required this.initialStatus,
    required this.selectedNotifier,
  });

  @override
  State<InteractiveSeat> createState() => _InteractiveSeatState();
}

class _InteractiveSeatState extends State<InteractiveSeat> {
  late SeatStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    widget.selectedNotifier.addListener(_onSelectedChanged);
  }

  void _onSelectedChanged() {
    final selected = widget.selectedNotifier.value;
    final newStatus = _status == SeatStatus.reserved
        ? SeatStatus.reserved
        : (selected == widget.id ? SeatStatus.selected : SeatStatus.available);
    if (newStatus != _status) {
      setState(() => _status = newStatus);
    }
  }

  @override
  void dispose() {
    widget.selectedNotifier.removeListener(_onSelectedChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReserved = widget.initialStatus == SeatStatus.reserved;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: _status == SeatStatus.selected ? 1.04 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutQuad,
        child: GestureDetector(
          onTap: isReserved
              ? null
              : () {
                  final currently = widget.selectedNotifier.value;
                  widget.selectedNotifier.value = currently == widget.id
                      ? null
                      : widget.id;
                },
          child: SeatWidget(
            id: widget.id,
            status: _status,
            onTap: isReserved
                ? null
                : () {
                    final currently = widget.selectedNotifier.value;
                    widget.selectedNotifier.value = currently == widget.id
                        ? null
                        : widget.id;
                  },
          ),
        ),
      ),
    );
  }
}
