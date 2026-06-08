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
            ? 'st-${route.stations.length + 10}'
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
        id: 'route-${_routes.length + 10}',
        stations: _assignStationIds(route.stations),
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

  List<RouteStation> _assignStationIds(List<RouteStation> stations) {
    return stations.indexed.map((entry) {
      final (index, station) = entry;
      return station.copyWith(
        id: station.id.isEmpty ? 'st-new-${index + 1}' : station.id,
        order: index + 1,
      );
    }).toList();
  }
}

const _seedRoutes = [
  OperationRouteModel(
    id: 'route-1',
    name: 'بنها - القرية الذكية',
    startCity: 'بنها',
    endCity: 'القرية الذكية',
    duration: '٧٥ دقيقة',
    distance: '٧٦ كم',
    tripsCount: 18,
    status: OperationRouteStatus.active,
    stations: [
      RouteStation(
        id: 'st-1',
        name: 'محطة بنها الرئيسية',
        area: 'بنها',
        arrivalOffset: '٠ دقيقة',
        notes: 'نقطة تجمع رئيسية بجوار مدخل المحطة.',
        order: 1,
      ),
      RouteStation(
        id: 'st-2',
        name: 'موقف شبرا',
        area: 'شبرا الخيمة',
        arrivalOffset: '٢٠ دقيقة',
        notes: 'تأكيد الوقوف في الجانب الشرقي وقت الذروة.',
        order: 2,
      ),
      RouteStation(
        id: 'st-3',
        name: 'بوابة الشيخ زايد',
        area: 'الشيخ زايد',
        arrivalOffset: '٦٠ دقيقة',
        notes: 'محطة إنزال فقط في الرحلات الصباحية.',
        order: 3,
      ),
      RouteStation(
        id: 'st-4',
        name: 'القرية الذكية',
        area: '٦ أكتوبر',
        arrivalOffset: '٧٥ دقيقة',
        notes: 'نهاية المسار أمام البوابة الرئيسية.',
        order: 4,
      ),
    ],
    notes: ['مسار صباحي عالي الطلب', 'يفضل مركبات سعة ١٢ مقعد'],
  ),
  OperationRouteModel(
    id: 'route-2',
    name: 'بنها - مدينة نصر',
    startCity: 'بنها',
    endCity: 'مدينة نصر',
    duration: '٦٥ دقيقة',
    distance: '٦٢ كم',
    tripsCount: 14,
    status: OperationRouteStatus.active,
    stations: [
      RouteStation(
        id: 'st-5',
        name: 'بنها الجديدة',
        area: 'بنها',
        arrivalOffset: '٠ دقيقة',
        notes: 'تجمع أمام الموقف الجديد.',
        order: 1,
      ),
      RouteStation(
        id: 'st-6',
        name: 'الدائري',
        area: 'القاهرة',
        arrivalOffset: '٣٥ دقيقة',
        notes: 'نقطة حساسة للزحام، راقب التأخير.',
        order: 2,
      ),
      RouteStation(
        id: 'st-7',
        name: 'عباس العقاد',
        area: 'مدينة نصر',
        arrivalOffset: '٦٥ دقيقة',
        notes: 'نقطة وصول بجوار الشارع الرئيسي.',
        order: 3,
      ),
    ],
    notes: ['ازدحام متكرر بعد ٨ صباحاً'],
  ),
  OperationRouteModel(
    id: 'route-3',
    name: 'بنها - المهندسين',
    startCity: 'بنها',
    endCity: 'المهندسين',
    duration: '٧٠ دقيقة',
    distance: '٦٨ كم',
    tripsCount: 9,
    status: OperationRouteStatus.paused,
    stations: [
      RouteStation(
        id: 'st-8',
        name: 'بنها',
        area: 'القليوبية',
        arrivalOffset: '٠ دقيقة',
        notes: 'تشغيل متوقف مؤقتاً.',
        order: 1,
      ),
      RouteStation(
        id: 'st-9',
        name: 'المؤسسة',
        area: 'شبرا',
        arrivalOffset: '٢٥ دقيقة',
        notes: 'مراجعة الطلب قبل إعادة التشغيل.',
        order: 2,
      ),
      RouteStation(
        id: 'st-10',
        name: 'جامعة الدول',
        area: 'المهندسين',
        arrivalOffset: '٧٠ دقيقة',
        notes: 'نهاية المسار المقترحة.',
        order: 3,
      ),
    ],
    notes: ['متوقف مؤقتاً لمراجعة الطلب'],
  ),
];
