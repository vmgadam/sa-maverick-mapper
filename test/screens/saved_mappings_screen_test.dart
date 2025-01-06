import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/models/saved_mapping.dart';
import '../../lib/screens/saved_mappings_screen.dart';
import '../../lib/state/mapping_state.dart';
import '../../lib/services/mapping_export_service.dart';
import '../../lib/services/field_mapping_service.dart';

void main() {
  late MappingState mappingState;
  late MappingExportService exportService;
  late FieldMappingService fieldMappingService;

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<MappingState>.value(value: mappingState),
          Provider<MappingExportService>.value(value: exportService),
          Provider<FieldMappingService>.value(value: fieldMappingService),
        ],
        child: const SavedMappingsScreen(),
      ),
    );
  }

  setUp(() {
    mappingState = MappingState();
    exportService = MappingExportService();
    fieldMappingService = FieldMappingService();

    // Add some test mappings
    mappingState.addSavedMapping(SavedMapping(
      name: 'Test Mapping 1',
      product: 'Test App',
      query: '{"term": "test1"}',
      mappings: [
        {'source': 'test1', 'target': 'test1', 'isComplex': 'false'}
      ],
      configFields: {},
      totalFieldsMapped: 1,
      requiredFieldsMapped: 0,
      totalRequiredFields: 0,
    ));

    mappingState.addSavedMapping(SavedMapping(
      name: 'Test Mapping 2',
      product: 'Test App',
      query: '{"term": "test2"}',
      mappings: [
        {'source': 'test2', 'target': 'test2', 'isComplex': 'false'}
      ],
      configFields: {},
      totalFieldsMapped: 1,
      requiredFieldsMapped: 0,
      totalRequiredFields: 0,
    ));
  });

  group('SavedMappingsScreen Load Tests', () {
    testWidgets('handles save first option correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select both mappings
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      // Find and tap the bulk update button
      final bulkUpdateButton = find.byKey(const Key('bulk_update_button'));
      expect(bulkUpdateButton, findsOneWidget);
      await tester.tap(bulkUpdateButton);
      await tester.pumpAndSettle();

      // Verify bulk update dialog is shown
      expect(find.text('Bulk Field Update'), findsOneWidget);
    });
  });
}
