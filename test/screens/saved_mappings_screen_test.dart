import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sa_rc_live/models/saved_mapping.dart';
import 'package:sa_rc_live/screens/saved_mappings_screen.dart';
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
      totalFieldsMapped: 10,
      requiredFieldsMapped: 5,
      totalRequiredFields: 8,
      createdAt: DateTime(2024, 1, 1),
      modifiedAt: DateTime(2024, 1, 2),
    );
  });

  Widget buildScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: state,
        child: const Scaffold(
          body: SavedMappingsScreen(),
        ),
      ),
    );
  }

  testWidgets('shows message when no product is selected', (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.text('Please select a product to view saved mappings'),
        findsOneWidget);
  });

  testWidgets('shows empty state message when no mappings exist',
      (tester) async {
    state.setSelectedProduct('TestProduct');
    await tester.pumpWidget(buildScreen());
    expect(find.text('No saved mappings for this product'), findsOneWidget);
  });

  testWidgets('displays mapping when one exists', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    await tester.pumpWidget(buildScreen());

    expect(find.text('Test Mapping'), findsOneWidget);
    expect(find.text('TestProduct'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5/8'), findsOneWidget);
  });

  testWidgets('can select and deselect mapping', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    await tester.pumpWidget(buildScreen());

    // Initially no selection header
    expect(find.text('1 item selected'), findsNothing);

    // Select the mapping
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('1 item selected'), findsOneWidget);

    // Deselect the mapping
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('1 item selected'), findsNothing);
  });

  testWidgets('can select all mappings', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    state.createMapping(testMapping.copyWith(name: 'Test Mapping 2'));
    await tester.pumpWidget(buildScreen());

    // Select all mappings
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('2 items selected'), findsOneWidget);

    // Deselect all mappings
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('2 items selected'), findsNothing);
  });

  testWidgets('can sort mappings by name', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping.copyWith(name: 'B Mapping'));
    state.createMapping(testMapping.copyWith(name: 'A Mapping'));
    await tester.pumpWidget(buildScreen());

    // Initial order
    expect(
      tester.widget<Text>(find.text('B Mapping')).textAlign,
      null,
    );

    // Sort by name
    await tester.tap(find.text('Name'));
    await tester.pump();

    // Verify sort indicator
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Reverse sort
    await tester.tap(find.text('Name'));
    await tester.pump();

    // Verify sort indicator changed
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('shows duplicate query indicator', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    state.createMapping(testMapping.copyWith(
      name: 'Test Mapping 2',
      query: 'test query',
    ));
    await tester.pumpWidget(buildScreen());

    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
  });

  testWidgets('can duplicate mapping', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(find.text('Copy of Test Mapping'), findsOneWidget);
  });

  testWidgets('shows delete confirmation dialog', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('Delete Mapping'), findsOneWidget);
    expect(find.text('Are you sure you want to delete "Test Mapping"?'),
        findsOneWidget);
  });

  testWidgets('shows bulk delete confirmation dialog', (tester) async {
    state.setSelectedProduct('TestProduct');
    state.createMapping(testMapping);
    state.createMapping(testMapping.copyWith(name: 'Test Mapping 2'));
    await tester.pumpWidget(buildScreen());

    // Select all mappings
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    // Click delete button
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(find.text('Delete Selected Mappings'), findsOneWidget);
    expect(find.text('Are you sure you want to delete 2 mappings?'),
        findsOneWidget);
  });
}
