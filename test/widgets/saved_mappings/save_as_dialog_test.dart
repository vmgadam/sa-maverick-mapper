import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sa_rc_live/models/saved_mapping.dart';
import 'package:sa_rc_live/state/saved_mappings_state.dart';
import 'package:sa_rc_live/widgets/saved_mappings/save_as_dialog.dart';

void main() {
  late SavedMappingsState state;

  setUp(() {
    state = SavedMappingsState();
  });

  Widget buildDialog() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider.value(
          value: state,
          child: const SaveAsDialog(
            product: 'TestProduct',
            query: 'test query',
            mappings: [
              {'source': 'test', 'target': 'test'}
            ],
            configFields: {'field': 'value'},
            totalFieldsMapped: 1,
            requiredFieldsMapped: 1,
            totalRequiredFields: 1,
          ),
        ),
      ),
    );
  }

  testWidgets('renders dialog with form fields', (tester) async {
    await tester.pumpWidget(buildDialog());

    expect(find.text('Save Mapping As'), findsOneWidget);
    expect(find.text('Mapping Name'), findsOneWidget);
    expect(find.text('Maximum 200 characters'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('validates empty name', (tester) async {
    await tester.pumpWidget(buildDialog());

    // Try to save without entering a name
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name'), findsOneWidget);
  });

  test('SavedMapping validates name length', () {
    expect(
      () => SavedMapping(
        name: 'a' * 201,
        product: 'test',
        query: 'test',
        mappings: [],
        configFields: {},
        totalFieldsMapped: 0,
        requiredFieldsMapped: 0,
        totalRequiredFields: 0,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ),
      throwsArgumentError,
    );
  });

  testWidgets('shows error for duplicate name', (tester) async {
    // Add an existing mapping
    state.createMapping(SavedMapping(
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
    ));

    await tester.pumpWidget(buildDialog());

    // Try to save with the same name
    await tester.enterText(find.byType(TextFormField), 'Test Mapping');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Exception: A mapping with this name already exists'),
        findsOneWidget);
  });

  testWidgets('saves mapping successfully', (tester) async {
    await tester.pumpWidget(buildDialog());

    // Enter a valid name
    await tester.enterText(find.byType(TextFormField), 'New Mapping');

    // Save should show loading indicator
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify mapping was created
    final mappings = state.getMappingsForProduct('TestProduct');
    expect(mappings.length, 1);
    expect(mappings.first.name, 'New Mapping');
  });

  testWidgets('cancel closes dialog', (tester) async {
    await tester.pumpWidget(buildDialog());

    // Enter some text
    await tester.enterText(find.byType(TextFormField), 'Test');

    // Click cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify no mapping was created
    final mappings = state.getMappingsForProduct('TestProduct');
    expect(mappings.isEmpty, true);
  });

  testWidgets('disables form during save', (tester) async {
    await tester.pumpWidget(buildDialog());

    // Enter a valid name
    await tester.enterText(find.byType(TextFormField), 'New Mapping');

    // Start save
    await tester.tap(find.text('Save'));
    await tester.pump();

    // Verify form is disabled
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      false,
    );

    // Verify buttons are disabled
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Cancel'),
          )
          .onPressed,
      null,
    );

    // Save button is replaced with loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('enforces maximum name length through TextField', (tester) async {
    await tester.pumpWidget(buildDialog());

    // Try to enter text longer than 200 characters
    final longText = 'a' * 250;
    await tester.enterText(find.byType(TextFormField), longText);
    await tester.pump();

    // Verify text was truncated to 200 characters
    final textField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(textField.controller?.text.length, equals(200));

    // Try to save the truncated text (should work since it's exactly 200 chars)
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify mapping was created with truncated name
    final mappings = state.getMappingsForProduct('TestProduct');
    expect(mappings.length, equals(1));
    expect(mappings.first.name.length, equals(200));
  });
}
