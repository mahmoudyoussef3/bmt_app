import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/fleet_workspace.dart';
import '../models/fleet_models.dart';
import 'mock_fleet_datasource.dart';

class SupabaseFleetDatasource implements FleetDatasource {
  final SupabaseClient _client;

  SupabaseFleetDatasource(this._client);

  @override
  Future<FleetWorkspace> fetchWorkspace() async {
    // 1. Fetch Drivers (not archived)
    final driversData = await _client
        .from('drivers')
        .select()
        .neq('status', 'archived')
        .order('full_name');

    // 2. Fetch Vehicles (not archived)
    final vehiclesData = await _client
        .from('vehicles')
        .select()
        .neq('status', 'archived')
        .order('vehicle_code');

    // 3. Fetch Assignments
    final assignmentsData = await _client
        .from('assignments')
        .select()
        .order('assigned_at', ascending: false);

    // 4. Fetch Driver Documents
    final driverDocsData = await _client.from('driver_documents').select();

    // 5. Fetch Vehicle Documents
    final vehicleDocsData = await _client.from('vehicle_documents').select();

    // Parse Assignments
    final List<FleetAssignment> assignments = assignmentsData
        .map<FleetAssignment>((json) => FleetAssignmentModel.fromJson(json))
        .toList();

    // Active Assignments Map (DriverId -> Assignment, VehicleId -> Assignment)
    final Map<String, FleetAssignmentModel> activeDriverAssignments = {};
    final Map<String, FleetAssignmentModel> activeVehicleAssignments = {};

    for (final assignment in assignments) {
      if (assignment.status == FleetAssignmentStatus.active) {
        activeDriverAssignments[assignment.driverId] = assignment as FleetAssignmentModel;
        activeVehicleAssignments[assignment.vehicleId] = assignment as FleetAssignmentModel;
      }
    }

    // Driver Names Map for document owner names
    final Map<String, String> driverNames = {};
    for (final json in driversData) {
      driverNames[json['id'] as String] = (json['full_name'] ?? '') as String;
    }

    // Vehicle Codes/Numbers Map for document owner names
    final Map<String, String> vehicleCodes = {};
    for (final json in vehiclesData) {
      vehicleCodes[json['id'] as String] = (json['vehicle_code'] ?? '') as String;
    }

    // Parse Driver Documents
    final List<FleetDocumentModel> driverDocs = driverDocsData.map((json) {
      final driverId = json['driver_id'] as String? ?? '';
      return FleetDocumentModel.fromJson(json, ownerName: driverNames[driverId] ?? '');
    }).toList();

    // Parse Vehicle Documents
    final List<FleetDocumentModel> vehicleDocs = vehicleDocsData.map((json) {
      final vehicleId = json['vehicle_id'] as String? ?? '';
      return FleetDocumentModel.fromJson(json, ownerName: vehicleCodes[vehicleId] ?? '');
    }).toList();

    // Group documents by owner
    final Map<String, List<FleetDocumentModel>> docsByDriverId = {};
    for (final doc in driverDocs) {
      docsByDriverId.putIfAbsent(doc.ownerId, () => []).add(doc);
    }

    final Map<String, List<FleetDocumentModel>> docsByVehicleId = {};
    for (final doc in vehicleDocs) {
      docsByVehicleId.putIfAbsent(doc.ownerId, () => []).add(doc);
    }

    // Parse Drivers
    final List<FleetDriver> drivers = driversData.map<FleetDriver>((json) {
      final driverId = json['id'] as String;
      final activeAssign = activeDriverAssignments[driverId];
      final currentVehicleId = activeAssign?.vehicleId ?? '';
      return FleetDriverModel.fromJson(
        json,
        currentVehicleId: currentVehicleId,
        documents: docsByDriverId[driverId] ?? [],
      );
    }).toList();

    // Parse Vehicles
    final List<FleetVehicle> vehicles = vehiclesData.map<FleetVehicle>((json) {
      final vehicleId = json['id'] as String;
      final activeAssign = activeVehicleAssignments[vehicleId];
      final currentDriverId = activeAssign?.driverId ?? '';

      // Find expiry dates from documents
      final vDocs = docsByVehicleId[vehicleId] ?? [];
      final licExpiry = vDocs
          .firstWhere((d) => d.type == FleetDocumentType.vehicleLicense,
              orElse: () => FleetDocumentModel.empty())
          .expiryDate;
      final insExpiry = vDocs
          .firstWhere((d) => d.type == FleetDocumentType.insurance,
              orElse: () => FleetDocumentModel.empty())
          .expiryDate;
      final inspExpiry = vDocs
          .firstWhere((d) => d.type == FleetDocumentType.inspection,
              orElse: () => FleetDocumentModel.empty())
          .expiryDate;

      return FleetVehicleModel.fromJson(
        json,
        currentDriverId: currentDriverId,
        licenseExpiry: licExpiry,
        insuranceExpiry: insExpiry,
        inspectionExpiry: inspExpiry,
      );
    }).toList();

    // Combine all documents
    final List<FleetDocument> allDocuments = <FleetDocument>[...driverDocs, ...vehicleDocs];

    return FleetWorkspace(
      drivers: drivers,
      vehicles: vehicles,
      assignments: assignments,
      documents: allDocuments,
    );
  }

  @override
  Future<FleetDriverModel> createDriver(FleetDriver driver) async {
    final driverModel = FleetDriverModel.fromEntity(driver);
    final response = await _client
        .from('drivers')
        .insert(driverModel.toJson())
        .select()
        .single();
    return FleetDriverModel.fromJson(response);
  }

  @override
  Future<FleetDriverModel> updateDriver(FleetDriver driver) async {
    final driverModel = FleetDriverModel.fromEntity(driver);
    final response = await _client
        .from('drivers')
        .update(driverModel.toJson())
        .eq('id', driver.id)
        .select()
        .single();
    return FleetDriverModel.fromJson(response);
  }

  @override
  Future<FleetDriverModel> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  ) async {
    final response = await _client
        .from('drivers')
        .update({'status': status.name})
        .eq('id', driverId)
        .select()
        .single();
    return FleetDriverModel.fromJson(response);
  }

  @override
  Future<FleetVehicleModel> createVehicle(FleetVehicle vehicle) async {
    final vehicleModel = FleetVehicleModel.fromEntity(vehicle);
    final response = await _client
        .from('vehicles')
        .insert(vehicleModel.toJson())
        .select()
        .single();
    return FleetVehicleModel.fromJson(response);
  }

  @override
  Future<FleetVehicleModel> updateVehicle(FleetVehicle vehicle) async {
    final vehicleModel = FleetVehicleModel.fromEntity(vehicle);
    final response = await _client
        .from('vehicles')
        .update(vehicleModel.toJson())
        .eq('id', vehicle.id)
        .select()
        .single();
    return FleetVehicleModel.fromJson(response);
  }

  @override
  Future<FleetVehicleModel> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  ) async {
    final response = await _client
        .from('vehicles')
        .update({'status': status.name})
        .eq('id', vehicleId)
        .select()
        .single();
    return FleetVehicleModel.fromJson(response);
  }

  @override
  Future<FleetAssignmentModel> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  ) async {
    final assignment = {
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'status': FleetAssignmentStatus.active.name,
      'assigned_at': DateTime.now().toIso8601String(),
      'history': [
        {
          'title': 'تم إنشاء التعيين',
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'description': 'تم ربط السائق بالمركبة وحفظ السجل.',
        }
      ],
    };
    final response =
        await _client.from('assignments').insert(assignment).select().single();
    return FleetAssignmentModel.fromJson(response);
  }

  @override
  Future<FleetAssignmentModel> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  ) async {
    // 1. Fetch current assignment history
    final current = await _client
        .from('assignments')
        .select()
        .eq('id', assignmentId)
        .single();

    final List<dynamic> history = current['history'] as List? ?? [];
    history.add({
      'title': 'تغيير المركبة',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'description': 'تم تغيير المركبة المرتبطة من ${current['vehicle_id']} إلى $newVehicleId.',
    });

    final response = await _client
        .from('assignments')
        .update({
          'vehicle_id': newVehicleId,
          'history': history,
        })
        .eq('id', assignmentId)
        .select()
        .single();
    return FleetAssignmentModel.fromJson(response);
  }

  @override
  Future<FleetAssignmentModel> removeAssignment(String assignmentId) async {
    final current = await _client
        .from('assignments')
        .select()
        .eq('id', assignmentId)
        .single();

    final List<dynamic> history = current['history'] as List? ?? [];
    history.add({
      'title': 'فك التعيين',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'description': 'تم إنهاء تعيين المركبة وفك الارتباط.',
    });

    final response = await _client
        .from('assignments')
        .update({
          'status': FleetAssignmentStatus.ended.name,
          'ended_at': DateTime.now().toIso8601String(),
          'history': history,
        })
        .eq('id', assignmentId)
        .select()
        .single();
    return FleetAssignmentModel.fromJson(response);
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
    final body = {
      isDriver ? 'driver_id' : 'vehicle_id': ownerId,
      'type': documentTypeToDbString(type),
      'file_url': fileUrl,
      'expiry_date': expiryDate,
      'status': documentStatusToDbString(status),
    };
    final tableName = isDriver ? 'driver_documents' : 'vehicle_documents';
    final response = await _client.from(tableName).insert(body).select().single();
    return FleetDocumentModel.fromJson(response);
  }

  @override
  Future<FleetDocumentModel> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    final body = {
      'file_url': fileUrl,
      'expiry_date': expiryDate,
      'status': documentStatusToDbString(status),
    };
    final tableName = isDriver ? 'driver_documents' : 'vehicle_documents';
    final response = await _client.from(tableName).update(body).eq('id', documentId).select().single();
    return FleetDocumentModel.fromJson(response);
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    final tableName = isDriver ? 'driver_documents' : 'vehicle_documents';
    await _client.from(tableName).delete().eq('id', documentId);
  }

  // Storage bucket helper functions
  Future<String> uploadFile(String bucket, String path, Uint8List bytes) async {
    await _client.storage.from(bucket).uploadBinary(path, bytes);
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
