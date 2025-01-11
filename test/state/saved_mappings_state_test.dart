import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/saved_mapping.dart';
import '../../lib/state/saved_mappings_state.dart';

void main() {
  late SavedMappingsState savedMappingsState;

  setUp(() {
    savedMappingsState = SavedMappingsState();
  });

  test('Loading and unloading mappings maintains unique configuration fields',
      () {
    // Create first mapping with its configuration fields
    final mapping1 = SavedMapping(
      eventName: 'Test Event 1',
      product: 'Product1',
      query: '',
      mappings: [
        {'source': 'source1', 'target': 'target1', 'isComplex': 'false'}
      ],
      configFields: {
        'endpointId': '1',
        'eventType': 'TYPE1',
        'accountKeyField': 'account1',
        'userKeyField': 'user1',
      },
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      rawSamples: [
        {'field1': 'value1'}
      ],
    );

    // Create second mapping with different configuration fields
    final mapping2 = SavedMapping(
      eventName: 'Test Event 2',
      product: 'Product2',
      query: '',
      mappings: [
        {'source': 'source2', 'target': 'target2', 'isComplex': 'false'}
      ],
      configFields: {
        'endpointId': '2',
        'eventType': 'TYPE2',
        'accountKeyField': 'account2',
        'userKeyField': 'user2',
      },
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      rawSamples: [
        {'field2': 'value2'}
      ],
    );

    // Create third mapping with different configuration fields
    final mapping3 = SavedMapping(
      eventName: 'Test Event 3',
      product: 'Product3',
      query: '',
      mappings: [
        {'source': 'source3', 'target': 'target3', 'isComplex': 'false'}
      ],
      configFields: {
        'endpointId': '3',
        'eventType': 'TYPE3',
        'accountKeyField': 'account3',
        'userKeyField': 'user3',
      },
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      rawSamples: [
        {'field3': 'value3'}
      ],
    );

    // Save all mappings
    savedMappingsState.createMapping(mapping1);
    savedMappingsState.createMapping(mapping2);
    savedMappingsState.createMapping(mapping3);

    // Load and verify first mapping
    savedMappingsState.setSelectedProduct(mapping1.product);
    var loadedMapping = savedMappingsState.getMappings(mapping1.product).first;
    expect(loadedMapping.configFields['endpointId'], equals('1'));
    expect(loadedMapping.configFields['eventType'], equals('TYPE1'));
    expect(loadedMapping.configFields['accountKeyField'], equals('account1'));
    expect(loadedMapping.configFields['userKeyField'], equals('user1'));

    // Load and verify second mapping
    savedMappingsState.setSelectedProduct(mapping2.product);
    loadedMapping = savedMappingsState.getMappings(mapping2.product).first;
    expect(loadedMapping.configFields['endpointId'], equals('2'));
    expect(loadedMapping.configFields['eventType'], equals('TYPE2'));
    expect(loadedMapping.configFields['accountKeyField'], equals('account2'));
    expect(loadedMapping.configFields['userKeyField'], equals('user2'));

    // Load and verify third mapping
    savedMappingsState.setSelectedProduct(mapping3.product);
    loadedMapping = savedMappingsState.getMappings(mapping3.product).first;
    expect(loadedMapping.configFields['endpointId'], equals('3'));
    expect(loadedMapping.configFields['eventType'], equals('TYPE3'));
    expect(loadedMapping.configFields['accountKeyField'], equals('account3'));
    expect(loadedMapping.configFields['userKeyField'], equals('user3'));

    // Load first mapping again and verify it hasn't changed
    savedMappingsState.setSelectedProduct(mapping1.product);
    loadedMapping = savedMappingsState.getMappings(mapping1.product).first;
    expect(loadedMapping.configFields['endpointId'], equals('1'));
    expect(loadedMapping.configFields['eventType'], equals('TYPE1'));
    expect(loadedMapping.configFields['accountKeyField'], equals('account1'));
    expect(loadedMapping.configFields['userKeyField'], equals('user1'));

    // Load second mapping again and verify it hasn't changed
    savedMappingsState.setSelectedProduct(mapping2.product);
    loadedMapping = savedMappingsState.getMappings(mapping2.product).first;
    expect(loadedMapping.configFields['endpointId'], equals('2'));
    expect(loadedMapping.configFields['eventType'], equals('TYPE2'));
    expect(loadedMapping.configFields['accountKeyField'], equals('account2'));
    expect(loadedMapping.configFields['userKeyField'], equals('user2'));

    // Load third mapping again and verify it hasn't changed
    savedMappingsState.setSelectedProduct(mapping3.product);
    loadedMapping = savedMappingsState.getMappings(mapping3.product).first;
    expect(loadedMapping.configFields['endpointId'], equals('3'));
    expect(loadedMapping.configFields['eventType'], equals('TYPE3'));
    expect(loadedMapping.configFields['accountKeyField'], equals('account3'));
    expect(loadedMapping.configFields['userKeyField'], equals('user3'));

    // Cycle through all mappings multiple times to ensure no persistence of initial settings
    for (var i = 0; i < 3; i++) {
      // Load first mapping
      savedMappingsState.setSelectedProduct(mapping1.product);
      loadedMapping = savedMappingsState.getMappings(mapping1.product).first;
      expect(loadedMapping.configFields['endpointId'], equals('1'));
      expect(loadedMapping.configFields['eventType'], equals('TYPE1'));

      // Load second mapping
      savedMappingsState.setSelectedProduct(mapping2.product);
      loadedMapping = savedMappingsState.getMappings(mapping2.product).first;
      expect(loadedMapping.configFields['endpointId'], equals('2'));
      expect(loadedMapping.configFields['eventType'], equals('TYPE2'));

      // Load third mapping
      savedMappingsState.setSelectedProduct(mapping3.product);
      loadedMapping = savedMappingsState.getMappings(mapping3.product).first;
      expect(loadedMapping.configFields['endpointId'], equals('3'));
      expect(loadedMapping.configFields['eventType'], equals('TYPE3'));
    }
  });

  test('Configuration fields are saved independently for each mapping', () {
    // Create first mapping with its configuration fields
    final mapping1 = SavedMapping(
      eventName: 'Test Event 1',
      product: 'Product1',
      query: '',
      mappings: [
        {
          'source': 'source1',
          'target': 'target1',
          'isComplex': 'false',
          'tokens': '[]',
          'jsonataExpr': '',
        }
      ],
      configFields: {
        'endpointId': '1',
        'eventType': 'TYPE1',
        'accountKeyField': 'account1',
        'userKeyField': 'user1',
      },
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      rawSamples: [
        {'field1': 'value1'}
      ],
    );

    // Create second mapping with different configuration fields
    final mapping2 = SavedMapping(
      eventName: 'Test Event 2',
      product: 'Product2',
      query: '',
      mappings: [
        {
          'source': 'source2',
          'target': 'target2',
          'isComplex': 'false',
          'tokens': '[]',
          'jsonataExpr': '',
        }
      ],
      configFields: {
        'endpointId': '2',
        'eventType': 'TYPE2',
        'accountKeyField': 'account2',
        'userKeyField': 'user2',
      },
      totalFieldsMapped: 1,
      requiredFieldsMapped: 1,
      totalRequiredFields: 1,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      rawSamples: [
        {'field2': 'value2'}
      ],
    );

    // Save both mappings
    savedMappingsState.createMapping(mapping1);
    savedMappingsState.createMapping(mapping2);

    // Verify first mapping's configuration fields
    savedMappingsState.setSelectedProduct(mapping1.product);
    final firstMapping = savedMappingsState.getMappings(mapping1.product).first;
    expect(firstMapping.configFields['endpointId'], equals('1'));
    expect(firstMapping.configFields['eventType'], equals('TYPE1'));
    expect(firstMapping.configFields['accountKeyField'], equals('account1'));
    expect(firstMapping.configFields['userKeyField'], equals('user1'));

    // Verify second mapping's configuration fields
    savedMappingsState.setSelectedProduct(mapping2.product);
    final secondMapping =
        savedMappingsState.getMappings(mapping2.product).first;
    expect(secondMapping.configFields['endpointId'], equals('2'));
    expect(secondMapping.configFields['eventType'], equals('TYPE2'));
    expect(secondMapping.configFields['accountKeyField'], equals('account2'));
    expect(secondMapping.configFields['userKeyField'], equals('user2'));

    // Modify second mapping's configuration fields
    final modifiedMapping = secondMapping.copyWith(
      configFields: {
        ...secondMapping.configFields,
        'endpointId': '3',
        'eventType': 'TYPE3',
      },
    );
    savedMappingsState.updateMapping(
      mapping2.product,
      mapping2.eventName,
      modifiedMapping,
    );

    // Verify second mapping was updated
    final updatedSecondMapping =
        savedMappingsState.getMappings(mapping2.product).first;
    expect(updatedSecondMapping.configFields['endpointId'], equals('3'));
    expect(updatedSecondMapping.configFields['eventType'], equals('TYPE3'));
    expect(updatedSecondMapping.configFields['accountKeyField'],
        equals('account2'));
    expect(updatedSecondMapping.configFields['userKeyField'], equals('user2'));

    // Verify first mapping remains unchanged
    savedMappingsState.setSelectedProduct(mapping1.product);
    final unchangedFirstMapping =
        savedMappingsState.getMappings(mapping1.product).first;
    expect(unchangedFirstMapping.configFields['endpointId'], equals('1'));
    expect(unchangedFirstMapping.configFields['eventType'], equals('TYPE1'));
    expect(unchangedFirstMapping.configFields['accountKeyField'],
        equals('account1'));
    expect(unchangedFirstMapping.configFields['userKeyField'], equals('user1'));
  });
}
