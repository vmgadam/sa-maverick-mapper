import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('Field Mapping Tests', () {
    // Sample data from elastic response
    final sampleFields = {
      'data.status': ['Technician Logged Out'],
      'data.data.message.params.appUserName.keyword': ['Ryan Roberts'],
      'product.type': ['NINJA_ONE'],
      'partner.id': ['tPCIowv2mMEPB2lFJjSS'],
      'data.message': ['Technician \'Ryan Roberts\' logged out.'],
      'data.activityResult': ['SUCCESS'],
      'data.data.message.params.appUserId': ['363'],
      'data.activityResult.keyword': ['SUCCESS'],
      '@timestamp': ['2024-12-31T19:55:42.516Z'],
      'data.data.message.params.appUserName': ['Ryan Roberts'],
      'data.activityTime': [1735674240],
    };

    dynamic getNestedValue(Map<String, dynamic> data, String path) {
      // In Elastic fields, the path is the key and the value is an array
      final value = data[path];
      if (value is List && value.isNotEmpty) {
        return value[0].toString();
      }
      return 'null';
    }

    test('Field values should be correctly extracted', () {
      // Test each field
      expect(getNestedValue(sampleFields, 'data.status'),
          equals('Technician Logged Out'));
      expect(getNestedValue(sampleFields, 'product.type'), equals('NINJA_ONE'));
      expect(getNestedValue(sampleFields, 'partner.id'),
          equals('tPCIowv2mMEPB2lFJjSS'));
      expect(getNestedValue(sampleFields, 'data.message'),
          equals('Technician \'Ryan Roberts\' logged out.'));
      expect(getNestedValue(sampleFields, 'data.activityResult'),
          equals('SUCCESS'));
      expect(getNestedValue(sampleFields, 'data.data.message.params.appUserId'),
          equals('363'));
      expect(getNestedValue(sampleFields, '@timestamp'),
          equals('2024-12-31T19:55:42.516Z'));
      expect(
          getNestedValue(sampleFields, 'data.data.message.params.appUserName'),
          equals('Ryan Roberts'));
      expect(getNestedValue(sampleFields, 'data.activityTime'),
          equals('1735674240'));
    });

    test('Non-existent fields should return null', () {
      expect(getNestedValue(sampleFields, 'nonexistent.field'), equals('null'));
    });

    test(
        'Fields with .keyword suffix should be ignored but base field should work',
        () {
      expect(getNestedValue(sampleFields, 'data.activityResult'),
          equals('SUCCESS'));
      expect(
          getNestedValue(sampleFields, 'data.data.message.params.appUserName'),
          equals('Ryan Roberts'));
    });

    test('Array values should return first element', () {
      final data = {
        'test.field': ['first', 'second', 'third']
      };
      expect(getNestedValue(data, 'test.field'), equals('first'));
    });
  });
}
