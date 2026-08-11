import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../domain/usecases/search_places_usecase.dart';

/// Place field for one point of a route: type to search, pick from the list.
///
/// Unlike a bare [Autocomplete], this one is *controlled* — [value] is the
/// truth, so a point placed by tapping the map, reordered, or loaded from a
/// saved route immediately shows the right text without the field losing focus
/// or fighting the operator mid-word. When no geocoding key is configured it
/// degrades to a plain text field instead of disappearing.
class RoutePlaceField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String value;

  /// Biases search results toward the point already chosen for this stop.
  final GeoPoint? focusPoint;

  /// `null` disables autocomplete and renders a plain text field.
  final SearchPlacesUseCase? searchPlaces;
  final ValueChanged<String> onChanged;
  final ValueChanged<GeoPlace> onPlaceSelected;
  final bool autofocus;

  const RoutePlaceField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onPlaceSelected,
    this.hint = 'اكتب اسم المكان ثم اختر من القائمة',
    this.icon = Icons.place_outlined,
    this.focusPoint,
    this.searchPlaces,
    this.autofocus = false,
  });

  @override
  State<RoutePlaceField> createState() => _RoutePlaceFieldState();
}

class _RoutePlaceFieldState extends State<RoutePlaceField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _latestQuery = '';

  /// The last text pushed in from outside (a place picked on the map, a
  /// reorder, a saved route loading). Writing it into the controller makes
  /// [RawAutocomplete] think the operator typed it and fires a lookup for text
  /// nobody asked about — remembering it lets that one lookup be skipped.
  String _appliedExternally = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(RoutePlaceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.value != _controller.text) {
      _appliedExternally = widget.value;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<GeoPlace>> _search(TextEditingValue value) async {
    final search = widget.searchPlaces;
    if (search == null) return const <GeoPlace>[];
    if (value.text == _appliedExternally) return const <GeoPlace>[];
    _latestQuery = value.text;
    final query = value.text.trim();
    if (query.length < 3) return const <GeoPlace>[];

    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (_latestQuery != value.text) return const <GeoPlace>[];
    try {
      return await search(query, focus: widget.focusPoint);
    } catch (_) {
      return const <GeoPlace>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchPlaces == null) {
      return _field(context, _controller, _focusNode);
    }
    return RawAutocomplete<GeoPlace>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (place) => place.label,
      optionsBuilder: _search,
      onSelected: widget.onPlaceSelected,
      fieldViewBuilder: (context, controller, focusNode, _) =>
          _field(context, controller, focusNode),
      optionsViewBuilder: (context, onSelected, options) =>
          _Suggestions(options: options, onSelected: onSelected),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon),
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final Iterable<GeoPlace> options;
  final ValueChanged<GeoPlace> onSelected;

  const _Suggestions({required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280, maxWidth: 460),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final place = options.elementAt(index);
              final parts = place.label.split(',');
              return ListTile(
                dense: true,
                leading: Icon(Icons.place_outlined, color: scheme.primary),
                title: Text(
                  parts.first.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: parts.length > 1
                    ? Text(
                        parts.skip(1).join(',').trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () => onSelected(place),
              );
            },
          ),
        ),
      ),
    );
  }
}
