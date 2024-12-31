import 'package:flutter_test/flutter_test.dart';
import 'package:sa_maverick_mapper/services/field_mapping_service.dart';

void main() {
  group('Field Value Extraction Tests', () {
    test('should extract values from Elastic-style array fields', () {
      final data = {
        'user.email': ['test@example.com'],
        'user.name': ['John Doe'],
        'timestamp': ['2024-01-01'],
      };

      expect(FieldMappingService.getNestedValue(data, 'user.email'),
          'test@example.com');
      expect(FieldMappingService.getNestedValue(data, 'user.name'), 'John Doe');
      expect(
          FieldMappingService.getNestedValue(data, 'timestamp'), '2024-01-01');
    });

    test('should extract values from Rocket Cyber-style nested objects', () {
      final data = {
        'user': {
          'email': 'test@example.com',
          'name': 'John Doe',
        },
        'timestamp': '2024-01-01',
      };

      expect(FieldMappingService.getNestedValue(data, 'user.email'),
          'test@example.com');
      expect(FieldMappingService.getNestedValue(data, 'user.name'), 'John Doe');
      expect(
          FieldMappingService.getNestedValue(data, 'timestamp'), '2024-01-01');
    });

    test('should handle missing or null values', () {
      final data = {
        'user': {
          'email': null,
        },
        'timestamp': [''],
      };

      expect(FieldMappingService.getNestedValue(data, 'user.email'), '');
      expect(FieldMappingService.getNestedValue(data, 'nonexistent.field'), '');
      expect(FieldMappingService.getNestedValue(data, 'timestamp'), '');
    });

    test('should handle mixed data structures', () {
      final data = {
        'user.email': ['test@example.com'], // Elastic style
        'user': {
          // Rocket Cyber style
          'name': 'John Doe',
          'details': {'age': 30}
        },
      };

      expect(FieldMappingService.getNestedValue(data, 'user.email'),
          'test@example.com');
      expect(FieldMappingService.getNestedValue(data, 'user.name'), 'John Doe');
      expect(
          FieldMappingService.getNestedValue(data, 'user.details.age'), '30');
    });
  });
}
