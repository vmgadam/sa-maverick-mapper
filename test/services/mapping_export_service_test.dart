import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/saved_mapping.dart';
import '../../lib/services/mapping_export_service.dart';

void main() {
  late SavedMapping testMapping;

  setUp(() {
    testMapping = SavedMapping(
      name: 'Test Mapping',
      product: 'Test Product',
      query: 'test query',
      mappings: [
        {'source': 'field1', 'target': 'target1', 'isComplex': 'false'},
      ],
      configFields: {
        'endpointId': '123',
        'eventType': 'TEST_EVENT',
        'productRef': 'products/test',
      },
      totalFieldsMapped: 1,
      requiredFieldsMapped: 0,
      totalRequiredFields: 1,
    );
  });

  group('MappingExportService', () {
    test('formats single mapping correctly', () {
      final result = MappingExportService.formatSingleMapping(testMapping);

      // Verify basic structure
      expect(result['accountKey'], equals({'field': 'data.id', 'type': 'id'}));
      expect(result['dateKeyField'], equals('data.createdAt'));
      expect(result['endpointId'], equals(123));
      expect(result['endpointName'], equals('events'));
      expect(result['eventFilter'], equals('test query'));
      expect(result['eventType'], equals('TEST_EVENT'));
      expect(result['eventTypeKey'], equals('TEST_EVENT'));
      expect(result['productRef'], equals({'__ref__': 'products/test'}));
      expect(result['userKeyField'], equals('data.userId'));

      // Verify schema
      expect(result['schema'], equals(testMapping.mappings));

      // Verify metadata
      final metadata = result['metadata'] as Map<String, dynamic>;
      expect(metadata['name'], equals(testMapping.name));
      expect(metadata['product'], equals(testMapping.product));
      expect(
          metadata['totalFieldsMapped'], equals(testMapping.totalFieldsMapped));
      expect(metadata['requiredFieldsMapped'],
          equals(testMapping.requiredFieldsMapped));
      expect(metadata['totalRequiredFields'],
          equals(testMapping.totalRequiredFields));
      expect(metadata['createdAt'], isNotNull);
      expect(metadata['modifiedAt'], isNotNull);
    });

    test('formats multiple mappings correctly', () {
      final testMapping2 = SavedMapping(
        name: 'Test Mapping 2',
        product: 'Test Product',
        query: 'test query 2',
        mappings: [
          {'source': 'field2', 'target': 'target2', 'isComplex': 'false'},
        ],
        configFields: {
          'endpointId': '456',
          'eventType': 'TEST_EVENT_2',
          'productRef': 'products/test2',
        },
        totalFieldsMapped: 1,
        requiredFieldsMapped: 0,
        totalRequiredFields: 1,
      );

      final result = MappingExportService.formatMultipleMappings(
          [testMapping, testMapping2]);

      // Verify structure
      expect(result['version'], equals('1.0'));
      expect(result['exportedAt'], isNotNull);
      expect(result['mappings'], isList);
      expect(result['mappings'].length, equals(2));

      // Verify first mapping
      final firstMapping = result['mappings'][0] as Map<String, dynamic>;
      expect(firstMapping['eventType'], equals('TEST_EVENT'));
      expect(firstMapping['schema'], equals(testMapping.mappings));

      // Verify second mapping
      final secondMapping = result['mappings'][1] as Map<String, dynamic>;
      expect(secondMapping['eventType'], equals('TEST_EVENT_2'));
      expect(secondMapping['schema'], equals(testMapping2.mappings));
    });

    test('handles empty query correctly', () {
      final emptyQueryMapping = SavedMapping(
        name: 'Empty Query Mapping',
        product: 'Test Product',
        query: '',
        mappings: [],
        configFields: {},
        totalFieldsMapped: 0,
        requiredFieldsMapped: 0,
        totalRequiredFields: 0,
      );

      final result =
          MappingExportService.formatSingleMapping(emptyQueryMapping);

      // Verify default query is used
      expect(
        result['eventFilter'],
        equals(
            '{\n  "query": {\n    "bool": {\n      "must": [],\n      "filter": [],\n      "should": [],\n      "must_not": []\n    }\n  }\n}'),
      );
    });

    test('handles missing config fields correctly', () {
      final noConfigMapping = SavedMapping(
        name: 'No Config Mapping',
        product: 'Test Product',
        query: 'test query',
        mappings: [],
        configFields: {},
        totalFieldsMapped: 0,
        requiredFieldsMapped: 0,
        totalRequiredFields: 0,
      );

      final result = MappingExportService.formatSingleMapping(noConfigMapping);

      // Verify default values
      expect(result['endpointId'], equals(0));
      expect(result['eventType'], equals('EVENT'));
      expect(result['eventTypeKey'], equals('EVENT'));
      expect(result['productRef'], equals({'__ref__': 'products/default'}));
    });
  });
}
