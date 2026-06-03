import 'package:flutter/material.dart';

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
        label: 'Vehicle',
        gradientIndex: 0,
      );
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: labels.length,
        itemBuilder: (context, index) {
          return _ImagePlaceholder(
            height: height,
            label: labels[index],
            gradientIndex: index,
          );
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
  const _ImagePlaceholder({
    required this.height,
    required this.label,
    required this.gradientIndex,
  });

  final double height;
  final String label;
  final int gradientIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palettes = [
      [scheme.primary.withAlpha(90), scheme.secondary.withAlpha(50)],
      [scheme.secondary.withAlpha(80), scheme.tertiary.withAlpha(45)],
      [scheme.tertiary.withAlpha(70), scheme.primary.withAlpha(55)],
      [const Color(0xFF334155), scheme.primary.withAlpha(60)],
    ];
    final colors = palettes[gradientIndex % palettes.length];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 12,
                    color: Colors.white.withAlpha(220),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
