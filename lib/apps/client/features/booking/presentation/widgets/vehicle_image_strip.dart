import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Placeholder vehicle image gallery (no network assets).
class VehicleImageStrip extends StatelessWidget {
  const VehicleImageStrip({
    super.key,
    required this.labels,
    this.height = 160,
    this.onPageChanged,
    this.pageController,
  });

  final List<String> labels;
  final double height;
  final ValueChanged<int>? onPageChanged;
  final PageController? pageController;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return _ImagePlaceholder(
        height: height,
        label: context.l10n.tracking_vehicle,
      );
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: labels.length,
        itemBuilder: (context, index) {
          return _ImagePlaceholder(height: height, label: labels[index]);
        },
      ),
    );
  }
}

class VehicleImageDots extends StatelessWidget {
  const VehicleImageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.outline.withAlpha(120),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.height, required this.label});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Every page used to draw its own two-hue ramp, keyed off its index, so a
    // gallery of stand-ins looked like four different vehicles. One brand tint
    // for all of them: which page you are on is the dots' job, not the fill's.
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.primary.withAlpha(60),
        border: Border.all(color: scheme.outline.withAlpha(100)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: CustomPaint(
                painter: _GridPainter(color: scheme.onSurface),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus_filled_rounded,
                  size: height * 0.28,
                  color: scheme.onSurface.withAlpha(200),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(30)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
