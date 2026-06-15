import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_route.dart';
import 'route_timeline.dart';

class RouteBuilderView extends StatefulWidget {
  final OperationRoute? route;
  final ValueChanged<OperationRoute> onSubmit;
  final VoidCallback onCancel;

  const RouteBuilderView({
    required this.onSubmit,
    required this.onCancel,
    this.route,
    super.key,
  });

  @override
  State<RouteBuilderView> createState() => _RouteBuilderViewState();
}

class _RouteBuilderViewState extends State<RouteBuilderView> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _duration;
  late final TextEditingController _distance;
  late final TextEditingController _routeNote;
  late final TextEditingController _stationName;
  late final TextEditingController _stationArea;
  late final TextEditingController _stationArrival;
  late final TextEditingController _stationNotes;
  late List<RouteStation> _stations;
  late OperationRouteStatus _status;
  RouteStation? _editingStation;

  bool get _editingRoute => widget.route != null;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _name = TextEditingController(text: route?.name ?? '');
    _code = TextEditingController(text: route?.routeCode ?? '');
    _start = TextEditingController(text: route?.startCity ?? '');
    _end = TextEditingController(text: route?.endCity ?? '');
    _duration = TextEditingController(text: route?.duration ?? '');
    _distance = TextEditingController(text: route?.distance ?? '');
    _routeNote = TextEditingController(
      text: route?.notes.isNotEmpty == true ? route!.notes.first : '',
    );
    _stationName = TextEditingController();
    _stationArea = TextEditingController();
    _stationArrival = TextEditingController();
    _stationNotes = TextEditingController();
    _stations = [...?route?.stations];
    _status = route?.status ?? OperationRouteStatus.draft;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _start.dispose();
    _end.dispose();
    _duration.dispose();
    _distance.dispose();
    _routeNote.dispose();
    _stationName.dispose();
    _stationArea.dispose();
    _stationArrival.dispose();
    _stationNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildRoute();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingRoute ? 'تعديل المسار' : 'بناء مسار جديد',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'صمم الرحلة كنقاط متتابعة، ثم راجعها بصرياً قبل الحفظ.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  AppButton(
                    label: 'إلغاء',
                    height: 40,
                    outline: true,
                    onPressed: widget.onCancel,
                  ),
                  AppButton(
                    label: _editingRoute ? 'حفظ التعديل' : 'حفظ المسار',
                    height: 40,
                    onPressed: () => widget.onSubmit(preview),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1080;
            final builder = _BuilderPanel(
              name: _name,
              code: _code,
              start: _start,
              end: _end,
              duration: _duration,
              distance: _distance,
              routeNote: _routeNote,
              status: _status,
              onStatusChanged: (status) => setState(() => _status = status),
              stationName: _stationName,
              stationArea: _stationArea,
              stationArrival: _stationArrival,
              stationNotes: _stationNotes,
              editingStation: _editingStation,
              stations: _stations,
              onSaveStation: _saveStation,
              onEditStation: _startEditingStation,
              onDeleteStation: _deleteStation,
              onCancelStationEdit: _cancelStationEdit,
              onReorder: _reorderStations,
            );
            final previewPanel = _LivePreview(route: preview);

            if (compact) {
              return Column(
                children: [
                  builder,
                  const SizedBox(height: AppSpacing.large),
                  previewPanel,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: builder),
                const SizedBox(width: AppSpacing.large),
                Expanded(flex: 2, child: previewPanel),
              ],
            );
          },
        ),
      ],
    );
  }

  void _saveStation() {
    final existing = _editingStation;
    final nextOrder = existing?.order ?? _stations.length + 1;
    final station = RouteStation(
      id: existing?.id ?? 'draft-${DateTime.now().microsecondsSinceEpoch}',
      name: _stationName.text.trim(),
      area: _stationArea.text.trim(),
      arrivalOffset: _stationArrival.text.trim(),
      estimatedArrivalTime: existing?.estimatedArrivalTime ?? '',
      notes: _stationNotes.text.trim(),
      pickupAllowed: existing?.pickupAllowed ?? true,
      dropoffAllowed: existing?.dropoffAllowed ?? true,
      order: nextOrder,
    );

    setState(() {
      if (existing == null) {
        _stations = _normalize([..._stations, station]);
      } else {
        _stations = _normalize(
          _stations.map((item) => item.id == existing.id ? station : item),
        );
      }
      _clearStationFields();
    });
  }

  void _startEditingStation(RouteStation station) {
    setState(() {
      _editingStation = station;
      _stationName.text = station.name;
      _stationArea.text = station.area;
      _stationArrival.text = station.arrivalOffset;
      _stationNotes.text = station.notes;
    });
  }

  void _deleteStation(RouteStation station) {
    setState(() {
      _stations = _normalize(_stations.where((item) => item.id != station.id));
      if (_editingStation?.id == station.id) {
        _clearStationFields();
      }
    });
  }

  void _reorderStations(int oldIndex, int newIndex) {
    setState(() {
      final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final stations = [..._stations];
      final station = stations.removeAt(oldIndex);
      stations.insert(adjustedIndex, station);
      _stations = _normalize(stations);
    });
  }

  void _cancelStationEdit() {
    setState(_clearStationFields);
  }

  void _clearStationFields() {
    _editingStation = null;
    _stationName.clear();
    _stationArea.clear();
    _stationArrival.clear();
    _stationNotes.clear();
  }

  List<RouteStation> _normalize(Iterable<RouteStation> stations) {
    return stations.indexed.map((entry) {
      final (index, station) = entry;
      return station.copyWith(order: index + 1);
    }).toList();
  }

  OperationRoute _buildRoute() {
    final route = widget.route;
    return OperationRoute(
      id: route?.id ?? '',
      routeCode: _code.text.trim(),
      name: _name.text.trim(),
      startCity: _start.text.trim(),
      endCity: _end.text.trim(),
      duration: _duration.text.trim(),
      distance: _distance.text.trim(),
      status: _status,
      stations: _normalize(_stations),
      notes: _routeNote.text.trim().isEmpty ? const [] : [_routeNote.text],
    );
  }
}

class _BuilderPanel extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController code;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController duration;
  final TextEditingController distance;
  final TextEditingController routeNote;
  final OperationRouteStatus status;
  final ValueChanged<OperationRouteStatus> onStatusChanged;
  final TextEditingController stationName;
  final TextEditingController stationArea;
  final TextEditingController stationArrival;
  final TextEditingController stationNotes;
  final RouteStation? editingStation;
  final List<RouteStation> stations;
  final VoidCallback onSaveStation;
  final ValueChanged<RouteStation> onEditStation;
  final ValueChanged<RouteStation> onDeleteStation;
  final VoidCallback onCancelStationEdit;
  final ReorderCallback onReorder;

  const _BuilderPanel({
    required this.name,
    required this.code,
    required this.start,
    required this.end,
    required this.duration,
    required this.distance,
    required this.routeNote,
    required this.status,
    required this.onStatusChanged,
    required this.stationName,
    required this.stationArea,
    required this.stationArrival,
    required this.stationNotes,
    required this.editingStation,
    required this.stations,
    required this.onSaveStation,
    required this.onEditStation,
    required this.onDeleteStation,
    required this.onCancelStationEdit,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات الرحلة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: [
              _TextInput(label: 'اسم المسار', controller: name),
              _TextInput(label: 'كود المسار', controller: code),
              _TextInput(label: 'نقطة البداية', controller: start),
              _TextInput(label: 'نقطة النهاية', controller: end),
              _TextInput(label: 'مدة الرحلة', controller: duration),
              _TextInput(label: 'المسافة', controller: distance),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<OperationRouteStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'حالة المسار'),
                  items: OperationRouteStatus.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
              _TextInput(
                label: 'ملاحظات المسار',
                controller: routeNote,
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text('محطات الرحلة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          _StationComposer(
            name: stationName,
            area: stationArea,
            arrival: stationArrival,
            notes: stationNotes,
            editingStation: editingStation,
            onSave: onSaveStation,
            onCancelEdit: onCancelStationEdit,
          ),
          const SizedBox(height: AppSpacing.medium),
          _StationReorderList(
            stations: stations,
            onReorder: onReorder,
            onEditStation: onEditStation,
            onDeleteStation: onDeleteStation,
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _TextInput({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: controller,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _StationComposer extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController area;
  final TextEditingController arrival;
  final TextEditingController notes;
  final RouteStation? editingStation;
  final VoidCallback onSave;
  final VoidCallback onCancelEdit;

  const _StationComposer({
    required this.name,
    required this.area,
    required this.arrival,
    required this.notes,
    required this.editingStation,
    required this.onSave,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    final editing = editingStation != null;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(130),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'تعديل محطة' : 'إضافة محطة للرحلة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.medium,
              runSpacing: AppSpacing.medium,
              children: [
                _TextInput(label: 'اسم المحطة', controller: name),
                _TextInput(label: 'المنطقة', controller: area),
                _TextInput(label: 'وقت الوصول المتوقع', controller: arrival),
                _TextInput(label: 'ملاحظات', controller: notes, maxLines: 2),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                AppButton(
                  label: editing ? 'حفظ المحطة' : 'إضافة المحطة',
                  height: 40,
                  onPressed: onSave,
                ),
                if (editing)
                  AppButton(
                    label: 'إلغاء التعديل',
                    height: 40,
                    outline: true,
                    onPressed: onCancelEdit,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StationReorderList extends StatelessWidget {
  final List<RouteStation> stations;
  final ReorderCallback onReorder;
  final ValueChanged<RouteStation> onEditStation;
  final ValueChanged<RouteStation> onDeleteStation;

  const _StationReorderList({
    required this.stations,
    required this.onReorder,
    required this.onEditStation,
    required this.onDeleteStation,
  });

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const Text('ابدأ بإضافة محطة واحدة على الأقل.');
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: stations.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final station = stations[index];
        return _StationBuilderCard(
          key: ValueKey(station.id),
          station: station,
          index: index,
          onEdit: () => onEditStation(station),
          onDelete: () => onDeleteStation(station),
        );
      },
    );
  }
}

class _StationBuilderCard extends StatelessWidget {
  final RouteStation station;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StationBuilderCard({
    required this.station,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
              const SizedBox(width: AppSpacing.small),
              CircleAvatar(radius: 15, child: Text('${index + 1}')),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text('${station.area} • ${station.arrivalOffset}'),
                    if (station.notes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(station.notes),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final OperationRoute route;

  const _LivePreview({required this.route});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _JourneySummary(route: route),
        const SizedBox(height: AppSpacing.medium),
        RouteTimeline(route: route),
      ],
    );
  }
}

class _JourneySummary extends StatelessWidget {
  final OperationRoute route;

  const _JourneySummary({required this.route});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معاينة المسار', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: _Endpoint(label: 'البداية', value: route.startCity),
              ),
              Icon(Icons.arrow_back, color: scheme.primary),
              Expanded(
                child: _Endpoint(label: 'النهاية', value: route.endCity),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              _MetricChip(label: '${route.stations.length} محطات'),
              _MetricChip(label: route.duration),
              _MetricChip(label: route.distance),
              _MetricChip(label: route.status.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  final String label;
  final String value;

  const _Endpoint({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;

  const _MetricChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
