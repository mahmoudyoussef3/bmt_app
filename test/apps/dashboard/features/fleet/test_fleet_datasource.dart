import 'package:bmt_app/apps/dashboard/features/fleet/data/datasources/fleet_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/data/models/fleet_models.dart';

class MockFleetDatasource implements FleetDatasource {
  final List<FleetDriverModel> _drivers = _buildDrivers();
  final List<FleetVehicleModel> _vehicles = _buildVehicles();
  final List<FleetAssignmentModel> _assignments = [];
  final List<FleetDocumentModel> _customDocuments = [];

  MockFleetDatasource() {
    for (var index = 0; index < 15; index++) {
      final driverId = _drivers[index].id;
      final vehicleId = _vehicles[index].id;
      _assignments.add(
        FleetAssignmentModel(
          id: 'assign-${index + 1}',
          driverId: driverId,
          vehicleId: vehicleId,
          assignedAt: '١ ${_monthName(index)} ٢٠٢٦',
          status: FleetAssignmentStatus.active,
          history: [
            FleetHistoryItem(
              title: 'تم التعيين',
              date: '١ ${_monthName(index)} ٢٠٢٦',
              description: 'تم ربط السائق بالمركبة بعد مراجعة الوثائق.',
            ),
          ],
        ),
      );
      _drivers[index] = FleetDriverModel.fromEntity(
        _drivers[index].copyWith(currentVehicleId: vehicleId),
      );
      _vehicles[index] = FleetVehicleModel.fromEntity(
        _vehicles[index].copyWith(currentDriverId: driverId),
      );
    }
  }

  @override
  Future<FleetWorkspace> fetchWorkspace() async {
    final builtDocs = _buildDocumentsFrom(_drivers, _vehicles);
    final List<FleetDocument> mergedDocs = [...builtDocs];
    for (final doc in _customDocuments) {
      final idx = mergedDocs.indexWhere((d) => d.ownerId == doc.ownerId && d.type == doc.type);
      if (idx != -1) {
        mergedDocs[idx] = doc;
      } else {
        mergedDocs.add(doc);
      }
    }
    return FleetWorkspace(
      drivers: List<FleetDriver>.unmodifiable(_drivers),
      vehicles: List<FleetVehicle>.unmodifiable(_vehicles),
      assignments: List<FleetAssignment>.unmodifiable(_assignments),
      documents: List<FleetDocument>.unmodifiable(mergedDocs),
    );
  }

  @override
  Future<FleetDriverModel> createDriver(FleetDriver driver) async {
    _validateDriver(driver);
    final driverId = 'driver-${_drivers.length + 1}';
    final model = FleetDriverModel.fromEntity(
      driver.copyWith(
        id: driverId,
        status: FleetDriverStatus.active,
        currentVehicleId: '',
      ),
    );
    _drivers.insert(0, model);

    if (driver.currentVehicleId.isNotEmpty) {
      await _handleVehicleAssignmentChange(driverId, driver.currentVehicleId);
    }

    return _drivers.firstWhere((d) => d.id == driverId);
  }

  @override
  Future<FleetDriverModel> updateDriver(FleetDriver driver) async {
    _validateDriver(driver);
    final index = _drivers.indexWhere((item) => item.id == driver.id);
    if (index == -1) throw ArgumentError('Driver not found');
    
    await _handleVehicleAssignmentChange(driver.id, driver.currentVehicleId);
    
    final latestVehicleId = _drivers[index].currentVehicleId;
    final model = FleetDriverModel.fromEntity(driver.copyWith(currentVehicleId: latestVehicleId));
    _drivers[index] = model;
    return model;
  }

  @override
  Future<FleetDriverModel> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  ) async {
    final index = _drivers.indexWhere((item) => item.id == driverId);
    if (index == -1) throw ArgumentError('Driver not found');
    final updated = _drivers[index].copyWith(status: status);
    _drivers[index] = FleetDriverModel.fromEntity(updated);
    if (status == FleetDriverStatus.archived ||
        status == FleetDriverStatus.suspended) {
      final active = _activeAssignmentForDriver(driverId);
      if (active != null) await removeAssignment(active.id);
    }
    return _drivers[index];
  }

  @override
  Future<FleetVehicleModel> createVehicle(FleetVehicle vehicle) async {
    _validateVehicle(vehicle);
    final vehicleId = 'vehicle-${_vehicles.length + 1}';
    final model = FleetVehicleModel.fromEntity(
      vehicle.copyWith(
        id: vehicleId,
        status: FleetVehicleStatus.active,
        currentDriverId: '',
        images: vehicle.images.isEmpty
            ? _vehicleImages(vehicle.vehicleCode)
            : vehicle.images,
      ),
    );
    _vehicles.insert(0, model);

    if (vehicle.currentDriverId.isNotEmpty) {
      await _handleDriverAssignmentChange(vehicleId, vehicle.currentDriverId);
    }

    return _vehicles.firstWhere((v) => v.id == vehicleId);
  }

  @override
  Future<FleetVehicleModel> updateVehicle(FleetVehicle vehicle) async {
    _validateVehicle(vehicle);
    final index = _vehicles.indexWhere((item) => item.id == vehicle.id);
    if (index == -1) throw ArgumentError('Vehicle not found');
    
    await _handleDriverAssignmentChange(vehicle.id, vehicle.currentDriverId);
    
    final latestDriverId = _vehicles[index].currentDriverId;
    final model = FleetVehicleModel.fromEntity(vehicle.copyWith(currentDriverId: latestDriverId));
    _vehicles[index] = model;
    return model;
  }

  @override
  Future<FleetVehicleModel> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  ) async {
    final index = _vehicles.indexWhere((item) => item.id == vehicleId);
    if (index == -1) throw ArgumentError('Vehicle not found');
    final updated = _vehicles[index].copyWith(status: status);
    _vehicles[index] = FleetVehicleModel.fromEntity(updated);
    if (status != FleetVehicleStatus.active) {
      final active = _activeAssignmentForVehicle(vehicleId);
      if (active != null) await removeAssignment(active.id);
    }
    return _vehicles[index];
  }

  @override
  Future<FleetAssignmentModel> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  ) async {
    _ensureAssignable(driverId, vehicleId);
    final assignment = FleetAssignmentModel(
      id: 'assign-${_assignments.length + 1}',
      driverId: driverId,
      vehicleId: vehicleId,
      assignedAt: '٨ يونيو ٢٠٢٦',
      status: FleetAssignmentStatus.active,
      history: const [
        FleetHistoryItem(
          title: 'تم إنشاء التعيين',
          date: '٨ يونيو ٢٠٢٦',
          description:
              'تم التحقق من أن السائق والمركبة غير مرتبطين بتعيين آخر.',
        ),
      ],
    );
    _assignments.insert(0, assignment);
    _link(driverId, vehicleId);
    return assignment;
  }

  @override
  Future<FleetAssignmentModel> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  ) async {
    final index = _assignments.indexWhere((item) => item.id == assignmentId);
    if (index == -1) throw ArgumentError('Assignment not found');
    final current = _assignments[index];
    if (_activeAssignmentForVehicle(newVehicleId) != null) {
      throw ArgumentError('Vehicle already assigned');
    }
    final oldVehicleId = current.vehicleId;
    final updated = FleetAssignmentModel.fromEntity(
      current.copyWith(
        vehicleId: newVehicleId,
        history: [
          ...current.history,
          FleetHistoryItem(
            title: 'تغيير المركبة',
            date: '٨ يونيو ٢٠٢٦',
            description: 'تم تغيير المركبة من $oldVehicleId إلى $newVehicleId.',
          ),
        ],
      ),
    );
    _assignments[index] = updated;
    _unlinkVehicle(oldVehicleId);
    _link(current.driverId, newVehicleId);
    return updated;
  }

  @override
  Future<FleetAssignmentModel> removeAssignment(String assignmentId) async {
    final index = _assignments.indexWhere((item) => item.id == assignmentId);
    if (index == -1) throw ArgumentError('Assignment not found');
    final current = _assignments[index];
    final updated = FleetAssignmentModel.fromEntity(
      current.copyWith(
        status: FleetAssignmentStatus.ended,
        history: [
          ...current.history,
          const FleetHistoryItem(
            title: 'فك التعيين',
            date: '٨ يونيو ٢٠٢٦',
            description: 'تم فك التعيين وحفظ السجل التشغيلي.',
          ),
        ],
      ),
    );
    _assignments[index] = updated;
    _unlinkDriver(current.driverId);
    _unlinkVehicle(current.vehicleId);
    return updated;
  }

  @override
  Future<FleetDocumentModel> createDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    final doc = FleetDocumentModel(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      ownerId: ownerId,
      ownerName: isDriver ? 'سائق' : 'مركبة',
      referenceNumber: 'REF-MOCK',
      expiryDate: expiryDate,
      status: status,
      fileUrl: fileUrl,
    );
    if (isDriver) {
      final index = _drivers.indexWhere((d) => d.id == ownerId);
      if (index != -1) {
        final current = _drivers[index];
        _drivers[index] = FleetDriverModel.fromEntity(
          current.copyWith(documents: [...current.documents, doc]),
        );
      }
    } else {
      final index = _vehicles.indexWhere((v) => v.id == ownerId);
      if (index != -1) {
        final current = _vehicles[index];
        _vehicles[index] = FleetVehicleModel.fromEntity(
          current.copyWith(
            licenseExpiry: type == FleetDocumentType.vehicleLicense ? expiryDate : current.licenseExpiry,
            insuranceExpiry: type == FleetDocumentType.insurance ? expiryDate : current.insuranceExpiry,
            inspectionExpiry: type == FleetDocumentType.inspection ? expiryDate : current.inspectionExpiry,
          ),
        );
        final docWithReference = FleetDocumentModel(
          id: doc.id,
          type: doc.type,
          ownerId: doc.ownerId,
          ownerName: current.vehicleCode,
          referenceNumber: current.plateNumber,
          expiryDate: doc.expiryDate,
          status: doc.status,
          fileUrl: doc.fileUrl,
        );
        final existingIdx = _customDocuments.indexWhere((d) => d.ownerId == ownerId && d.type == type);
        if (existingIdx != -1) {
          _customDocuments[existingIdx] = docWithReference;
        } else {
          _customDocuments.add(docWithReference);
        }
      }
    }
    return doc;
  }

  @override
  Future<FleetDocumentModel> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    if (isDriver) {
      for (var i = 0; i < _drivers.length; i++) {
        final driver = _drivers[i];
        final docIndex = driver.documents.indexWhere((d) => d.id == documentId);
        if (docIndex != -1) {
          final oldDoc = driver.documents[docIndex];
          final updatedDoc = FleetDocumentModel(
            id: documentId,
            type: oldDoc.type,
            ownerId: oldDoc.ownerId,
            ownerName: oldDoc.ownerName,
            referenceNumber: oldDoc.referenceNumber,
            expiryDate: expiryDate,
            status: status,
            fileUrl: fileUrl,
          );
          final nextDocs = [...driver.documents];
          nextDocs[docIndex] = updatedDoc;
          _drivers[i] = FleetDriverModel.fromEntity(driver.copyWith(documents: nextDocs));
          return updatedDoc;
        }
      }
    } else {
      // Find which vehicle and type
      String vehicleId = '';
      FleetDocumentType type = FleetDocumentType.other;
      if (documentId.startsWith('doc-license-')) {
        vehicleId = documentId.replaceFirst('doc-license-', '');
        type = FleetDocumentType.vehicleLicense;
      } else if (documentId.startsWith('doc-insurance-')) {
        vehicleId = documentId.replaceFirst('doc-insurance-', '');
        type = FleetDocumentType.insurance;
      } else if (documentId.startsWith('doc-inspection-')) {
        vehicleId = documentId.replaceFirst('doc-inspection-', '');
        type = FleetDocumentType.inspection;
      }

      if (vehicleId.isNotEmpty) {
        final index = _vehicles.indexWhere((v) => v.id == vehicleId);
        if (index != -1) {
          final current = _vehicles[index];
          _vehicles[index] = FleetVehicleModel.fromEntity(
            current.copyWith(
              licenseExpiry: type == FleetDocumentType.vehicleLicense ? expiryDate : current.licenseExpiry,
              insuranceExpiry: type == FleetDocumentType.insurance ? expiryDate : current.insuranceExpiry,
              inspectionExpiry: type == FleetDocumentType.inspection ? expiryDate : current.inspectionExpiry,
            ),
          );
          final updatedDoc = FleetDocumentModel(
            id: documentId,
            type: type,
            ownerId: vehicleId,
            ownerName: current.vehicleCode,
            referenceNumber: current.plateNumber,
            expiryDate: expiryDate,
            status: status,
            fileUrl: fileUrl,
          );
          final existingIdx = _customDocuments.indexWhere((d) => d.ownerId == vehicleId && d.type == type);
          if (existingIdx != -1) {
            _customDocuments[existingIdx] = updatedDoc;
          } else {
            _customDocuments.add(updatedDoc);
          }
          return updatedDoc;
        }
      }
    }

    return FleetDocumentModel(
      id: documentId,
      type: FleetDocumentType.other,
      ownerId: '',
      ownerName: 'معدل',
      referenceNumber: 'REF-MOCK',
      expiryDate: expiryDate,
      status: status,
      fileUrl: fileUrl,
    );
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    if (isDriver) {
      for (var i = 0; i < _drivers.length; i++) {
        final driver = _drivers[i];
        final docIndex = driver.documents.indexWhere((d) => d.id == documentId);
        if (docIndex != -1) {
          final nextDocs = [...driver.documents]..removeAt(docIndex);
          _drivers[i] = FleetDriverModel.fromEntity(driver.copyWith(documents: nextDocs));
          break;
        }
      }
    } else {
      String vehicleId = '';
      FleetDocumentType type = FleetDocumentType.other;
      if (documentId.startsWith('doc-license-')) {
        vehicleId = documentId.replaceFirst('doc-license-', '');
        type = FleetDocumentType.vehicleLicense;
      } else if (documentId.startsWith('doc-insurance-')) {
        vehicleId = documentId.replaceFirst('doc-insurance-', '');
        type = FleetDocumentType.insurance;
      } else if (documentId.startsWith('doc-inspection-')) {
        vehicleId = documentId.replaceFirst('doc-inspection-', '');
        type = FleetDocumentType.inspection;
      }

      if (vehicleId.isNotEmpty) {
        final index = _vehicles.indexWhere((v) => v.id == vehicleId);
        if (index != -1) {
          final current = _vehicles[index];
          _vehicles[index] = FleetVehicleModel.fromEntity(
            current.copyWith(
              licenseExpiry: type == FleetDocumentType.vehicleLicense ? '' : current.licenseExpiry,
              insuranceExpiry: type == FleetDocumentType.insurance ? '' : current.insuranceExpiry,
              inspectionExpiry: type == FleetDocumentType.inspection ? '' : current.inspectionExpiry,
            ),
          );
          _customDocuments.removeWhere((d) => d.ownerId == vehicleId && d.type == type);
        }
      }
    }
  }

  void _ensureAssignable(String driverId, String vehicleId) {
    final driver = _drivers.firstWhere((item) => item.id == driverId);
    final vehicle = _vehicles.firstWhere((item) => item.id == vehicleId);
    if (driver.status != FleetDriverStatus.active) {
      throw ArgumentError('Driver is not active');
    }
    if (vehicle.status != FleetVehicleStatus.active) {
      throw ArgumentError('Vehicle is not active');
    }
    if (_activeAssignmentForDriver(driverId) != null) {
      throw ArgumentError('Driver already assigned');
    }
    if (_activeAssignmentForVehicle(vehicleId) != null) {
      throw ArgumentError('Vehicle already assigned');
    }
  }

  FleetAssignmentModel? _activeAssignmentForDriver(String driverId) {
    return _assignments.cast<FleetAssignmentModel?>().firstWhere(
      (item) =>
          item?.driverId == driverId &&
          item?.status == FleetAssignmentStatus.active,
      orElse: () => null,
    );
  }

  FleetAssignmentModel? _activeAssignmentForVehicle(String vehicleId) {
    return _assignments.cast<FleetAssignmentModel?>().firstWhere(
      (item) =>
          item?.vehicleId == vehicleId &&
          item?.status == FleetAssignmentStatus.active,
      orElse: () => null,
    );
  }

  void _link(String driverId, String vehicleId) {
    final driverIndex = _drivers.indexWhere((item) => item.id == driverId);
    final vehicleIndex = _vehicles.indexWhere((item) => item.id == vehicleId);
    _drivers[driverIndex] = FleetDriverModel.fromEntity(
      _drivers[driverIndex].copyWith(currentVehicleId: vehicleId),
    );
    _vehicles[vehicleIndex] = FleetVehicleModel.fromEntity(
      _vehicles[vehicleIndex].copyWith(currentDriverId: driverId),
    );
  }

  void _unlinkDriver(String driverId) {
    final index = _drivers.indexWhere((item) => item.id == driverId);
    if (index == -1) return;
    _drivers[index] = FleetDriverModel.fromEntity(
      _drivers[index].copyWith(clearCurrentVehicle: true),
    );
  }

  void _unlinkVehicle(String vehicleId) {
    final index = _vehicles.indexWhere((item) => item.id == vehicleId);
    if (index == -1) return;
    _vehicles[index] = FleetVehicleModel.fromEntity(
      _vehicles[index].copyWith(clearCurrentDriver: true),
    );
  }

  Future<void> _handleVehicleAssignmentChange(String driverId, String newVehicleId) async {
    final currentDriver = _drivers.firstWhere((d) => d.id == driverId);
    final oldVehicleId = currentDriver.currentVehicleId;

    if (oldVehicleId == newVehicleId) return;

    if (oldVehicleId.isNotEmpty) {
      final activeAssign = _activeAssignmentForDriver(driverId);
      if (activeAssign != null) {
        await removeAssignment(activeAssign.id);
      }
    }

    if (newVehicleId.isNotEmpty) {
      final activeAssignForNewVehicle = _activeAssignmentForVehicle(newVehicleId);
      if (activeAssignForNewVehicle != null) {
        await removeAssignment(activeAssignForNewVehicle.id);
      }
      await assignDriverToVehicle(driverId, newVehicleId);
    }
  }

  Future<void> _handleDriverAssignmentChange(String vehicleId, String newDriverId) async {
    final currentVehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    final oldDriverId = currentVehicle.currentDriverId;

    if (oldDriverId == newDriverId) return;

    if (oldDriverId.isNotEmpty) {
      final activeAssign = _activeAssignmentForVehicle(vehicleId);
      if (activeAssign != null) {
        await removeAssignment(activeAssign.id);
      }
    }

    if (newDriverId.isNotEmpty) {
      final activeAssignForNewDriver = _activeAssignmentForDriver(newDriverId);
      if (activeAssignForNewDriver != null) {
        await removeAssignment(activeAssignForNewDriver.id);
      }
      await assignDriverToVehicle(newDriverId, vehicleId);
    }
  }

  void _validateDriver(FleetDriver driver) {
    if (driver.fullName.trim().isEmpty ||
        driver.phone.trim().isEmpty ||
        driver.nationalId.trim().isEmpty ||
        driver.licenseNumber.trim().isEmpty) {
      throw ArgumentError('Driver data is incomplete');
    }
  }

  void _validateVehicle(FleetVehicle vehicle) {
    if (vehicle.vehicleCode.trim().isEmpty ||
        vehicle.plateNumber.trim().isEmpty ||
        vehicle.model.trim().isEmpty ||
        vehicle.capacity <= 0) {
      throw ArgumentError('Vehicle data is incomplete');
    }
  }
}

List<FleetDriverModel> _buildDrivers() {
  final names = [
    'أحمد عبد الرازق',
    'مصطفى سمير',
    'كريم فتحي',
    'محمد سامي',
    'حسن عادل',
    'طارق محمود',
    'وليد نبيل',
    'إسلام حسين',
    'محمود فتح الله',
    'علي منصور',
    'أشرف كمال',
    'رامي فؤاد',
    'ياسر عبد الحميد',
    'خالد مراد',
    'شريف عاطف',
    'عمرو عبد السلام',
    'أيمن جمال',
    'سعيد فوزي',
    'هاني سليمان',
    'عبد الله ناصر',
    'ماهر إبراهيم',
    'مينا سمير',
    'صلاح يوسف',
    'أحمد عزت',
    'كامل شوقي',
  ];
  return names.indexed.map((entry) {
    final (index, name) = entry;
    final expiring = index % 7 == 0;
    final expired = index % 13 == 0;
    final licExpiry = expired
        ? '١ مايو ٢٠٢٦'
        : expiring
        ? '١٨ يونيو ٢٠٢٦'
        : '${10 + index % 18} ديسمبر ٢٠٢٦';
    return FleetDriverModel(
      id: 'driver-${index + 1}',
      employeeCode: 'EMP-${1000 + index}',
      fullName: name,
      phone: '010${(22334455 + index * 731).toString()}',
      emergencyPhone: '012${(44770000 + index * 421).toString()}',
      address: 'شارع ${index + 12}، القاهرة الكبرى',
      nationalId: '29${800000000000 + index * 91017}',
      profileImageUrl: '',
      licenseNumber: 'د-${(60000 + index * 137)}',
      licenseExpiryDate: licExpiry,
      hireDate: '2024-01-01',
      notes: '',
      status: index == 18
          ? FleetDriverStatus.suspended
          : FleetDriverStatus.active,
      tripHistory: _history('رحلة مكتملة', 4),
      violations: index % 6 == 0 ? _history('مخالفة سرعة', 1) : const [],
      documents: [
        FleetDocument(
          id: 'doc-driver-${index + 1}',
          type: FleetDocumentType.driverLicense,
          ownerId: 'driver-${index + 1}',
          ownerName: name,
          referenceNumber: 'د-${(60000 + index * 137)}',
          expiryDate: licExpiry,
          status: expired
              ? FleetDocumentStatus.expired
              : expiring
              ? FleetDocumentStatus.expiringSoon
              : FleetDocumentStatus.valid,
        ),
      ],
      activityTimeline: _history('تحديث ملف السائق', 4),
    );
  }).toList();
}

List<FleetVehicleModel> _buildVehicles() {
  final models = [
    'تويوتا كوستر',
    'مرسيدس سبرنتر',
    'تويوتا هايس',
    'هيونداي H1',
    'ميتسوبيشي روزا',
  ];
  return List.generate(15, (index) {
    final vehicleNumber = 'مركبة ${index + 101}';
    final expiring = index % 5 == 0;
    final expired = index % 11 == 0;
    final capacityVal = [12, 14, 19, 28][index % 4];
    final modelName = models[index % models.length];
    final brandVal = modelName.split(' ')[0];
    final licExpiry = expired
        ? '٣٠ أبريل ٢٠٢٦'
        : expiring
        ? '٢٠ يونيو ٢٠٢٦'
        : '${8 + index} نوفمبر ٢٠٢٦';
    final insExpiry = expiring ? '٢٢ يونيو ٢٠٢٦' : '${9 + index} يناير ٢٠٢٧';
    final inspExpiry = expired ? '٢٨ أبريل ٢٠٢٦' : '${5 + index} فبراير ٢٠٢٧';
    return FleetVehicleModel(
      id: 'vehicle-${index + 1}',
      vehicleCode: vehicleNumber,
      plateNumber: '${3300 + index * 17} ق ل',
      vehicleType: 'ميني باص',
      brand: brandVal,
      model: modelName,
      manufactureYear: 2018 + (index % 7),
      color: 'أبيض',
      capacity: capacityVal,
      seatLayoutType: 'standard',
      imageUrl: '',
      notes: '',
      status: index == 12
          ? FleetVehicleStatus.maintenance
          : FleetVehicleStatus.active,
      seatConfiguration: SeatConfiguration.generateDefault(capacityVal),
      licenseExpiry: licExpiry,
      insuranceExpiry: insExpiry,
      inspectionExpiry: inspExpiry,
      images: _vehicleImages(vehicleNumber),
      previousDrivers: _history('سائق سابق', 3),
      tripHistory: _history('رحلة تشغيل', 4),
      timeline: _history('فحص وتشغيل', 4),
    );
  });
}

List<FleetDocument> _buildDocumentsFrom(
  List<FleetDriver> driversSource,
  List<FleetVehicle> vehiclesSource,
) {
  final drivers = driversSource.expand((driver) => driver.documents);
  final vehicles = vehiclesSource.expand((vehicle) {
    return [
      FleetDocument(
        id: 'doc-license-${vehicle.id}',
        type: FleetDocumentType.vehicleLicense,
        ownerId: vehicle.id,
        ownerName: vehicle.vehicleCode,
        referenceNumber: vehicle.plateNumber,
        expiryDate: vehicle.licenseExpiry,
        status: _documentStatus(vehicle.licenseExpiry),
      ),
      FleetDocument(
        id: 'doc-insurance-${vehicle.id}',
        type: FleetDocumentType.insurance,
        ownerId: vehicle.id,
        ownerName: vehicle.vehicleCode,
        referenceNumber: 'تأمين-${vehicle.plateNumber}',
        expiryDate: vehicle.insuranceExpiry,
        status: _documentStatus(vehicle.insuranceExpiry),
      ),
      FleetDocument(
        id: 'doc-inspection-${vehicle.id}',
        type: FleetDocumentType.inspection,
        ownerId: vehicle.id,
        ownerName: vehicle.vehicleCode,
        referenceNumber: 'فحص-${vehicle.plateNumber}',
        expiryDate: vehicle.inspectionExpiry,
        status: _documentStatus(vehicle.inspectionExpiry),
      ),
    ];
  });
  return [...drivers, ...vehicles];
}

FleetDocumentStatus _documentStatus(String expiry) {
  if (expiry.contains('أبريل') || expiry.contains('مايو')) {
    return FleetDocumentStatus.expired;
  }
  if (expiry.contains('يونيو')) return FleetDocumentStatus.expiringSoon;
  return FleetDocumentStatus.valid;
}

List<FleetVehicleImage> _vehicleImages(String vehicleNumber) {
  return [
    FleetVehicleImage(label: 'أمام', description: '$vehicleNumber من الأمام'),
    FleetVehicleImage(label: 'خلف', description: '$vehicleNumber من الخلف'),
    FleetVehicleImage(
      label: 'يسار',
      description: '$vehicleNumber من الجانب الأيسر',
    ),
    FleetVehicleImage(
      label: 'يمين',
      description: '$vehicleNumber من الجانب الأيمن',
    ),
    FleetVehicleImage(
      label: 'الداخل',
      description: 'صالون $vehicleNumber وعدد المقاعد',
    ),
  ];
}

List<FleetHistoryItem> _history(String title, int count) {
  return List.generate(
    count,
    (index) => FleetHistoryItem(
      title: title,
      date: '${index + 2} يونيو ٢٠٢٦',
      description: '$title رقم ${index + 1} تم تسجيله من فريق التشغيل.',
    ),
  );
}



String _monthName(int index) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يناير',
    'فبراير',
    'مارس',
  ];
  return months[index % months.length];
}
