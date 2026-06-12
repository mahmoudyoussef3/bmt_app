
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/domain/entities/fleet_workspace.dart';
import '../models/fleet_models.dart';
import 'fleet_datasource.dart';

/// Real Supabase datasource only.
///
/// Important:
/// - No fake data.
/// - No local fallback.
/// - Any Supabase/database error is thrown clearly so you can fix the real issue.
/// - Payloads are filtered to match the current Supabase tables.
class SupabaseFleetDatasource implements FleetDatasource {
  SupabaseFleetDatasource(this._client);

  final SupabaseClient _client;

  static const Set<String> _driverColumns = {
    'employee_code',
    'full_name',
    'phone',
    'emergency_phone',
    'address',
    'national_id',
    'profile_image_url',
    'license_number',
    'license_expiry_date',
    'hire_date',
    'notes',
    'status',
    'updated_at',
  };

  static const Set<String> _vehicleColumns = {
    'vehicle_code',
    'plate_number',
    'vehicle_type',
    'brand',
    'model',
    'manufacture_year',
    'color',
    'capacity',
    'seat_layout_type',
    'image_url',
    'notes',
    'status',
    'seat_configuration',
    'updated_at',
  };

  @override
  Future<FleetWorkspace> fetchWorkspace() async {
    try {
      debugPrint('[SupabaseFleetDatasource] Loading real fleet workspace...');

      final driversData = await _client
          .from('drivers')
          .select()
          .neq('status', 'archived')
          .order('full_name');

      final vehiclesData = await _client
          .from('vehicles')
          .select()
          .neq('status', 'archived')
          .order('vehicle_code');

      final assignmentsData = await _client
          .from('assignments')
          .select()
          .order('assigned_at', ascending: false);

      final driverDocsData = await _client.from('driver_documents').select();

      final vehicleDocsData = await _client.from('vehicle_documents').select();

      final assignments = assignmentsData
          .map<FleetAssignmentModel>(
            (json) => FleetAssignmentModel.fromJson(json),
          )
          .toList();

      final activeDriverAssignments = <String, FleetAssignmentModel>{};
      final activeVehicleAssignments = <String, FleetAssignmentModel>{};

      for (final assignment in assignments) {
        if (assignment.status == FleetAssignmentStatus.active) {
          activeDriverAssignments[assignment.driverId] = assignment;
          activeVehicleAssignments[assignment.vehicleId] = assignment;
        }
      }

      final driverNames = <String, String>{};
      for (final json in driversData) {
        driverNames[json['id'] as String] = (json['full_name'] ?? '') as String;
      }

      final vehicleCodes = <String, String>{};
      for (final json in vehiclesData) {
        vehicleCodes[json['id'] as String] =
            (json['vehicle_code'] ?? '') as String;
      }

      final driverDocs = driverDocsData.map<FleetDocumentModel>((json) {
        final driverId = json['driver_id'] as String? ?? '';
        return FleetDocumentModel.fromJson(
          json,
          ownerName: driverNames[driverId] ?? '',
        );
      }).toList();

      final vehicleDocs = vehicleDocsData.map<FleetDocumentModel>((json) {
        final vehicleId = json['vehicle_id'] as String? ?? '';
        return FleetDocumentModel.fromJson(
          json,
          ownerName: vehicleCodes[vehicleId] ?? '',
        );
      }).toList();

      final docsByDriverId = <String, List<FleetDocumentModel>>{};
      for (final doc in driverDocs) {
        docsByDriverId.putIfAbsent(doc.ownerId, () => []).add(doc);
      }

      final docsByVehicleId = <String, List<FleetDocumentModel>>{};
      for (final doc in vehicleDocs) {
        docsByVehicleId.putIfAbsent(doc.ownerId, () => []).add(doc);
      }

      final drivers = driversData.map<FleetDriver>((json) {
        final driverId = json['id'] as String;
        final activeAssign = activeDriverAssignments[driverId];

        return FleetDriverModel.fromJson(
          json,
          currentVehicleId: activeAssign?.vehicleId ?? '',
          documents: docsByDriverId[driverId] ?? const [],
        );
      }).toList();

      final vehicles = vehiclesData.map<FleetVehicle>((json) {
        final vehicleId = json['id'] as String;
        final activeAssign = activeVehicleAssignments[vehicleId];
        final vehicleDocsList = docsByVehicleId[vehicleId] ?? const [];

        final licenseExpiry = vehicleDocsList
            .firstWhere(
              (doc) => doc.type == FleetDocumentType.vehicleLicense,
              orElse: FleetDocumentModel.empty,
            )
            .expiryDate;

        final insuranceExpiry = vehicleDocsList
            .firstWhere(
              (doc) => doc.type == FleetDocumentType.insurance,
              orElse: FleetDocumentModel.empty,
            )
            .expiryDate;

        final inspectionExpiry = vehicleDocsList
            .firstWhere(
              (doc) => doc.type == FleetDocumentType.inspection,
              orElse: FleetDocumentModel.empty,
            )
            .expiryDate;

        return FleetVehicleModel.fromJson(
          json,
          currentDriverId: activeAssign?.driverId ?? '',
          licenseExpiry: licenseExpiry,
          insuranceExpiry: insuranceExpiry,
          inspectionExpiry: inspectionExpiry,
        );
      }).toList();

      debugPrint(
        '[SupabaseFleetDatasource] Loaded: '
        '${drivers.length} drivers, '
        '${vehicles.length} vehicles, '
        '${assignments.length} assignments.',
      );

      return FleetWorkspace(
        drivers: drivers,
        vehicles: vehicles,
        assignments: assignments,
        documents: <FleetDocument>[...driverDocs, ...vehicleDocs],
      );
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected Supabase fetch error: $e');
    }
  }

  @override
  Future<FleetDriverModel> createDriver(FleetDriver driver) async {
    try {
      final payload = _driverPayload(driver);

      final response = await _client
          .from('drivers')
          .insert(payload)
          .select()
          .single();

      final created = FleetDriverModel.fromJson(response);

      if (driver.currentVehicleId.isNotEmpty) {
        await _handleVehicleAssignmentChange(
          created.id,
          driver.currentVehicleId,
        );
      }

      return created;
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected create driver error: $e');
    }
  }

  @override
  Future<FleetDriverModel> updateDriver(FleetDriver driver) async {
    try {
      final payload = _driverPayload(driver);

      final response = await _client
          .from('drivers')
          .update(payload)
          .eq('id', driver.id)
          .select()
          .single();

      final updated = FleetDriverModel.fromJson(response);

      await _handleVehicleAssignmentChange(driver.id, driver.currentVehicleId);

      return updated;
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update driver error: $e');
    }
  }

  @override
  Future<FleetDriverModel> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  ) async {
    try {
      final response = await _client
          .from('drivers')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId)
          .select()
          .single();

      if (status == FleetDriverStatus.archived ||
          status == FleetDriverStatus.suspended) {
        final active = await _activeAssignmentForDriver(driverId);
        if (active != null) {
          await removeAssignment(active['id'] as String);
        }
      }

      return FleetDriverModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update driver status error: $e');
    }
  }

  @override
  Future<FleetVehicleModel> createVehicle(FleetVehicle vehicle) async {
    try {
      final payload = _vehiclePayload(vehicle);

      final response = await _client
          .from('vehicles')
          .insert(payload)
          .select()
          .single();

      final created = FleetVehicleModel.fromJson(response);

      if (vehicle.currentDriverId.isNotEmpty) {
        await _handleDriverAssignmentChange(created.id, vehicle.currentDriverId);
      }

      return created;
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected create vehicle error: $e');
    }
  }

  @override
  Future<FleetVehicleModel> updateVehicle(FleetVehicle vehicle) async {
    try {
      final payload = _vehiclePayload(vehicle);

      final response = await _client
          .from('vehicles')
          .update(payload)
          .eq('id', vehicle.id)
          .select()
          .single();

      final updated = FleetVehicleModel.fromJson(response);

      await _handleDriverAssignmentChange(vehicle.id, vehicle.currentDriverId);

      return updated;
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update vehicle error: $e');
    }
  }

  @override
  Future<FleetVehicleModel> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  ) async {
    try {
      final response = await _client
          .from('vehicles')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vehicleId)
          .select()
          .single();

      if (status != FleetVehicleStatus.active) {
        final active = await _activeAssignmentForVehicle(vehicleId);
        if (active != null) {
          await removeAssignment(active['id'] as String);
        }
      }

      return FleetVehicleModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update vehicle status error: $e');
    }
  }

  @override
  Future<FleetAssignmentModel> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  ) async {
    try {
      final response = await _client
          .from('assignments')
          .insert({
            'driver_id': driverId,
            'vehicle_id': vehicleId,
            'assigned_at': DateTime.now().toIso8601String(),
            'status': FleetAssignmentStatus.active.name,
            'history': [
              {
                'title': 'تم إنشاء التعيين',
                'date': _today(),
                'description': 'تم ربط السائق بالمركبة بعد مراجعة الوثائق.',
              },
            ],
          })
          .select()
          .single();

      return FleetAssignmentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected create assignment error: $e');
    }
  }

  @override
  Future<FleetAssignmentModel> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  ) async {
    try {
      final current = await _client
          .from('assignments')
          .select()
          .eq('id', assignmentId)
          .single();

      final driverId = current['driver_id'] as String;
      final oldVehicleId = current['vehicle_id'] as String;
      final history = List<dynamic>.from((current['history'] as List?) ?? []);

      history.add({
        'title': 'تغيير المركبة',
        'date': _today(),
        'description': 'تم فك المركبة القديمة $oldVehicleId.',
      });

      await _client
          .from('assignments')
          .update({
            'status': FleetAssignmentStatus.ended.name,
            'ended_at': DateTime.now().toIso8601String(),
            'history': history,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);

      return assignDriverToVehicle(driverId, newVehicleId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected reassign vehicle error: $e');
    }
  }

  @override
  Future<FleetAssignmentModel> removeAssignment(String assignmentId) async {
    try {
      final current = await _client
          .from('assignments')
          .select()
          .eq('id', assignmentId)
          .single();

      final history = List<dynamic>.from((current['history'] as List?) ?? []);

      history.add({
        'title': 'فك التعيين',
        'date': _today(),
        'description': 'تم إنهاء التعيين وحفظ السجل التشغيلي.',
      });

      final response = await _client
          .from('assignments')
          .update({
            'status': FleetAssignmentStatus.ended.name,
            'ended_at': DateTime.now().toIso8601String(),
            'history': history,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId)
          .select()
          .single();

      return FleetAssignmentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected remove assignment error: $e');
    }
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
    try {
      final tableName = isDriver ? 'driver_documents' : 'vehicle_documents';

      final response = await _client
          .from(tableName)
          .insert({
            if (isDriver) 'driver_id': ownerId else 'vehicle_id': ownerId,
            'type': documentTypeToDbString(type),
            'file_url': fileUrl,
            'expiry_date': expiryDate,
            'status': documentStatusToDbString(status),
          })
          .select()
          .single();

      final ownerName = await _getOwnerName(
        ownerId: ownerId,
        isDriver: isDriver,
      );

      return FleetDocumentModel.fromJson(response, ownerName: ownerName);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected create document error: $e');
    }
  }

  @override
  Future<FleetDocumentModel> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    try {
      final tableName = isDriver ? 'driver_documents' : 'vehicle_documents';

      final response = await _client
          .from(tableName)
          .update({
            'file_url': fileUrl,
            'expiry_date': expiryDate,
            'status': documentStatusToDbString(status),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId)
          .select()
          .single();

      final ownerId = isDriver
          ? response['driver_id'] as String
          : response['vehicle_id'] as String;

      final ownerName = await _getOwnerName(
        ownerId: ownerId,
        isDriver: isDriver,
      );

      return FleetDocumentModel.fromJson(response, ownerName: ownerName);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update document error: $e');
    }
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    try {
      final tableName = isDriver ? 'driver_documents' : 'vehicle_documents';
      await _client.from(tableName).delete().eq('id', documentId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected delete document error: $e');
    }
  }

  Future<String> uploadFile(String bucket, String path, Uint8List bytes) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _client.storage.from(bucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unexpected upload file error: $e');
    }
  }

  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } on StorageException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unexpected delete file error: $e');
    }
  }

  Future<Map<String, dynamic>?> _activeAssignmentForDriver(
    String driverId,
  ) async {
    final list = await _client
        .from('assignments')
        .select()
        .eq('driver_id', driverId)
        .eq('status', FleetAssignmentStatus.active.name);

    if (list.isEmpty) return null;
    return list.first;
  }

  Future<Map<String, dynamic>?> _activeAssignmentForVehicle(
    String vehicleId,
  ) async {
    final list = await _client
        .from('assignments')
        .select()
        .eq('vehicle_id', vehicleId)
        .eq('status', FleetAssignmentStatus.active.name);

    if (list.isEmpty) return null;
    return list.first;
  }

  Future<void> _handleVehicleAssignmentChange(
    String driverId,
    String newVehicleId,
  ) async {
    final activeAssign = await _activeAssignmentForDriver(driverId);
    final oldVehicleId = activeAssign?['vehicle_id'] as String? ?? '';

    if (oldVehicleId == newVehicleId) return;

    if (activeAssign != null) {
      await removeAssignment(activeAssign['id'] as String);
    }

    if (newVehicleId.isNotEmpty) {
      final activeAssignForNewVehicle =
          await _activeAssignmentForVehicle(newVehicleId);

      if (activeAssignForNewVehicle != null) {
        await removeAssignment(activeAssignForNewVehicle['id'] as String);
      }

      await assignDriverToVehicle(driverId, newVehicleId);
    }
  }

  Future<void> _handleDriverAssignmentChange(
    String vehicleId,
    String newDriverId,
  ) async {
    final activeAssign = await _activeAssignmentForVehicle(vehicleId);
    final oldDriverId = activeAssign?['driver_id'] as String? ?? '';

    if (oldDriverId == newDriverId) return;

    if (activeAssign != null) {
      await removeAssignment(activeAssign['id'] as String);
    }

    if (newDriverId.isNotEmpty) {
      final activeAssignForNewDriver =
          await _activeAssignmentForDriver(newDriverId);

      if (activeAssignForNewDriver != null) {
        await removeAssignment(activeAssignForNewDriver['id'] as String);
      }

      await assignDriverToVehicle(newDriverId, vehicleId);
    }
  }

  Future<String> _getOwnerName({
    required String ownerId,
    required bool isDriver,
  }) async {
    if (isDriver) {
      final owner = await _client
          .from('drivers')
          .select('full_name')
          .eq('id', ownerId)
          .single();

      return owner['full_name'] as String? ?? '';
    }

    final owner = await _client
        .from('vehicles')
        .select('vehicle_code')
        .eq('id', ownerId)
        .single();

    return owner['vehicle_code'] as String? ?? '';
  }

  Map<String, dynamic> _driverPayload(FleetDriver driver) {
    final raw = FleetDriverModel.fromEntity(driver).toJson();
    final payload = _onlyAllowed(raw, _driverColumns);

    payload['updated_at'] = DateTime.now().toIso8601String();

    return payload;
  }

  Map<String, dynamic> _vehiclePayload(FleetVehicle vehicle) {
    final raw = FleetVehicleModel.fromEntity(vehicle).toJson();
    final payload = _onlyAllowed(raw, _vehicleColumns);

    payload['updated_at'] = DateTime.now().toIso8601String();

    return payload;
  }

  Map<String, dynamic> _onlyAllowed(
    Map<String, dynamic> raw,
    Set<String> allowedKeys,
  ) {
    final payload = <String, dynamic>{};

    for (final entry in raw.entries) {
      if (allowedKeys.contains(entry.key)) {
        payload[entry.key] = entry.value;
      }
    }

    payload.removeWhere((key, value) => value == '');

    return payload;
  }

  String _formatPostgrestError(PostgrestException e) {
    final buffer = StringBuffer(e.message);

    if (e.code != null && e.code!.isNotEmpty) {
      buffer.write(' | code: ${e.code}');
    }

    if (e.details != null && e.details.toString().isNotEmpty) {
      buffer.write(' | details: ${e.details}');
    }

    if (e.hint != null && e.hint.toString().isNotEmpty) {
      buffer.write(' | hint: ${e.hint}');
    }

    return buffer.toString();
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;
}
