import 'package:flutter_test/flutter_test.dart';
import 'package:sa_rc_live/models/saved_mapping.dart';
import 'package:sa_rc_live/state/saved_mappings_state.dart';

void main() {
  late SavedMappingsState state;
  late SavedMapping testMapping;

  setUp(() {
    state = SavedMappingsState();
    testMapping = SavedMapping(
      name: 'Test Mapping',
      product: 'TestProduct',
      query: 'test query',
      mappings: [
        {'source': 'test', 'target': 'test'}
      ],
      configFields: {'field': 'value'},
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
  });

  group('SavedMappingsState', () {
    test('creates new mapping', () {
      state.createMapping(testMapping);
      final mappings = state.getMappingsForProduct('TestProduct');
      expect(mappings.length, 1);
      expect(mappings.first.name, 'Test Mapping');
    });

    test('creates mapping with unique name', () {
      state.createMapping(testMapping);
      state.createMapping(testMapping);
      final mappings = state.getMappingsForProduct('TestProduct');
      expect(mappings.length, 2);
      expect(mappings[0].name, 'Test Mapping');
      expect(mappings[1].name, 'Test Mapping (1)');
    });

    test('updates existing mapping', () {
      state.createMapping(testMapping);
      final updatedMapping = testMapping.copyWith(
        query: 'updated query',
      );
      state.updateMapping('TestProduct', 'Test Mapping', updatedMapping);
      final mappings = state.getMappingsForProduct('TestProduct');
      expect(mappings.first.query, 'updated query');
    });

    test('deletes mapping', () {
      state.createMapping(testMapping);
      state.deleteMapping('TestProduct', 'Test Mapping');
      final mappings = state.getMappingsForProduct('TestProduct');
      expect(mappings.isEmpty, true);
    });

    test('duplicates mapping', () {
      state.createMapping(testMapping);
      state.duplicateMapping('TestProduct', 'Test Mapping');
      final mappings = state.getMappingsForProduct('TestProduct');
      expect(mappings.length, 2);
      expect(mappings[1].name, 'Copy of Test Mapping');
    });

    test('bulk deletes mappings', () {
      state.createMapping(testMapping);
      state.createMapping(testMapping.copyWith(name: 'Test Mapping 2'));
      state.deleteMappings('TestProduct', ['Test Mapping', 'Test Mapping 2']);
      final mappings = state.getMappingsForProduct('TestProduct');
      expect(mappings.isEmpty, true);
    });

    test('finds duplicate queries', () {
      state.createMapping(testMapping);
      state.createMapping(testMapping.copyWith(
        name: 'Test Mapping 2',
        query: 'test query',
      ));
      final duplicates =
          state.findDuplicateQueries('TestProduct', 'test query');
      expect(duplicates.length, 2);
    });

    test('undoes last delete', () {
      state.createMapping(testMapping);
      state.deleteMapping('TestProduct', 'Test Mapping');
      expect(state.getMappingsForProduct('TestProduct').isEmpty, true);

      final undoSuccessful = state.undoDelete();
      expect(undoSuccessful, true);
      expect(state.getMappingsForProduct('TestProduct').length, 1);
    });

    test('undo returns false when no delete to undo', () {
      final undoSuccessful = state.undoDelete();
      expect(undoSuccessful, false);
    });
  });
}
