import 'package:flutter_test/flutter_test.dart';
import 'package:sa_rc_live/state/mapping_state.dart';
import 'package:sa_rc_live/models/saved_mapping.dart';

void main() {
  group('MappingState', () {
    late MappingState state;
    late SavedMapping testMapping;

    setUp(() {
      state = MappingState();
      testMapping = SavedMapping(
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
    });

    test('initial state is empty', () {
      expect(state.savedMappings, isEmpty);
      expect(state.lastBulkOperation, isNull);
    });

    group('SavedMapping operations', () {
      test('adds new mapping', () {
        state.addSavedMapping(testMapping);
        expect(state.savedMappings.length, equals(1));
        expect(state.savedMappings.first, equals(testMapping));
      });

      test('updates existing mapping', () {
        state.addSavedMapping(testMapping);
        final updated = testMapping.copyWith(totalFieldsMapped: 2);
        state.updateSavedMapping(updated);

        expect(state.savedMappings.length, equals(1));
        expect(state.savedMappings.first.totalFieldsMapped, equals(2));
        expect(state.savedMappings.first.modifiedAt,
            isNot(equals(testMapping.modifiedAt)));
      });

      test('deletes mapping', () {
        state.addSavedMapping(testMapping);
        state.deleteSavedMapping(testMapping);
        expect(state.savedMappings, isEmpty);
      });

      test('duplicates mapping', () {
        state.addSavedMapping(testMapping);
        final duplicate = state.duplicateSavedMapping(testMapping);

        expect(state.savedMappings.length, equals(2));
        expect(duplicate?.name, equals('Copy of Test Mapping'));
      });

      test('duplicates mapping with custom name', () {
        state.addSavedMapping(testMapping);
        final duplicate =
            state.duplicateSavedMapping(testMapping, newName: 'Custom Name');

        expect(state.savedMappings.length, equals(2));
        expect(duplicate?.name, equals('Custom Name'));
      });

      test('finds mappings with query', () {
        state.addSavedMapping(testMapping);
        state.addSavedMapping(
            testMapping.copyWith(name: 'Other', query: 'different'));

        final matches = state.findMappingsWithQuery('test query');
        expect(matches.length, equals(1));
        expect(matches.first, equals(testMapping));
      });
    });

    group('Bulk operations', () {
      late SavedMapping mapping1;
      late SavedMapping mapping2;

      setUp(() {
        mapping1 = testMapping;
        mapping2 = SavedMapping(
          name: 'Test 2',
          product: 'Test Product',
          query: 'test query',
          mappings: [
            {'source': 'test2', 'target': 'test2'}
          ],
          configFields: {'field': 'value2'},
          totalFieldsMapped: 2,
          requiredFieldsMapped: 2,
          totalRequiredFields: 2,
        );
        state.addSavedMapping(mapping1);
        state.addSavedMapping(mapping2);
      });

      test('bulk updates mappings', () {
        state.bulkUpdateMappings(
          [mapping1, mapping2],
          (m) => m.copyWith(totalFieldsMapped: 10),
        );

        expect(state.savedMappings[0].totalFieldsMapped, equals(10));
        expect(state.savedMappings[1].totalFieldsMapped, equals(10));
        expect(state.lastBulkOperation, isNotNull);
      });

      test('reverts bulk operation', () {
        state.bulkUpdateMappings(
          [mapping1, mapping2],
          (m) => m.copyWith(totalFieldsMapped: 10),
        );
        state.revertLastBulkOperation();

        expect(state.savedMappings[0].totalFieldsMapped, equals(1));
        expect(state.savedMappings[1].totalFieldsMapped, equals(2));
        expect(state.lastBulkOperation, isNull);
      });

      test('bulk deletes mappings', () {
        state.deleteSavedMappings([mapping1, mapping2]);
        expect(state.savedMappings, isEmpty);
      });
    });
  });
}
