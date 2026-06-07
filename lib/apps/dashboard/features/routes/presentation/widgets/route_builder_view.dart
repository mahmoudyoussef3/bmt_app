import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_route.dart';
import 'route_timeline.dart';

class RouteBuilderView extends StatefulWidget {
  final ValueChanged<OperationRoute> onSubmit;
  final VoidCallback onCancel;

  const RouteBuilderView({
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  @override
  State<RouteBuilderView> createState() => _RouteBuilderViewState();
}

class _RouteBuilderViewState extends State<RouteBuilderView> {
  int _step = 0;
  final _name = TextEditingController();
  final _start = TextEditingController(text: 'بنها');
  final _end = TextEditingController();
  final _duration = TextEditingController();
  final _distance = TextEditingController();
  final List<RouteStation> _stations = [
    const RouteStation(
      id: 'draft-1',
      name: 'Station 1',
      area: 'نقطة البداية',
      arrivalOffset: '٠ دقيقة',
      order: 1,
    ),
    const RouteStation(
      id: 'draft-2',
      name: 'Station 2',
      area: 'منتصف المسار',
      arrivalOffset: '٢٠ دقيقة',
      order: 2,
    ),
    const RouteStation(
      id: 'draft-3',
      name: 'Station 3',
      area: 'قبل الوصول',
      arrivalOffset: '٥٠ دقيقة',
      order: 3,
    ),
  ];

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    _duration.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildRoute();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بناء مسار جديد',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  const Text(
                    'إنشاء مسار بصري خطوة بخطوة بدون أي خرائط خارجية.',
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'إلغاء',
              height: 40,
              outline: true,
              onPressed: widget.onCancel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final builder = AppCard(
              child: Stepper(
                currentStep: _step,
                onStepTapped: (step) => setState(() => _step = step),
                onStepContinue: _step == 3
                    ? () => widget.onSubmit(_buildRoute())
                    : () => setState(() => _step += 1),
                onStepCancel: _step == 0
                    ? widget.onCancel
                    : () => setState(() => _step -= 1),
                controlsBuilder: (context, details) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.medium),
                  child: Wrap(
                    spacing: AppSpacing.small,
                    children: [
                      AppButton(
                        label: _step == 3 ? 'حفظ المسار' : 'التالي',
                        height: 40,
                        onPressed: details.onStepContinue ?? () {},
                      ),
                      AppButton(
                        label: _step == 0 ? 'إلغاء' : 'السابق',
                        height: 40,
                        outline: true,
                        onPressed: details.onStepCancel ?? () {},
                      ),
                    ],
                  ),
                ),
                steps: [
                  Step(
                    title: const Text('تعريف المسار'),
                    isActive: _step >= 0,
                    content: _Fields(
                      fields: [
                        ('اسم المسار', _name),
                        ('مدينة الانطلاق', _start),
                        ('مدينة الوصول', _end),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('المدة والمسافة'),
                    isActive: _step >= 1,
                    content: _Fields(
                      fields: [
                        ('مدة الرحلة', _duration),
                        ('المسافة', _distance),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('المحطات'),
                    isActive: _step >= 2,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._stations.map(
                          (station) => ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(station.name),
                            subtitle: Text(station.area),
                          ),
                        ),
                        AppButton(
                          label: 'إضافة محطة سريعة',
                          height: 40,
                          outline: true,
                          onPressed: () => setState(() {
                            final next = _stations.length + 1;
                            _stations.add(
                              RouteStation(
                                id: 'draft-$next',
                                name: 'Station $next',
                                area: 'منطقة جديدة',
                                arrivalOffset: '${next * 20} دقيقة',
                                order: next,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('المراجعة'),
                    isActive: _step >= 3,
                    content: Text(
                      '${preview.name} • ${preview.stations.length} محطات • ${preview.duration}',
                    ),
                  ),
                ],
              ),
            );

            if (compact) {
              return Column(
                children: [
                  builder,
                  const SizedBox(height: AppSpacing.medium),
                  RouteTimeline(route: preview),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: builder),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: RouteTimeline(route: preview)),
              ],
            );
          },
        ),
      ],
    );
  }

  OperationRoute _buildRoute() {
    final name = _name.text.trim().isEmpty ? 'مسار جديد' : _name.text.trim();
    final start = _start.text.trim().isEmpty ? 'بنها' : _start.text.trim();
    final end = _end.text.trim().isEmpty ? 'وجهة جديدة' : _end.text.trim();
    return OperationRoute(
      id: '',
      name: name,
      startCity: start,
      endCity: end,
      duration: _duration.text.trim().isEmpty
          ? 'غير محدد'
          : _duration.text.trim(),
      distance: _distance.text.trim().isEmpty
          ? 'غير محدد'
          : _distance.text.trim(),
      tripsCount: 0,
      status: OperationRouteStatus.draft,
      stations: _stations,
      notes: const ['تم إنشاؤه من أداة بناء المسار التجريبية.'],
    );
  }
}

class _Fields extends StatelessWidget {
  final List<(String, TextEditingController)> fields;

  const _Fields({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: fields
          .map(
            (field) => SizedBox(
              width: 280,
              child: TextField(
                controller: field.$2,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(labelText: field.$1),
              ),
            ),
          )
          .toList(),
    );
  }
}
