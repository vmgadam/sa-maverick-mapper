import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/models/saved_mapping.dart';
import '../../lib/widgets/bulk_field_update_dialog.dart';
import '../../lib/widgets/complex_mapping_editor.dart';
import '../../lib/state/mapping_state.dart';

void main() {
  late List<SavedMapping> selectedMappings;
  late List<String> availableFields;
  late Map<String, String> sampleValues;
  late MappingState mappingState;

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<MappingState>(
        create: (_) => mappingState,
        child: Builder(
          builder: (context) => Scaffold(
            body: BulkFieldUpdateDialog(
              selectedMappings: selectedMappings,
              availableFields: availableFields,
              sampleValues: sampleValues,
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    mappingState = MappingState();
    selectedMappings = [
      SavedMapping(
        name: 'Test Mapping 1',
        product: 'Test Product',
        query: 'test query',
        mappings: [
          {'source': 'field1', 'target': 'target1', 'isComplex': 'false'},
        ],
        configFields: {},
        totalFieldsMapped: 1,
        requiredFieldsMapped: 0,
        totalRequiredFields: 0,
      ),
      SavedMapping(
        name: 'Test Mapping 2',
        product: 'Test Product',
        query: 'test query',
        mappings: [
          {'source': 'field2', 'target': 'target1', 'isComplex': 'false'},
        ],
        configFields: {},
        totalFieldsMapped: 1,
        requiredFieldsMapped: 0,
        totalRequiredFields: 0,
      ),
    ];
    availableFields = ['field1', 'field2', 'field3'];
    sampleValues = {
      'field1': 'value1',
      'field2': 'value2',
      'field3': 'value3',
    };
  });

  group('BulkFieldUpdateDialog', () {
    testWidgets('allows switching between simple and complex mapping',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Select a field first
      await tester.tap(find.byKey(const Key('target_field_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('target1').first);
      await tester.pumpAndSettle();

      // Verify initial state is simple mapping
      expect(find.text('Simple'), findsOneWidget);
      expect(find.text('Complex'), findsOneWidget);
      expect(find.byKey(const Key('field_selector_dropdown')), findsOneWidget);

      // Switch to complex mapping
      await tester.tap(find.text('Complex'));
      await tester.pumpAndSettle();

      // Verify complex mapping editor is shown
      expect(find.byType(ComplexMappingEditor), findsOneWidget);
      expect(find.byKey(const Key('field_selector_dropdown')), findsNothing);
    });

    testWidgets('validates input before applying changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select a target field
      await tester.tap(find.byKey(const Key('target_field_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('target1').first);
      await tester.pumpAndSettle();

      // Select a source field
      await tester.tap(find.byKey(const Key('field_selector_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('field1 (value1)').first);
      await tester.pumpAndSettle();

      // Verify apply button is enabled and has correct text
      final applyButton = find.byKey(const Key('apply_button'));
      expect(applyButton, findsOneWidget);
      expect(find.text('Apply to Selected'), findsOneWidget);
      expect(tester.widget<TextButton>(applyButton).enabled, isTrue);

      // Apply changes
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(BulkFieldUpdateDialog), findsNothing);
    });
  });
}
