import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../domain/entities/operation_route.dart';
import '../../../domain/entities/route_draft.dart';
import '../../../domain/usecases/search_places_usecase.dart';
import '../../cubit/route_builder_cubit.dart';
import '../../cubit/route_builder_state.dart';
import 'route_place_field.dart';
import 'route_stop_card.dart';

/// The builder's editing column: where the route starts and ends, what it stops
/// at on the way, and — folded away until wanted — its name, code and status.
///
/// The order is deliberate. A route is two places; everything else is a detail
/// of those two. The previous form opened on "اسم المسار / كود المسار" and hid
/// the actual route below three more cards.
class RouteBuilderPanel extends StatelessWidget {
  final RouteBuilderState state;
  final RouteBuilderCubit cubit;
  final SearchPlacesUseCase? searchPlaces;

  const RouteBuilderPanel({
    super.key,
    required this.state,
    required this.cubit,
    required this.searchPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final draft = state.draft;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _SectionTitle(
          icon: Icons.swap_calls_rounded,
          title: 'خط السير',
          subtitle: 'من أين إلى أين يتحرك الأتوبيس',
          trailing: TextButton.icon(
            onPressed: cubit.swapEndpoints,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: const Text('عكس الاتجاه'),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _EndpointRow(
          icon: Icons.trip_origin_rounded,
          label: 'نقطة الانطلاق',
          hint: 'ابحث عن المدينة أو الموقف',
          index: 0,
          stop: draft.origin,
          state: state,
          cubit: cubit,
          searchPlaces: searchPlaces,
          autofocus: !draft.isEditing && draft.origin.name.isEmpty,
        ),
        _EndpointConnector(count: draft.intermediateStops.length),
        _EndpointRow(
          icon: Icons.flag_rounded,
          label: 'الوجهة النهائية',
          hint: 'ابحث عن المدينة أو الموقف',
          index: draft.stops.length - 1,
          stop: draft.destination,
          state: state,
          cubit: cubit,
          searchPlaces: searchPlaces,
        ),
        const SizedBox(height: AppSpacing.large),
        _SectionTitle(
          icon: Icons.pin_drop_outlined,
          title: 'محطات في الطريق',
          subtitle: 'اختياري — أضفها إذا كان الأتوبيس يقف قبل الوجهة',
          trailing: FilledButton.tonalIcon(
            onPressed: cubit.addStop,
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة محطة'),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _StopsList(state: state, cubit: cubit, searchPlaces: searchPlaces),
        const SizedBox(height: AppSpacing.large),
        _DetailsSection(state: state, cubit: cubit),
      ],
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final int index;
  final RouteStopDraft stop;
  final RouteBuilderState state;
  final RouteBuilderCubit cubit;
  final SearchPlacesUseCase? searchPlaces;
  final bool autofocus;

  const _EndpointRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.index,
    required this.stop,
    required this.state,
    required this.cubit,
    required this.searchPlaces,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picking = state.picking && state.activeIndex == index;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoutePlaceField(
                key: ValueKey('endpoint-${stop.key}'),
                label: label,
                hint: hint,
                icon: Icons.search_rounded,
                value: stop.name,
                focusPoint: stop.point,
                searchPlaces: searchPlaces,
                autofocus: autofocus,
                onChanged: (value) => cubit.renameStop(index, value),
                onPlaceSelected: (place) => cubit.selectPlace(index, place),
              ),
              if (stop.isLocated || stop.arrivalOffset.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  [
                    if (stop.area.trim().isNotEmpty) stop.area.trim(),
                    if (index == 0 && stop.departureOffset.isNotEmpty)
                      'الانطلاق ${stop.departureOffset}'
                    else if (stop.arrivalOffset.isNotEmpty)
                      'الوصول بعد ${stop.arrivalOffset}',
                  ].join(' · '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: MapPickButton(
            active: picking,
            onPressed: () =>
                picking ? cubit.cancelPicking() : cubit.pickOnMap(index),
          ),
        ),
      ],
    );
  }
}

/// The line between origin and destination, labelled with the number of stops
/// in between so the shape of the route reads at a glance.
class _EndpointConnector extends StatelessWidget {
  final int count;

  const _EndpointConnector({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 9, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(width: 2, height: 26, color: scheme.outline.withAlpha(110)),
          const SizedBox(width: AppSpacing.medium),
          Text(
            count == 0 ? 'مسار مباشر' : '$count محطة في الطريق',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StopsList extends StatelessWidget {
  final RouteBuilderState state;
  final RouteBuilderCubit cubit;
  final SearchPlacesUseCase? searchPlaces;

  const _StopsList({
    required this.state,
    required this.cubit,
    required this.searchPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final stops = state.draft.intermediateStops;
    if (stops.isEmpty) return const _NoStopsHint();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: stops.length,
      // The list holds only the stops between the endpoints, so positions are
      // shifted by one to address the draft's full ordered list.
      onReorder: (oldIndex, newIndex) =>
          cubit.moveStop(oldIndex + 1, newIndex + 1),
      itemBuilder: (context, position) {
        final entry = stops[position];
        return RouteStopCard(
          key: ValueKey(entry.stop.key),
          index: entry.index,
          dragIndex: position,
          stop: entry.stop,
          expanded: state.activeIndex == entry.index,
          picking: state.picking && state.activeIndex == entry.index,
          searchPlaces: searchPlaces,
          onToggle: () => cubit.focusStop(
            state.activeIndex == entry.index ? -1 : entry.index,
          ),
          onPickOnMap: () => state.picking && state.activeIndex == entry.index
              ? cubit.cancelPicking()
              : cubit.pickOnMap(entry.index),
          onRemove: () => cubit.removeStop(entry.index),
          onNameChanged: (value) => cubit.renameStop(entry.index, value),
          onPlaceSelected: (place) => cubit.selectPlace(entry.index, place),
          onBoardingChanged: (value) => cubit.setBoarding(entry.index, value),
          onDwellChanged: (value) => cubit.setDwellMinutes(entry.index, value),
        );
      },
    );
  }
}

class _NoStopsHint extends StatelessWidget {
  const _NoStopsHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(Icons.linear_scale_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'لا توجد محطات وسيطة — سيسير الأتوبيس مباشرة من الانطلاق إلى الوجهة.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Name, code and status: all three have a sensible default, so the section
/// stays folded and shows what will be saved on its header line.
class _DetailsSection extends StatefulWidget {
  final RouteBuilderState state;
  final RouteBuilderCubit cubit;

  const _DetailsSection({required this.state, required this.cubit});

  @override
  State<_DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<_DetailsSection> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  bool _open = false;

  RouteDraft get _draft => widget.state.draft;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _draft.nameOverride);
    _code = TextEditingController(text: _draft.codeOverride);
    _distance = TextEditingController(text: _draft.distance);
    _duration = TextEditingController(text: _draft.duration);
  }

  @override
  void didUpdateWidget(_DetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Distance and duration are recalculated for the operator; mirror the new
    // values into the manual fields without disturbing anything being typed.
    _sync(_distance, _draft.distance);
    _sync(_duration, _draft.duration);
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _distance.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final draft = widget.state.draft;
    final cubit = widget.cubit;
    final summary = [
      draft.name.isEmpty ? 'بلا اسم بعد' : draft.name,
      draft.code,
      draft.status.label,
    ].where((part) => part.isNotEmpty).join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(35),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات المسار',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: AppTokens.motionBase,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                0,
                AppSpacing.medium,
                AppSpacing.medium,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    onChanged: cubit.setName,
                    decoration: InputDecoration(
                      labelText: 'اسم المسار',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: draft.suggestedName.isEmpty
                          ? 'يُقترح تلقائياً بعد تحديد النقطتين'
                          : draft.suggestedName,
                      helperText: draft.usesSuggestedName
                          ? 'يُستخدم الاسم المقترح تلقائياً'
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: cubit.setCode,
                          decoration: InputDecoration(
                            labelText: 'كود المسار',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            hintText: draft.suggestedCode,
                            helperText: draft.usesSuggestedCode
                                ? 'كود تلقائي غير مستخدم'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: DropdownButtonFormField<OperationRouteStatus>(
                          initialValue: draft.status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'الحالة',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: OperationRouteStatus.active,
                              child: Text('نشط'),
                            ),
                            DropdownMenuItem(
                              value: OperationRouteStatus.paused,
                              child: Text('متوقف'),
                            ),
                          ],
                          onChanged: (value) => cubit.setStatus(
                            value ?? OperationRouteStatus.active,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.state.geoEnabled) ...[
                    const SizedBox(height: AppSpacing.medium),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _distance,
                            onChanged: cubit.setDistance,
                            decoration: const InputDecoration(
                              labelText: 'المسافة',
                              hintText: 'مثال: 42 كم',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: TextField(
                            controller: _duration,
                            onChanged: cubit.setDuration,
                            decoration: const InputDecoration(
                              labelText: 'المدة',
                              hintText: 'مثال: 1 س 10 د',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
