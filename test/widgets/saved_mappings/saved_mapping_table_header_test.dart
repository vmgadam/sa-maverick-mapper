import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sa_rc_live/widgets/saved_mappings/saved_mapping_table_header.dart';

void main() {
  testWidgets('renders all column headers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(),
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Fields Mapped'), findsOneWidget);
    expect(find.text('Required Fields'), findsOneWidget);
    expect(find.text('Last Modified'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
  });

  testWidgets('shows selection checkbox when hasSelection is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(
            hasSelection: true,
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('hides selection checkbox when hasSelection is false',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(
            hasSelection: false,
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('shows sort indicator for selected field', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(
            sortField: SavedMappingSortField.name,
            sortAscending: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('shows descending sort indicator when sortAscending is false',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(
            sortField: SavedMappingSortField.name,
            sortAscending: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('calls onSort when header is clicked', (tester) async {
    SavedMappingSortField? sortedField;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(
            onSort: (field) => sortedField = field,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Name'));
    expect(sortedField, SavedMappingSortField.name);

    await tester.tap(find.text('Product'));
    expect(sortedField, SavedMappingSortField.product);
  });

  testWidgets('calls onSelectAll when checkbox is clicked', (tester) async {
    bool? selectionState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedMappingTableHeader(
            hasSelection: true,
            allSelected: false,
            onSelectAll: (selected) => selectionState = selected,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(selectionState, true);
  });
}
