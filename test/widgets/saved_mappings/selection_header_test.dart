import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sa_rc_live/widgets/saved_mappings/selection_header.dart';

void main() {
  testWidgets('displays correct selection count for single item',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectionHeader(
            selectedCount: 1,
          ),
        ),
      ),
    );

    expect(find.text('1 item selected'), findsOneWidget);
  });

  testWidgets('displays correct selection count for multiple items',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectionHeader(
            selectedCount: 3,
          ),
        ),
      ),
    );

    expect(find.text('3 items selected'), findsOneWidget);
  });

  testWidgets('shows all action buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectionHeader(
            selectedCount: 1,
          ),
        ),
      ),
    );

    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Clear selection'), findsOneWidget);
  });

  testWidgets('calls onDelete when delete button is pressed', (tester) async {
    bool deleteCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionHeader(
            selectedCount: 1,
            onDelete: () => deleteCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    expect(deleteCalled, true);
  });

  testWidgets('calls onExport when export button is pressed', (tester) async {
    bool exportCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionHeader(
            selectedCount: 1,
            onExport: () => exportCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Export'));
    expect(exportCalled, true);
  });

  testWidgets('calls onClearSelection when clear button is pressed',
      (tester) async {
    bool clearCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionHeader(
            selectedCount: 1,
            onClearSelection: () => clearCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear selection'));
    expect(clearCalled, true);
  });
}
