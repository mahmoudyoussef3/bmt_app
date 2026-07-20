import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Photos of the bus the rider is about to board, swiped one at a time.
///
/// Unlike the placeholder strip used elsewhere in booking, these are the real
/// images the operator uploaded against the fleet record. A bus with no photos
/// on file still gets a frame — an empty gap would read as a broken screen,
/// where a labelled placeholder reads as "not photographed yet".
class TripVehicleGallery extends StatefulWidget {
  const TripVehicleGallery({
    super.key,
    required this.imageUrls,
    this.height = 210,
  });

  final List<String> imageUrls;
  final double height;

  @override
  State<TripVehicleGallery> createState() => _TripVehicleGalleryState();
}

class _TripVehicleGalleryState extends State<TripVehicleGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _GalleryFrame(
        height: widget.height,
        child: _NoPhotos(height: widget.height),
      );
    }

    return Column(
      children: [
        _GalleryFrame(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) =>
                    _GalleryImage(url: widget.imageUrls[index]),
              ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _CountBadge(
                    label: '${_index + 1}/${widget.imageUrls.length}',
                  ),
                ),
            ],
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          _Dots(count: widget.imageUrls.length, index: _index),
        ],
      ],
    );
  }
}

class _GalleryFrame extends StatelessWidget {
  const _GalleryFrame({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClientRadius.md),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: ClientColors.surfaceMutedFor(context),
          child: child,
        ),
      ),
    );
  }
}

/// One photo, with its own loading and failure states so a single dead URL
/// never blanks the whole gallery.
class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: ClientColors.primaryFor(context),
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) => Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 34,
          color: ClientColors.textTertiaryFor(context),
        ),
      ),
    );
  }
}

class _NoPhotos extends StatelessWidget {
  const _NoPhotos({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_bus_filled_rounded,
            size: height * 0.24,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              context.l10n.booking_vehiclePhotosUnavailable,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: ClientMotion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? ClientColors.primaryFor(context)
                : ClientColors.borderStrongFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.pill),
          ),
        );
      }),
    );
  }
}
