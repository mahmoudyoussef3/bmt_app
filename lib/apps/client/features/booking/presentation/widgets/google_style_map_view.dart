import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

enum MapSelectionMode { pickup, destination }

/// Google Maps–style static map UI (no real map SDK or logic).
class GoogleStyleMapView extends StatelessWidget {
  const GoogleStyleMapView({
    super.key,
    required this.pickup,
    required this.destination,
    required this.selectionMode,
    required this.onMapTap,
    this.pickupOffset,
    this.destinationOffset,
  });

  final MapPinOption? pickup;
  final MapPinOption? destination;
  final MapSelectionMode selectionMode;
  final VoidCallback onMapTap;
  final Offset? pickupOffset;
  final Offset? destinationOffset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onMapTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          Offset pinPosition(MapPinOption? pin, Offset? override) {
            final o = override ?? Offset(pin?.x ?? 0.5, pin?.y ?? 0.5);
            return Offset(o.dx * size.width, o.dy * size.height);
          }

          final pickupPos = pickup != null
              ? pinPosition(pickup, pickupOffset)
              : null;
          final destPos = destination != null
              ? pinPosition(destination, destinationOffset)
              : null;

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A2332),
                      const Color(0xFF243447),
                      const Color(0xFF2D3E50),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _RoadMapPainter(
                    routeFrom: pickupPos,
                    routeTo: destPos,
                    accent: scheme.primary,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _MapChip(icon: Icons.layers_rounded, label: 'Map'),
              ),
              if (pickupPos != null)
                _MapMarker(
                  position: pickupPos,
                  color: scheme.secondary,
                  label: 'A',
                  isActive: selectionMode == MapSelectionMode.pickup,
                ),
              if (destPos != null)
                _MapMarker(
                  position: destPos,
                  color: scheme.error,
                  label: 'B',
                  isActive: selectionMode == MapSelectionMode.destination,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.position,
    required this.color,
    required this.label,
    required this.isActive,
  });

  final Offset position;
  final Color color;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 18,
      top: position.dy - 44,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: isActive ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(16, 10),
            painter: _PinTailPainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoadMapPainter extends CustomPainter {
  _RoadMapPainter({
    required this.routeFrom,
    required this.routeTo,
    required this.accent,
  });

  final Offset? routeFrom;
  final Offset? routeTo;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = const Color(0xFF2A3544);
    const block = 48.0;
    for (double x = 0; x < size.width; x += block) {
      for (double y = 0; y < size.height; y += block) {
        if ((x / block + y / block).toInt().isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, block, block), blockPaint);
        }
      }
    }

    final road = Paint()
      ..color = const Color(0xFF4A5568)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.4),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.55, size.height),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.35, size.height),
      road..strokeWidth = 8,
    );

    if (routeFrom != null && routeTo != null) {
      final routePaint = Paint()
        ..color = accent.withAlpha(200)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(routeFrom!.dx, routeFrom!.dy)
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.25,
          routeTo!.dx,
          routeTo!.dy,
        );
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadMapPainter oldDelegate) {
    return oldDelegate.routeFrom != routeFrom || oldDelegate.routeTo != routeTo;
  }
}
