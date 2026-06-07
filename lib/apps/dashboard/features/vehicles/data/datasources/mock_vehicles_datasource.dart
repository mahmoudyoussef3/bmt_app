import '../../domain/entities/vehicle.dart';
import '../models/vehicle_model.dart';

abstract class VehiclesDatasource {
  Future<List<VehicleModel>> fetchVehicles();
  Future<VehicleModel> createVehicle(Vehicle vehicle);
  Future<VehicleModel> updateVehicle(Vehicle vehicle);
  Future<VehicleModel> updateVehicleStatus(
    String vehicleId,
    VehicleStatus status,
  );
  Future<VehicleModel> renewDocument(String vehicleId, String documentTitle);
}

class MockVehiclesDatasource implements VehiclesDatasource {
  final List<VehicleModel> _vehicles = List<VehicleModel>.from(_seedVehicles);

  @override
  Future<List<VehicleModel>> fetchVehicles() async {
    return List<VehicleModel>.unmodifiable(_vehicles);
  }

  @override
  Future<VehicleModel> createVehicle(Vehicle vehicle) async {
    final model = VehicleModel.fromEntity(
      vehicle.copyWith(id: 'veh-${_vehicles.length + 10}'),
    );
    _vehicles.insert(0, model);
    return model;
  }

  @override
  Future<VehicleModel> updateVehicle(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((item) => item.id == vehicle.id);
    if (index == -1) throw ArgumentError('Vehicle not found');
    final model = VehicleModel.fromEntity(vehicle);
    _vehicles[index] = model;
    return model;
  }

  @override
  Future<VehicleModel> updateVehicleStatus(
    String vehicleId,
    VehicleStatus status,
  ) async {
    final index = _vehicles.indexWhere((item) => item.id == vehicleId);
    if (index == -1) throw ArgumentError('Vehicle not found');
    final model = VehicleModel.fromEntity(
      _vehicles[index].copyWith(status: status),
    );
    _vehicles[index] = model;
    return model;
  }

  @override
  Future<VehicleModel> renewDocument(
    String vehicleId,
    String documentTitle,
  ) async {
    final index = _vehicles.indexWhere((item) => item.id == vehicleId);
    if (index == -1) throw ArgumentError('Vehicle not found');
    final vehicle = _vehicles[index];
    final documents = vehicle.documents.map((document) {
      if (document.title != documentTitle) return document;
      return VehicleDocument(
        title: document.title,
        number: document.number,
        expirationDate: '٣١ ديسمبر ٢٠٢٧',
        previewLabel: document.previewLabel,
        expired: false,
      );
    }).toList();
    final model = VehicleModel.fromEntity(
      vehicle.copyWith(documents: documents),
    );
    _vehicles[index] = model;
    return model;
  }
}

const _documents = [
  VehicleDocument(
    title: 'رخصة المركبة',
    number: 'LIC-٤٥٦',
    expirationDate: '٣١ ديسمبر ٢٠٢٦',
    previewLabel: 'صورة الرخصة',
    expired: false,
  ),
  VehicleDocument(
    title: 'التأمين',
    number: 'INS-٧٨٩',
    expirationDate: '١٥ أكتوبر ٢٠٢٦',
    previewLabel: 'وثيقة التأمين',
    expired: false,
  ),
  VehicleDocument(
    title: 'الفحص الفني',
    number: 'CHK-٢٢٠',
    expirationDate: '٢٨ يونيو ٢٠٢٦',
    previewLabel: 'تقرير الفحص',
    expired: false,
  ),
];

const _expiredDocuments = [
  VehicleDocument(
    title: 'رخصة المركبة',
    number: 'LIC-٣٣١',
    expirationDate: 'منتهية منذ ٤ أيام',
    previewLabel: 'صورة الرخصة',
    expired: true,
  ),
  VehicleDocument(
    title: 'التأمين',
    number: 'INS-٣٣١',
    expirationDate: '١٨ أغسطس ٢٠٢٦',
    previewLabel: 'وثيقة التأمين',
    expired: false,
  ),
  VehicleDocument(
    title: 'الفحص الفني',
    number: 'CHK-٣٣١',
    expirationDate: 'قادم خلال أسبوع',
    previewLabel: 'تقرير الفحص',
    expired: false,
  ),
];

const _maintenance = [
  VehicleMaintenance(
    title: 'تغيير زيت وفلاتر',
    date: '١٢ مايو ٢٠٢٦',
    status: 'مكتملة',
    notes: 'تمت في مركز الصيانة الرئيسي.',
  ),
  VehicleMaintenance(
    title: 'مراجعة فرامل',
    date: '٢١ يونيو ٢٠٢٦',
    status: 'موعد قادم',
    notes: 'مطلوب قبل رحلات الذروة.',
  ),
  VehicleMaintenance(
    title: 'فحص تكييف',
    date: '٢٨ يونيو ٢٠٢٦',
    status: 'مجدولة',
    notes: 'متابعة راحة الركاب في الصيف.',
  ),
];

const _trips = [
  VehicleTrip(
    tripNumber: '٢٢١',
    route: 'بنها - مدينة نصر',
    driver: 'كريم حسن',
    status: 'في الطريق',
  ),
  VehicleTrip(
    tripNumber: '٢٢٤',
    route: 'بنها - القرية الذكية',
    driver: 'محمد أحمد',
    status: 'مكتملة',
  ),
];

const _seedVehicles = [
  VehicleModel(
    id: 'veh-1',
    plateNumber: 'أ ب ج ٤٥٦',
    type: 'ميني باص',
    model: 'تويوتا كوستر ٢٠٢٣',
    capacity: 12,
    status: VehicleStatus.active,
    currentDriver: 'محمد أحمد',
    currentRoute: 'بنها - القرية الذكية',
    licenseExpiry: '٣١ ديسمبر ٢٠٢٦',
    insuranceExpiry: '١٥ أكتوبر ٢٠٢٦',
    inspectionExpiry: '٢٨ يونيو ٢٠٢٦',
    imageLabel: 'مركبة تشغيل',
    documents: _documents,
    maintenance: _maintenance,
    trips: _trips,
    previousDrivers: ['مصطفى علي', 'عمرو نبيل'],
    notes: ['جاهزة لرحلات الصباح', 'استهلاك وقود مستقر'],
  ),
  VehicleModel(
    id: 'veh-2',
    plateNumber: 'س د هـ ٧٨٩',
    type: 'فان',
    model: 'هيونداي H1 ٢٠٢٢',
    capacity: 8,
    status: VehicleStatus.active,
    currentDriver: 'كريم حسن',
    currentRoute: 'بنها - مدينة نصر',
    licenseExpiry: '٢٢ نوفمبر ٢٠٢٦',
    insuranceExpiry: '٣٠ سبتمبر ٢٠٢٦',
    inspectionExpiry: '١٢ يوليو ٢٠٢٦',
    imageLabel: 'فان رحلات',
    documents: _documents,
    maintenance: _maintenance,
    trips: _trips,
    previousDrivers: ['محمد أحمد'],
    notes: ['مناسبة للمسارات القصيرة'],
  ),
  VehicleModel(
    id: 'veh-3',
    plateNumber: 'م ن و ٣٣١',
    type: 'ميني باص',
    model: 'مرسيدس سبرنتر ٢٠٢١',
    capacity: 14,
    status: VehicleStatus.maintenance,
    currentDriver: 'غير مسند',
    currentRoute: 'غير مسند',
    licenseExpiry: 'منتهية منذ ٤ أيام',
    insuranceExpiry: '١٨ أغسطس ٢٠٢٦',
    inspectionExpiry: 'قادم خلال أسبوع',
    imageLabel: 'صيانة',
    documents: _expiredDocuments,
    maintenance: _maintenance,
    trips: [],
    previousDrivers: ['هاني صلاح', 'مصطفى علي'],
    notes: ['مراجعة فرامل قبل العودة للتشغيل'],
  ),
  VehicleModel(
    id: 'veh-4',
    plateNumber: 'ر ز ط ١٢٣',
    type: 'فان',
    model: 'كيا كارنيفال ٢٠٢٤',
    capacity: 7,
    status: VehicleStatus.pendingAssignment,
    currentDriver: 'بانتظار التعيين',
    currentRoute: 'بانتظار التعيين',
    licenseExpiry: '١ يناير ٢٠٢٧',
    insuranceExpiry: '١ يناير ٢٠٢٧',
    inspectionExpiry: '١ يناير ٢٠٢٧',
    imageLabel: 'مركبة جديدة',
    documents: _documents,
    maintenance: [],
    trips: [],
    previousDrivers: [],
    notes: ['مركبة جديدة جاهزة للتعيين'],
  ),
  VehicleModel(
    id: 'veh-5',
    plateNumber: 'ق ل م ٨٨٠',
    type: 'ميني باص',
    model: 'تويوتا هايace ٢٠٢٠',
    capacity: 11,
    status: VehicleStatus.outOfService,
    currentDriver: 'غير مسند',
    currentRoute: 'غير مسند',
    licenseExpiry: '١٠ أبريل ٢٠٢٦',
    insuranceExpiry: 'منتهي',
    inspectionExpiry: 'منتهي',
    imageLabel: 'خارج الخدمة',
    documents: _expiredDocuments,
    maintenance: _maintenance,
    trips: [],
    previousDrivers: ['عمرو نبيل'],
    notes: ['خارج الخدمة لحين قرار الإدارة'],
  ),
];
