import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sa_maverick_mapper/models/mapping_state.dart';
import 'package:sa_maverick_mapper/screens/unified_mapper_screen.dart';
import 'package:sa_maverick_mapper/services/api_service.dart';
import 'package:sa_maverick_mapper/services/saas_alerts_api.dart';

void main() {
  group('UnifiedMapperScreen', () {
    late MappingState mappingState;
    late ApiService apiService;
    late SaasAlertsApi saasAlertsApi;

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<MappingState>(
          create: (_) => mappingState,
          child: const UnifiedMapperScreen(),
        ),
      );
    }

    setUp(() {
      apiService = ApiService();
      saasAlertsApi = SaasAlertsApi();
      mappingState = MappingState(
        apiService: apiService,
        saasAlertsApi: saasAlertsApi,
      );
    });

    testWidgets('Save button shows save dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap the save button
      final saveButton = find.byKey(const Key('save_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify save dialog is shown
      expect(find.text('Save Mapping'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Save dialog validates mapping name',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap the save button
      final saveButton = find.byKey(const Key('save_button'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Try to save with empty name
      final saveDialogButton = find.text('Save');
      await tester.tap(saveDialogButton);
      await tester.pumpAndSettle();

      // Verify validation message
      expect(find.text('Please enter a name for the mapping'), findsOneWidget);
    });
  });
}
