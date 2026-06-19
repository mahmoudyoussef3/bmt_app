import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/data/models/fleet_models.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_common.dart';

void main() {
  group('FleetVehicleModel Tests', () {
    test('fromJson parses comma-separated image URLs into images list', () {
      final json = {
        'id': 'v-123',
        'vehicle_code': 'BUS-999',
        'plate_number': '١٢٣٤ أ ب ج',
        'vehicle_type': 'Coaster',
        'brand': 'Toyota',
        'model': 'Coaster',
        'manufacture_year': 2022,
        'color': 'أبيض',
        'capacity': 14,
        'seat_layout_type': 'standard',
        'image_url':
            'https://example.com/img1.jpg,https://example.com/img2.jpg',
        'notes': 'مركبة جديدة في الأسطول',
        'status': 'active',
      };

      final vehicle = FleetVehicleModel.fromJson(json);

      expect(vehicle.id, 'v-123');
      expect(vehicle.vehicleCode, 'BUS-999');
      expect(
        vehicle.imageUrl,
        'https://example.com/img1.jpg,https://example.com/img2.jpg',
      );
      expect(vehicle.images, hasLength(2));
      expect(vehicle.images[0].url, 'https://example.com/img1.jpg');
      expect(vehicle.images[1].url, 'https://example.com/img2.jpg');
    });

    test(
      'toJson serializes images list back into comma-separated image_url',
      () {
        const vehicle = FleetVehicleModel(
          id: 'v-123',
          vehicleCode: 'BUS-999',
          plateNumber: '١٢٣٤ أ ب ج',
          vehicleType: 'Coaster',
          brand: 'Toyota',
          model: 'Coaster',
          manufactureYear: 2022,
          color: 'أبيض',
          capacity: 14,
          seatLayoutType: 'standard',
          imageUrl: '',
          notes: 'مركبة جديدة في الأسطول',
          status: FleetVehicleStatus.active,
          seatConfiguration: SeatConfiguration(rows: 0, columns: 0, seats: []),
          licenseExpiry: '',
          insuranceExpiry: '',
          inspectionExpiry: '',
          images: [
            FleetVehicleImage(url: 'https://example.com/img1.jpg'),
            FleetVehicleImage(url: 'https://example.com/img2.jpg'),
          ],
        );

        final json = vehicle.toJson();

        expect(
          json['image_url'],
          'https://example.com/img1.jpg,https://example.com/img2.jpg',
        );
      },
    );
  });
}
