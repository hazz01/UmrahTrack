import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:umrahtrack/presentation/pages/admin/lokasi_person.dart';

void main() {
  group('Route Feature Tests', () {
    test('JamaahLocation model should be created correctly', () {
      final jamaah = JamaahLocation(
        userId: 'test-user-id',
        name: 'Test Jamaah',
        email: 'test@example.com',
        rombonganName: 'Test Rombongan',
        location: const LatLng(21.4225, 39.8262), // Mecca coordinates
        accuracy: 5.0,
        speed: 0.0,
        lastUpdate: '2025-06-27T10:00:00Z',
        isTracking: true,
        isOnline: true,
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      expect(jamaah.userId, equals('test-user-id'));
      expect(jamaah.name, equals('Test Jamaah'));
      expect(jamaah.email, equals('test@example.com'));
      expect(jamaah.rombonganName, equals('Test Rombongan'));
      expect(jamaah.isTracking, equals(true));
      expect(jamaah.isOnline, equals(true));
    });
  });
}
