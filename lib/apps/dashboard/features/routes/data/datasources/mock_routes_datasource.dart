import '../../domain/entities/operation_route.dart';
import '../models/operation_route_model.dart';

abstract class RoutesDatasource {
  Future<List<OperationRouteModel>> fetchRoutes();
  Future<OperationRouteModel> createRoute(OperationRoute route);
  Future<OperationRouteModel> updateRoute(OperationRoute route);
  Future<OperationRouteModel> addStation(String routeId, RouteStation station);
  Future<OperationRouteModel> updateStation(
    String routeId,
    RouteStation station,
  );
  Future<OperationRouteModel> deleteStation(String routeId, String stationId);
  Future<OperationRouteModel> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  );
}

class MockRoutesDatasource implements RoutesDatasource {
  final List<OperationRouteModel> _routes = List<OperationRouteModel>.from(
    _seedRoutes,
  );

  @override
  Future<OperationRouteModel> addStation(
    String routeId,
    RouteStation station,
  ) async {
    final route = _find(routeId);
    final stations = [
      ...route.stations,
      station.copyWith(
        id: station.id.isEmpty
            ? 'st-${route.id}-${route.stations.length + 1}'
            : station.id,
        order: route.stations.length + 1,
      ),
    ];
    return _replace(route.copyWith(stations: _normalize(stations)));
  }

  @override
  Future<OperationRouteModel> createRoute(OperationRoute route) async {
    final model = OperationRouteModel.fromEntity(
      route.copyWith(
        id: 'route-${_routes.length + 1}',
        stations: _assignStationIds(route.id, route.stations),
      ),
    );
    _routes.insert(0, model);
    return model;
  }

  @override
  Future<OperationRouteModel> deleteStation(
    String routeId,
    String stationId,
  ) async {
    final route = _find(routeId);
    final stations = route.stations
        .where((station) => station.id != stationId)
        .toList();
    return _replace(route.copyWith(stations: _normalize(stations)));
  }

  @override
  Future<List<OperationRouteModel>> fetchRoutes() async {
    return List<OperationRouteModel>.unmodifiable(_routes);
  }

  @override
  Future<OperationRouteModel> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  ) async {
    final route = _find(routeId);
    final stations = [...route.stations];
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final station = stations.removeAt(oldIndex);
    stations.insert(adjustedIndex, station);
    return _replace(route.copyWith(stations: _normalize(stations)));
  }

  @override
  Future<OperationRouteModel> updateRoute(OperationRoute route) async {
    return _replace(route);
  }

  @override
  Future<OperationRouteModel> updateStation(
    String routeId,
    RouteStation station,
  ) async {
    final route = _find(routeId);
    final stations = route.stations
        .map((item) => item.id == station.id ? station : item)
        .toList();
    return _replace(route.copyWith(stations: _normalize(stations)));
  }

  OperationRouteModel _find(String routeId) {
    return _routes.firstWhere(
      (route) => route.id == routeId,
      orElse: () => throw ArgumentError('Route not found'),
    );
  }

  OperationRouteModel _replace(OperationRoute route) {
    final index = _routes.indexWhere((item) => item.id == route.id);
    if (index == -1) throw ArgumentError('Route not found');
    final model = OperationRouteModel.fromEntity(route);
    _routes[index] = model;
    return model;
  }

  List<RouteStation> _normalize(List<RouteStation> stations) {
    return stations.indexed.map((entry) {
      final (index, station) = entry;
      return station.copyWith(order: index + 1);
    }).toList();
  }

  List<RouteStation> _assignStationIds(
    String routeId,
    List<RouteStation> stations,
  ) {
    return stations.indexed.map((entry) {
      final (index, station) = entry;
      return station.copyWith(
        id: station.id.isEmpty ? 'st-$routeId-${index + 1}' : station.id,
        order: index + 1,
      );
    }).toList();
  }
}

final List<OperationRouteModel> _seedRoutes = [
  _route(
    id: 'route-1',
    name: 'بنها - القرية الذكية',
    start: 'بنها',
    end: 'القرية الذكية',
    duration: '٧٥ دقيقة',
    distance: '٧٦ كم',
    status: OperationRouteStatus.active,
    areas: [
      'بنها',
      'طوخ',
      'شبرا الخيمة',
      'رمسيس',
      'محور ٢٦ يوليو',
      'الشيخ زايد',
      'القرية الذكية',
    ],
  ),
  _route(
    id: 'route-2',
    name: 'المنصورة - القاهرة الجديدة',
    start: 'المنصورة',
    end: 'القاهرة الجديدة',
    duration: '١٥٥ دقيقة',
    distance: '١٤٣ كم',
    status: OperationRouteStatus.active,
    areas: [
      'المنصورة',
      'طلخا',
      'أجا',
      'ميت غمر',
      'بنها',
      'السلام',
      'الرحاب',
      'التجمع الخامس',
    ],
  ),
  _route(
    id: 'route-3',
    name: 'الشروق - التجمع الخامس',
    start: 'الشروق',
    end: 'التجمع الخامس',
    duration: '٤٥ دقيقة',
    distance: '٣٢ كم',
    status: OperationRouteStatus.active,
    areas: [
      'مدينة الشروق',
      'مدينتي',
      'الرحاب',
      'شارع التسعين الشمالي',
      'كايرو فيستيفال',
      'التجمع الخامس',
    ],
  ),
  _route(
    id: 'route-4',
    name: 'مدينة نصر - القرية الذكية',
    start: 'مدينة نصر',
    end: 'القرية الذكية',
    duration: '٩٠ دقيقة',
    distance: '٧٨ كم',
    status: OperationRouteStatus.active,
    areas: [
      'عباس العقاد',
      'مصطفى النحاس',
      'مصر الجديدة',
      'رمسيس',
      'الدائري',
      'الشيخ زايد',
      'القرية الذكية',
    ],
  ),
  _route(
    id: 'route-5',
    name: 'العبور - الشيخ زايد',
    start: 'العبور',
    end: 'الشيخ زايد',
    duration: '١١٠ دقيقة',
    distance: '٩٢ كم',
    status: OperationRouteStatus.paused,
    areas: [
      'مدينة العبور',
      'السلام',
      'موقف العاشر',
      'رمسيس',
      'المحور',
      'هايبر وان',
      'الشيخ زايد',
    ],
  ),
  _route(
    id: 'route-6',
    name: 'المعادي - العاصمة الإدارية',
    start: 'المعادي',
    end: 'العاصمة الإدارية',
    duration: '٧٠ دقيقة',
    distance: '٦٨ كم',
    status: OperationRouteStatus.active,
    areas: [
      'كورنيش المعادي',
      'زهراء المعادي',
      'القطامية',
      'التجمع الثالث',
      'الطريق الإقليمي',
      'الحي الحكومي',
    ],
  ),
  _route(
    id: 'route-7',
    name: '٦ أكتوبر - وسط البلد',
    start: '٦ أكتوبر',
    end: 'وسط البلد',
    duration: '٦٠ دقيقة',
    distance: '٤٨ كم',
    status: OperationRouteStatus.active,
    areas: [
      'الحصري',
      'مول العرب',
      'وصلة دهشور',
      'المحور',
      'المهندسين',
      'التحرير',
    ],
  ),
  _route(
    id: 'route-8',
    name: 'حلوان - التجمع الخامس',
    start: 'حلوان',
    end: 'التجمع الخامس',
    duration: '٨٥ دقيقة',
    distance: '٦١ كم',
    status: OperationRouteStatus.paused,
    areas: [
      'حلوان',
      'المعصرة',
      'المعادي',
      'القطامية',
      'شارع التسعين',
      'التجمع الخامس',
    ],
  ),
  _route(
    id: 'route-9',
    name: 'طنطا - مدينة نصر',
    start: 'طنطا',
    end: 'مدينة نصر',
    duration: '١٣٥ دقيقة',
    distance: '١٢١ كم',
    status: OperationRouteStatus.active,
    areas: ['طنطا', 'قويسنا', 'بنها', 'شبرا الخيمة', 'الدائري', 'عباس العقاد'],
  ),
  _route(
    id: 'route-10',
    name: 'الإسكندرية - القاهرة الجديدة',
    start: 'الإسكندرية',
    end: 'القاهرة الجديدة',
    duration: '٢٠٥ دقيقة',
    distance: '٢٢٣ كم',
    status: OperationRouteStatus.archived,
    areas: [
      'سموحة',
      'محرم بك',
      'العامرية',
      'وادي النطرون',
      'الرماية',
      'الرحاب',
      'التجمع الخامس',
    ],
  ),
];

OperationRouteModel _route({
  required String id,
  required String name,
  required String start,
  required String end,
  required String duration,
  required String distance,
  required OperationRouteStatus status,
  required List<String> areas,
}) {
  final stations = areas.indexed.map((entry) {
    final (index, area) = entry;
    final arrivalMinutes = index * 15;
    final departureMinutes =
        arrivalMinutes + (index == areas.length - 1 ? 0 : 3);
    return RouteStation(
      id: 'st-$id-${index + 1}',
      name: index == 0
          ? 'نقطة انطلاق $area'
          : index == areas.length - 1
          ? 'نقطة وصول $area'
          : 'محطة $area',
      area: area,
      arrivalOffset: '$arrivalMinutes دقيقة',
      departureOffset: '$departureMinutes دقيقة',
      locationDescription: 'نقطة تجمع واضحة داخل نطاق $area',
      notes: index == 0
          ? 'تأكيد حضور الركاب قبل التحرك.'
          : 'تسجيل الصعود والنزول من لوحة التشغيل.',
      order: index + 1,
    );
  }).toList();

  return OperationRouteModel(
    id: id,
    name: name,
    startCity: start,
    endCity: end,
    duration: duration,
    distance: distance,
    status: status,
    stations: stations,
    notes: const [
      'مسار ثابت قابل للاستخدام في إنشاء الرحلات',
      'آخر مراجعة تشغيلية تمت خلال يونيو ٢٠٢٦',
    ],
  );
}
