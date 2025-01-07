import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sa_rc_live/models/saved_mapping.dart';
import 'package:sa_rc_live/widgets/saved_mappings/saved_mapping_table_row.dart';

void main() {
  late SavedMapping testMapping;

  setUp(() {
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

  testWidgets('renders all mapping information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
          ),
        ),
      ),
    );

    expect(find.text('Test Mapping'), findsOneWidget);
    expect(find.text('TestProduct'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5/8'), findsOneWidget);
    expect(find.text('2024-01-02'), findsOneWidget);
  });

  testWidgets('shows selection checkbox when onSelect provided',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('hides selection checkbox when onSelect not provided',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('shows warning icon for duplicate query', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
            hasDuplicateQuery: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('calls onLoad when load button pressed', (tester) async {
    bool loadCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
            onLoad: () => loadCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(loadCalled, true);
  });

  testWidgets('calls onDuplicate when duplicate button pressed',
      (tester) async {
    bool duplicateCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
            onDuplicate: () => duplicateCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy));
    expect(duplicateCalled, true);
  });

  testWidgets('calls onDelete when delete button pressed', (tester) async {
    bool deleteCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableRow(
            mapping: testMapping,
            onDelete: () => deleteCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleteCalled, true);
  });
}
