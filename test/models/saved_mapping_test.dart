import 'package:flutter_test/flutter_test.dart';
import 'package:sa_rc_live/models/saved_mapping.dart';

void main() {
  group('SavedMapping', () {
    final testMapping = SavedMapping(
      name: 'Test Mapping',
      product: 'Test Product',
      query: 'test query',
      mappings: [
        {'source': 'test', 'target': 'test'}
      ],
      configFields: {'field': 'value'},
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
    );

    test('creates with default timestamps', () {
      expect(testMapping.name, equals('Test Mapping'));
      expect(testMapping.createdAt, isNotNull);
      expect(testMapping.modifiedAt, isNotNull);
    });

    test('creates with provided timestamps', () {
      final now = DateTime.now();
      final mapping = SavedMapping(
        name: 'Test',
        product: 'Product',
        query: 'query',
        mappings: [],
        configFields: {},
        totalFieldsMapped: 0,
        requiredFieldsMapped: 0,
        totalRequiredFields: 0,
        createdAt: now,
        modifiedAt: now,
      );

      expect(mapping.createdAt, equals(now));
      expect(mapping.modifiedAt, equals(now));
    });

    test('copyWith creates new instance with updated values', () {
      final updated = testMapping.copyWith(
        name: 'Updated Name',
        totalFieldsMapped: 2,
      );

      expect(updated.name, equals('Updated Name'));
      expect(updated.totalFieldsMapped, equals(2));
      expect(updated.product, equals(testMapping.product));
      expect(updated.modifiedAt, isNot(equals(testMapping.modifiedAt)));
    });

    test('toJson converts to correct format', () {
      final json = testMapping.toJson();

      expect(json['name'], equals('Test Mapping'));
      expect(json['product'], equals('Test Product'));
      expect(json['query'], equals('test query'));
      expect(json['mappings'], isA<List>());
      expect(json['configFields'], isA<Map>());
      expect(json['createdAt'], isA<String>());
      expect(json['modifiedAt'], isA<String>());
    });

    test('fromJson creates correct instance', () {
      final json = testMapping.toJson();
      final fromJson = SavedMapping.fromJson(json);

      expect(fromJson.name, equals(testMapping.name));
      expect(fromJson.product, equals(testMapping.product));
      expect(fromJson.query, equals(testMapping.query));
      expect(fromJson.mappings, equals(testMapping.mappings));
      expect(fromJson.configFields, equals(testMapping.configFields));
    });

    test('duplicate creates copy with new name', () {
      final duplicate = SavedMapping.duplicate(testMapping);
      expect(duplicate.name, equals('Copy of Test Mapping'));
      expect(duplicate.product, equals(testMapping.product));
      expect(duplicate.query, equals(testMapping.query));
      expect(duplicate.mappings, equals(testMapping.mappings));
      expect(duplicate.configFields, equals(testMapping.configFields));
      expect(duplicate.createdAt, isNot(equals(testMapping.createdAt)));
    });

    test('duplicate with custom name', () {
      final duplicate =
          SavedMapping.duplicate(testMapping, newName: 'Custom Name');
      expect(duplicate.name, equals('Custom Name'));
    });

    test('equality check works correctly', () {
      final copy = SavedMapping(
        name: testMapping.name,
        product: testMapping.product,
        query: testMapping.query,
        mappings: testMapping.mappings,
        configFields: testMapping.configFields,
        totalFieldsMapped: testMapping.totalFieldsMapped,
        requiredFieldsMapped: testMapping.requiredFieldsMapped,
        totalRequiredFields: testMapping.totalRequiredFields,
      );

      expect(testMapping == copy, isTrue);
      expect(testMapping.hashCode == copy.hashCode, isTrue);
    });
  });
}
