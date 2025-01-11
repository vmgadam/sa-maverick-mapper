import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/models/saved_mapping.dart';
import '../../lib/models/saas_field.dart';
import '../../lib/screens/unified_mapper_screen.dart';
import '../../lib/services/api_service.dart';
import '../../lib/services/saas_alerts_api_service.dart';
import '../../lib/state/mapping_state.dart';
import '../../lib/state/saved_mappings_state.dart';
import '../../lib/widgets/configuration/configuration_section.dart';

class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'http://mock.api', apiToken: 'mock-token');

  @override
  Future<Map<String, dynamic>?> getApps() async => {'data': []};
}

class MockSaasAlertsApi extends SaasAlertsApiService {
  MockSaasAlertsApi() : super(apiKey: 'mock-key');

  @override
  Future<Map<String, dynamic>?> getFields() async => {
        'fields': {
          'endpointId': {
            'name': 'endpointId',
            'type': 'text',
            'required': true,
            'category': 'configuration',
            'description': 'Endpoint ID',
          },
          'eventType': {
            'name': 'eventType',
            'type': 'text',
            'required': true,
            'category': 'configuration',
            'description': 'Event Type',
          },
        }
      };
}

void main() {
  late SavedMappingsState savedMappingsState;
  late MappingState mappingState;
  late ApiService mockApiService;
  late SaasAlertsApiService mockSaasAlertsApi;

  // Create three different test mappings with distinct configuration fields
  final testMapping1 = SavedMapping(
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

  final testMapping2 = SavedMapping(
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

  final testMapping3 = SavedMapping(
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

  setUp(() {
    savedMappingsState = SavedMappingsState();
    mappingState = MappingState();
    mockApiService = MockApiService();
    mockSaasAlertsApi = MockSaasAlertsApi();
  });

  testWidgets(
      'UI correctly loads and unloads mappings without persisting initial settings',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SavedMappingsState>(
            create: (_) => savedMappingsState,
          ),
          ChangeNotifierProvider<MappingState>(
            create: (_) => mappingState,
          ),
        ],
        child: MaterialApp(
          home: UnifiedMapperScreen(
            apiService: mockApiService,
            saasAlertsApi: mockSaasAlertsApi,
          ),
        ),
      ),
    );

    // Wait for the SaaS fields to load
    await tester.pumpAndSettle();

    // Save all mappings
    savedMappingsState.createMapping(testMapping1);
    savedMappingsState.createMapping(testMapping2);
    savedMappingsState.createMapping(testMapping3);
    await tester.pump();

    // Function to verify configuration fields in the UI
    Future<void> verifyConfigFields(SavedMapping mapping) async {
      // Find the configuration fields section
      final configSection = find.byType(ConfigurationSection);
      expect(configSection, findsOneWidget);

      // Verify endpointId field
      final endpointIdField = find.text(mapping.configFields['endpointId']!);
      expect(endpointIdField, findsOneWidget);

      // Verify eventType field
      final eventTypeField = find.text(mapping.configFields['eventType']!);
      expect(eventTypeField, findsOneWidget);
    }

    // Load and verify first mapping
    savedMappingsState.setSelectedProduct(testMapping1.product);
    await tester.pumpAndSettle();
    await verifyConfigFields(testMapping1);

    // Load and verify second mapping
    savedMappingsState.setSelectedProduct(testMapping2.product);
    await tester.pumpAndSettle();
    await verifyConfigFields(testMapping2);

    // Load and verify third mapping
    savedMappingsState.setSelectedProduct(testMapping3.product);
    await tester.pumpAndSettle();
    await verifyConfigFields(testMapping3);

    // Cycle through mappings multiple times to ensure no persistence
    for (var i = 0; i < 3; i++) {
      savedMappingsState.setSelectedProduct(testMapping1.product);
      await tester.pumpAndSettle();
      await verifyConfigFields(testMapping1);

      savedMappingsState.setSelectedProduct(testMapping2.product);
      await tester.pumpAndSettle();
      await verifyConfigFields(testMapping2);

      savedMappingsState.setSelectedProduct(testMapping3.product);
      await tester.pumpAndSettle();
      await verifyConfigFields(testMapping3);
    }
  });

  testWidgets('Save, load, change, save, load cycle maintains correct state',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SavedMappingsState>(
            create: (_) => savedMappingsState,
          ),
          ChangeNotifierProvider<MappingState>(
            create: (_) => mappingState,
          ),
        ],
        child: MaterialApp(
          home: UnifiedMapperScreen(
            apiService: mockApiService,
            saasAlertsApi: mockSaasAlertsApi,
          ),
        ),
      ),
    );

    // Wait for the SaaS fields to load
    await tester.pumpAndSettle();

    // Initial state - create and save first mapping
    savedMappingsState.createMapping(testMapping1);
    await tester.pump();

    // Load first mapping
    savedMappingsState.setSelectedProduct(testMapping1.product);
    await tester.pumpAndSettle();
    final firstMapping =
        savedMappingsState.getMappings(testMapping1.product).first;
    expect(firstMapping.configFields['endpointId'], equals('1'));
    expect(firstMapping.configFields['eventType'], equals('TYPE1'));

    // Create and save second mapping
    savedMappingsState.createMapping(testMapping2);
    await tester.pump();

    // Load second mapping
    savedMappingsState.setSelectedProduct(testMapping2.product);
    await tester.pumpAndSettle();
    final secondMapping =
        savedMappingsState.getMappings(testMapping2.product).first;
    expect(secondMapping.configFields['endpointId'], equals('2'));
    expect(secondMapping.configFields['eventType'], equals('TYPE2'));

    // Modify second mapping
    final modifiedMapping = secondMapping.copyWith(
      configFields: {
        ...secondMapping.configFields,
        'endpointId': '3',
        'eventType': 'TYPE3',
      },
    );
    savedMappingsState.updateMapping(
      testMapping2.product,
      testMapping2.eventName,
      modifiedMapping,
    );
    await tester.pump();

    // Verify second mapping was updated
    final updatedSecondMapping =
        savedMappingsState.getMappings(testMapping2.product).first;
    expect(updatedSecondMapping.configFields['endpointId'], equals('3'));
    expect(updatedSecondMapping.configFields['eventType'], equals('TYPE3'));

    // Load first mapping again and verify it's unchanged
    savedMappingsState.setSelectedProduct(testMapping1.product);
    await tester.pumpAndSettle();
    final unchangedFirstMapping =
        savedMappingsState.getMappings(testMapping1.product).first;
    expect(unchangedFirstMapping.configFields['endpointId'], equals('1'));
    expect(unchangedFirstMapping.configFields['eventType'], equals('TYPE1'));
  });
}
