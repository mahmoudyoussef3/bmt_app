import 'package:flutter/material.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/search_places_usecase.dart';

/// Debounced place-autocomplete field backed by [SearchPlacesUseCase] (ORS).
///
/// Used for a route's start, destination, and each stop. On selection it
/// reports the chosen [GeoPlace] (label + coordinates) via [onSelected]. Only
/// rendered when geocoding is enabled; the form falls back to plain text fields
/// otherwise.
class PlaceSearchField extends StatefulWidget {
  final String label;
  final String initialText;
  final SearchPlacesUseCase searchPlaces;
  final GeoPoint? focus;
  final ValueChanged<GeoPlace> onSelected;
  final String? Function(String?)? validator;

  const PlaceSearchField({
    super.key,
    required this.label,
    required this.searchPlaces,
    required this.onSelected,
    this.initialText = '',
    this.focus,
    this.validator,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  String _latest = '';

  Future<Iterable<GeoPlace>> _optionsBuilder(TextEditingValue value) async {
    _latest = value.text;
    final query = value.text.trim();
    if (query.length < 3) return const <GeoPlace>[];

    // Debounce: wait briefly, then bail if a newer keystroke superseded us.
    await Future.delayed(const Duration(milliseconds: 350));
    if (_latest != value.text) return const <GeoPlace>[];

    try {
      return await widget.searchPlaces(query, focus: widget.focus);
    } catch (_) {
      return const <GeoPlace>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<GeoPlace>(
      initialValue: TextEditingValue(text: widget.initialText),
      displayStringForOption: (place) => place.label,
      optionsBuilder: _optionsBuilder,
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.place_outlined),
            border: const OutlineInputBorder(),
            hintText: 'اكتب اسم المكان ثم اختر من القائمة',
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final scheme = Theme.of(context).colorScheme;
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final place = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on_outlined,
                        color: scheme.primary),
                    title: Text(place.label),
                    onTap: () => onSelected(place),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
