import '../../domain/entities/driver.dart';
import '../models/driver_model.dart';

abstract class DriversDatasource {
  Future<List<DriverModel>> fetchDrivers();
  Future<DriverModel> createDriver(Driver driver);
  Future<DriverModel> updateDriver(Driver driver);
  Future<DriverModel> updateDriverStatus(String driverId, DriverStatus status);
  Future<void> deleteDriver(String driverId);
}

class MockDriversDatasource implements DriversDatasource {
  final List<DriverModel> _drivers = List<DriverModel>.from(_seedDrivers);

  @override
  Future<List<DriverModel>> fetchDrivers() async {
    return List<DriverModel>.unmodifiable(_drivers);
  }

  @override
  Future<DriverModel> createDriver(Driver driver) async {
    final model = DriverModel.fromEntity(
      driver.copyWith(id: 'drv-${_drivers.length + 10}'),
    );
    _drivers.insert(0, model);
    return model;
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    _drivers.removeWhere((driver) => driver.id == driverId);
  }

  @override
  Future<DriverModel> updateDriver(Driver driver) async {
    final index = _drivers.indexWhere((item) => item.id == driver.id);
    if (index == -1) {
      throw ArgumentError('Driver not found');
    }
    final model = DriverModel.fromEntity(driver);
    _drivers[index] = model;
    return model;
  }

  @override
  Future<DriverModel> updateDriverStatus(
    String driverId,
    DriverStatus status,
  ) async {
    final index = _drivers.indexWhere((driver) => driver.id == driverId);
    if (index == -1) {
      throw ArgumentError('Driver not found');
    }
    final updated = DriverModel.fromEntity(
      _drivers[index].copyWith(status: status),
    );
    _drivers[index] = updated;
    return updated;
  }
}

const _documents = [
  DriverDocument(
    title: 'رخصة القيادة',
    number: 'LIC-٢٣٤٥',
    status: 'سارية',
    updatedAt: 'تم التحديث منذ ٣ أيام',
  ),
  DriverDocument(
    title: 'بطاقة الرقم القومي',
    number: 'NID-٤٥٦٧',
    status: 'مراجعة مكتملة',
    updatedAt: 'تم التحديث منذ أسبوع',
  ),
  DriverDocument(
    title: 'فيش جنائي',
    number: 'CR-١١٢٢',
    status: 'ساري',
    updatedAt: 'تم التحديث منذ شهر',
  ),
  DriverDocument(
    title: 'عقد العمل',
    number: 'CON-٨٨١١',
    status: 'موقع',
    updatedAt: 'تم التحديث منذ شهرين',
  ),
];

const _reviews = [
  DriverReview(
    passengerName: 'سارة أحمد',
    rating: 4.8,
    comment: 'السائق ملتزم بالمواعيد والتعامل محترم.',
  ),
  DriverReview(
    passengerName: 'محمود علي',
    rating: 4.5,
    comment: 'الرحلة كانت هادئة ووصلنا في المعاد.',
  ),
  DriverReview(
    passengerName: 'رنا يوسف',
    rating: 4.2,
    comment: 'محتاج يوضح نقطة التجمع بدري شوية.',
  ),
];

const _complaints = [
  DriverComplaint(
    id: 'CMP-١٠٠١',
    passengerName: 'خالد محمود',
    status: 'تحت المراجعة',
    summary: 'تأخير ٨ دقائق عند نقطة التجمع.',
  ),
  DriverComplaint(
    id: 'CMP-١٠٠٢',
    passengerName: 'ياسمين علي',
    status: 'مغلقة',
    summary: 'تم توضيح مسار الرحلة للراكبة.',
  ),
];

const _seedDrivers = [
  DriverModel(
    id: 'drv-1',
    name: 'محمد أحمد',
    phone: '٠١٠١٢٣٤٥٦٧٨',
    nationalId: '٢٩٣٠١١٤٠١٢٣٤٥٦',
    email: 'm.ahmed@bmt.local',
    address: 'بنها - القليوبية',
    avatarInitials: 'م أ',
    currentVehicle: 'أ ب ج ٤٥٦',
    currentRoute: 'بنها - القرية الذكية',
    totalTrips: 342,
    todayTrips: 4,
    monthlyTrips: 78,
    totalPassengers: 3904,
    rating: 4.8,
    status: DriverStatus.active,
    assignedAt: '١٥ مارس ٢٠٢٤',
    licenseNumber: 'ر-٢٣٤٥-ق',
    licenseExpiry: '١٢ ديسمبر ٢٠٢٧',
    documents: _documents,
    reviews: _reviews,
    complaints: _complaints,
    notes: ['مناسب للرحلات الصباحية', 'يفضل مسار القرية الذكية'],
  ),
  DriverModel(
    id: 'drv-2',
    name: 'كريم حسن',
    phone: '٠١٢٣٤٥٦٧٨٩٠',
    nationalId: '٢٨٨٠٧٢٢٠١٢٢٣٣٤',
    email: 'k.hassan@bmt.local',
    address: 'شبرا - القاهرة',
    avatarInitials: 'ك ح',
    currentVehicle: 'س د هـ ٧٨٩',
    currentRoute: 'بنها - مدينة نصر',
    totalTrips: 288,
    todayTrips: 3,
    monthlyTrips: 64,
    totalPassengers: 3050,
    rating: 4.6,
    status: DriverStatus.active,
    assignedAt: '٢ فبراير ٢٠٢٤',
    licenseNumber: 'ر-٩٩١٢-ق',
    licenseExpiry: '٣٠ سبتمبر ٢٠٢٦',
    documents: _documents,
    reviews: _reviews,
    complaints: [],
    notes: ['ملتزم بالمسار', 'تقييمات مستقرة'],
  ),
  DriverModel(
    id: 'drv-3',
    name: 'هاني صلاح',
    phone: '٠١١١٢٢٢٣٣٣٤',
    nationalId: '٢٩٠٠٩١٥٠١٤٤٥٥٦',
    email: 'h.salah@bmt.local',
    address: 'مدينة نصر - القاهرة',
    avatarInitials: 'هـ ص',
    currentVehicle: 'م ن و ٣٣١',
    currentRoute: 'بنها - المهندسين',
    totalTrips: 176,
    todayTrips: 0,
    monthlyTrips: 29,
    totalPassengers: 1810,
    rating: 4.3,
    status: DriverStatus.pendingDocuments,
    assignedAt: '١٠ يناير ٢٠٢٥',
    licenseNumber: 'ر-٤٤٣٣-ق',
    licenseExpiry: '١٨ مايو ٢٠٢٦',
    documents: _documents,
    reviews: _reviews,
    complaints: _complaints,
    notes: ['بانتظار مراجعة مستندات الرخصة'],
  ),
  DriverModel(
    id: 'drv-4',
    name: 'مصطفى علي',
    phone: '٠١٥٥٦٦٦٧٧٧٨',
    nationalId: '٢٨٥١٢٢٠٠١٧٧٨٨٩',
    email: 'm.ali@bmt.local',
    address: 'العبور - القليوبية',
    avatarInitials: 'م ع',
    currentVehicle: 'غير مسند',
    currentRoute: 'غير مسند',
    totalTrips: 98,
    todayTrips: 0,
    monthlyTrips: 12,
    totalPassengers: 940,
    rating: 4.1,
    status: DriverStatus.onLeave,
    assignedAt: '٢٠ أغسطس ٢٠٢٤',
    licenseNumber: 'ر-٥٥١٢-ق',
    licenseExpiry: '٢٢ نوفمبر ٢٠٢٦',
    documents: _documents,
    reviews: _reviews,
    complaints: [],
    notes: ['إجازة أسبوعية حتى الخميس'],
  ),
  DriverModel(
    id: 'drv-5',
    name: 'عمرو نبيل',
    phone: '٠١٠٩٩٨٨٧٧٦٦',
    nationalId: '٢٩٤٠٣١٧٠١٩٩٨٨٧',
    email: 'a.nabil@bmt.local',
    address: 'المعادي - القاهرة',
    avatarInitials: 'ع ن',
    currentVehicle: 'غير مسند',
    currentRoute: 'غير مسند',
    totalTrips: 212,
    todayTrips: 0,
    monthlyTrips: 0,
    totalPassengers: 2260,
    rating: 4.4,
    status: DriverStatus.suspended,
    assignedAt: '١ أبريل ٢٠٢٤',
    licenseNumber: 'ر-٧٧٢١-ق',
    licenseExpiry: '٩ يوليو ٢٠٢٥',
    documents: _documents,
    reviews: _reviews,
    complaints: _complaints,
    notes: ['موقوف مؤقتاً لحين مراجعة التشغيل'],
  ),
];
