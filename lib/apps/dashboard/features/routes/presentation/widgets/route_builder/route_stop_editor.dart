import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_dialog_header.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../domain/entities/route_draft.dart';
import '../../../domain/services/route_identity.dart';
import '../../../domain/services/route_stop_library.dart';
import '../../../domain/usecases/search_places_usecase.dart';
import 'route_location_picker.dart';

/// Where a stop sits in the journey. Only the wording changes — the rules are
/// the same for all three.
enum RouteStopRole {
  origin('نقطة الانطلاق', 'من أين تبدأ الرحلة'),
  waypoint('نقطة في الطريق', 'مكان يقف فيه الأتوبيس قبل الوجهة'),
  destination('الوجهة النهائية', 'أين تنتهي الرحلة');

  final String label;
  final String hint;

  const RouteStopRole(this.label, this.hint);

  bool get isEndpoint => this != RouteStopRole.waypoint;
}

/// What the editor hands back: the stop itself, and whether the operator chose
/// "حفظ والتالي" instead of finishing — so the caller knows to reopen it for
/// the next one.
typedef RouteStopEditorResult = ({RouteStopDraft stop, bool addAnother});

/// Collects one stop, then hands it back complete.
///
/// The only required answer is a name. Everything else — a street address, a
/// pin on the map, what riders may do here, how long the bus waits — is an
/// optional refinement, and the dialog says so rather than leaving the operator
/// to discover it by trying to save.
Future<RouteStopEditorResult?> showRouteStopEditor(
  BuildContext context, {
  required RouteStopDraft stop,
  required RouteStopRole role,
  RouteStopLibrary library = RouteStopLibrary.empty,
  SearchPlacesUseCase? searchPlaces,
  bool isNew = false,
}) {
  return showDialog<RouteStopEditorResult>(
    context: context,
    builder: (_) => _RouteStopEditorDialog(
      stop: stop,
      role: role,
      library: library,
      searchPlaces: searchPlaces,
      isNew: isNew,
    ),
  );
}

class _RouteStopEditorDialog extends StatefulWidget {
  final RouteStopDraft stop;
  final RouteStopRole role;
  final RouteStopLibrary library;
  final SearchPlacesUseCase? searchPlaces;
  final bool isNew;

  const _RouteStopEditorDialog({
    required this.stop,
    required this.role,
    required this.library,
    required this.searchPlaces,
    required this.isNew,
  });

  @override
  State<_RouteStopEditorDialog> createState() => _RouteStopEditorDialogState();
}

class _RouteStopEditorDialogState extends State<_RouteStopEditorDialog> {
  late RouteStopDraft _stop;
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _stop = widget.stop;
    _name = TextEditingController(text: _stop.name);
    _description = TextEditingController(text: _stop.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  /// Adopting an existing stop or a geocoder result fills several fields at
  /// once, so the text controllers have to follow the model rather than the
  /// other way round.
  void _adopt(RouteStopDraft next) {
    setState(() {
      _stop = next;
      _name.text = next.name;
      _description.text = next.description;
    });
  }

  Future<void> _pickLocation() async {
    final result = await showRouteLocationPicker(
      context,
      stopName: _name.text,
      initial: _stop.point,
      searchPlaces: widget.searchPlaces,
    );
    if (result == null || !mounted) return;
    setState(() {
      _stop = result.isCleared
          ? _stop.withoutPoint()
          : _stop.withPoint(result.point!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.large),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(role: widget.role, isNew: widget.isNew),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  0,
                  AppSpacing.large,
                  AppSpacing.large,
                ),
                children: [
                  _StopNameField(
                    controller: _name,
                    role: widget.role,
                    library: widget.library,
                    searchPlaces: widget.searchPlaces,
                    onChanged: (value) =>
                        setState(() => _stop = _stop.copyWith(name: value)),
                    onSuggestionSelected: (suggestion) => _adopt(
                      suggestion.toStop(_stop.key).copyWith(id: _stop.id),
                    ),
                    onPlaceSelected: (place) => _adopt(_stop.withPlace(place)),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextField(
                    controller: _description,
                    onChanged: (value) =>
                        _stop = _stop.copyWith(description: value),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'الوصف أو العنوان (اختياري)',
                      hintText: 'مثال: موقف شبين القناطر الرئيسي',
                      prefixIcon: Icon(Icons.notes_rounded),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _LocationBlock(
                    point: _stop.point,
                    onPick: _pickLocation,
                    onClear: () => setState(() => _stop = _stop.withoutPoint()),
                  ),
                  if (!widget.role.isEndpoint) ...[
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      'ماذا يفعل الركاب هنا؟',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _BoardingSelector(
                      value: _stop.boarding,
                      onChanged: (value) => setState(
                        () => _stop = _stop.copyWith(boarding: value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _DwellStepper(
                      minutes: _stop.dwellMinutes,
                      onChanged: (value) => setState(
                        () => _stop = _stop.copyWith(dwellMinutes: value),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                0,
                AppSpacing.large,
                AppSpacing.large,
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  // Only offered while adding a brand-new waypoint — the
                  // one action an operator repeats several times per route.
                  if (widget.isNew && !widget.role.isEndpoint)
                    Tooltip(
                      message: _canSave ? '' : 'أدخل اسم النقطة أولاً',
                      child: OutlinedButton.icon(
                        key: const ValueKey('route-stop-editor-save-next'),
                        onPressed: _canSave
                            ? () => Navigator.of(context).pop((
                                stop: _stop.copyWith(name: _name.text.trim()),
                                addAnother: true,
                              ))
                            : null,
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: const Text('حفظ والتالي'),
                      ),
                    ),
                  Tooltip(
                    message: _canSave ? '' : 'أدخل اسم النقطة أولاً',
                    child: FilledButton.icon(
                      key: const ValueKey('route-stop-editor-save'),
                      onPressed: _canSave
                          ? () => Navigator.of(context).pop((
                              stop: _stop.copyWith(name: _name.text.trim()),
                              addAnother: false,
                            ))
                          : null,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(widget.isNew ? 'إضافة النقطة' : 'حفظ النقطة'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final RouteStopRole role;
  final bool isNew;

  const _DialogHeader({required this.role, required this.isNew});

  @override
  Widget build(BuildContext context) {
    return DashboardDialogHeader(
      icon: switch (role) {
        RouteStopRole.origin => Icons.trip_origin_rounded,
        RouteStopRole.waypoint => Icons.pin_drop_outlined,
        RouteStopRole.destination => Icons.flag_rounded,
      },
      title: isNew ? 'إضافة ${role.label}' : 'تعديل ${role.label}',
      description: role.hint,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

/// The stop's name, and the two ways to avoid typing it twice: the office's own
/// stops first, map results second.
///
/// Offering the existing stop before the geocoder is what stops "شبين القناطر"
/// becoming four places. The list is inline rather than an overlay so it works
/// the same inside this dialog at any window size.
class _StopNameField extends StatefulWidget {
  final TextEditingController controller;
  final RouteStopRole role;
  final RouteStopLibrary library;
  final SearchPlacesUseCase? searchPlaces;
  final ValueChanged<String> onChanged;
  final ValueChanged<RouteStopSuggestion> onSuggestionSelected;
  final ValueChanged<GeoPlace> onPlaceSelected;

  const _StopNameField({
    required this.controller,
    required this.role,
    required this.library,
    required this.searchPlaces,
    required this.onChanged,
    required this.onSuggestionSelected,
    required this.onPlaceSelected,
  });

  @override
  State<_StopNameField> createState() => _StopNameFieldState();
}

class _StopNameFieldState extends State<_StopNameField> {
  Timer? _debounce;
  List<GeoPlace> _places = const [];
  bool _searching = false;

  /// The text the operator last accepted from a list. Re-searching it would
  /// re-offer the thing they just chose.
  String _accepted = '';

  @override
  void initState() {
    super.initState();
    _accepted = widget.controller.text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    setState(() {});
    _debounce?.cancel();
    final search = widget.searchPlaces;
    final query = value.trim();
    if (search == null || query.length < 3 || query == _accepted.trim()) {
      setState(() {
        _places = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      try {
        final results = await search(query);
        if (!mounted || widget.controller.text.trim() != query) return;
        setState(() {
          _places = results.take(5).toList();
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _places = const [];
          _searching = false;
        });
      }
    });
  }

  void _accept(String label) {
    _accepted = label;
    setState(() {
      _places = const [];
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = widget.controller.text;
    final suggestions = widget.library.search(query);

    final showSuggestions =
        suggestions.isNotEmpty &&
        (_accepted.trim().isEmpty || query.trim() != _accepted.trim());
    final showPlaces = _places.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'اسم النقطة *',
            hintText: widget.library.isEmpty
                ? 'مثال: شبين القناطر'
                : 'ابحث عن نقطة موجودة أو اكتب اسماً جديداً',
            helperText: query.trim().isEmpty
                ? 'مطلوب — هذا الاسم يظهر للركاب والكباتن'
                : null,
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      _onChanged('');
                    },
                  ),
          ),
        ),
        if (showSuggestions || showPlaces) ...[
          const SizedBox(height: AppSpacing.small),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: scheme.outline.withAlpha(60)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (showSuggestions) ...[
                  _ListLabel(
                    icon: Icons.history_rounded,
                    text: 'نقاط تستخدمها بالفعل',
                  ),
                  ...suggestions.map(
                    (suggestion) => ListTile(
                      dense: true,
                      leading: Icon(
                        suggestion.isLocated
                            ? Icons.place_rounded
                            : Icons.place_outlined,
                        color: scheme.primary,
                      ),
                      title: Text(
                        suggestion.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (suggestion.area.isNotEmpty) suggestion.area,
                          'في ${suggestion.usageCount} مسار',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        widget.onSuggestionSelected(suggestion);
                        _accept(suggestion.name);
                      },
                    ),
                  ),
                ],
                if (showPlaces) ...[
                  _ListLabel(
                    icon: Icons.travel_explore_rounded,
                    text: 'من الخريطة',
                  ),
                  ..._places.map(
                    (place) => ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.add_location_alt_outlined,
                        color: scheme.secondary,
                      ),
                      title: Text(
                        RouteIdentity.shortPlaceLabel(place.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        place.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        widget.onPlaceSelected(place);
                        _accept(RouteIdentity.shortPlaceLabel(place.label));
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'أو اكتب اسماً جديداً واستمر — لا حاجة لاختيار أي شيء من القائمة.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ListLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ListLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest.withAlpha(70),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.xSmall,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xSmall),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The optional map location, stated as optional.
///
/// An unset location renders in the ordinary surface colours with a plain
/// sentence — never the error red the rest of the dashboard reserves for things
/// that are actually wrong.
class _LocationBlock extends StatelessWidget {
  final GeoPoint? point;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _LocationBlock({
    required this.point,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final located = point != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                located ? Icons.place_rounded : Icons.place_outlined,
                size: 20,
                color: located ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  located ? 'الموقع محدد' : 'الموقع الجغرافي غير محدد',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: located ? scheme.primary : null,
                  ),
                ),
              ),
              if (located)
                TextButton.icon(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('إزالة'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            located
                ? '${point!.lat.toStringAsFixed(5)}, ${point!.lng.toStringAsFixed(5)}'
                : 'تحديد الموقع على الخريطة اختياري لتحسين تجربة العملاء.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.small),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(
                located ? 'تغيير الموقع' : 'تحديد الموقع على الخريطة',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Replaces the two independent "allow pickup" / "allow dropoff" checkboxes,
/// which could both be unchecked — a stop nobody can use.
class _BoardingSelector extends StatelessWidget {
  final RouteStopBoarding value;
  final ValueChanged<RouteStopBoarding> onChanged;

  const _BoardingSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<RouteStopBoarding>(
        segments: RouteStopBoarding.values
            .map(
              (option) => ButtonSegment(
                value: option,
                label: Text(option.label, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        selected: {value},
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Dwell time as a stepper instead of a free-text minutes field: it cannot be
/// typed wrong, and it feeds the arrival times derived for every later stop.
class _DwellStepper extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _DwellStepper({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            'مدة التوقف في المحطة',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outline.withAlpha(90)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onPressed: minutes <= 0 ? null : () => onChanged(minutes - 1),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '$minutes د',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onPressed: minutes >= 120 ? null : () => onChanged(minutes + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
