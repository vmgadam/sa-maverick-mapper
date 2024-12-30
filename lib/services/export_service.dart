import 'package:flutter/material.dart';
import '../screens/unified_mapper_screen.dart';

class ExportService {
  /// Generates CSV content from mappings data
  static String generateCSVContent({
    required List<Map<String, dynamic>> mappings,
    required Map<String, dynamic> currentEvent,
    required String? selectedAppId,
    required List<dynamic> apps,
    required Function(Map<String, dynamic>, String) getNestedValue,
    required List<SaasField> saasFields,
  }) {
    final csvRows = <String>[];

    // Add header row
    csvRows.add(
        '"Product Name","Source App","Source Field Name","SaaS Alerts Field Name","SaaS Alerts Field Description"');

    // Add data rows
    for (final mapping in mappings) {
      final targetField = mapping['target']!;
      final isComplex = mapping['isComplex'] == 'true';
      final appName = apps.firstWhere(
        (app) => app['id'].toString() == selectedAppId,
        orElse: () => {'name': 'Unknown App'},
      )['name'];

      // Find the SaaS Alerts field description
      final saasField = saasFields.firstWhere(
        (field) => field.name == targetField,
        orElse: () => SaasField(
          name: targetField,
          required: false,
          description: '',
          type: 'string',
          defaultMode: 'simple',
          category: 'Standard',
          displayOrder: 999,
          options: null,
        ),
      );

      final sourceField =
          isComplex ? mapping['jsonataExpr'] ?? '' : mapping['source'] ?? '';

      csvRows.add([
        'RocketCyber',
        appName,
        sourceField,
        targetField,
        saasField.description,
      ]
          .map((field) => '"${field.toString().replaceAll('"', '""')}"')
          .join(','));
    }

    return csvRows.join('\n');
  }

  /// Shows the CSV export dialog
  static void showCSVExportDialog(BuildContext context, String csvContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Export'),
        content: SingleChildScrollView(
          child: SelectableText(csvContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows the JSON export dialog using the provided JsonPreviewWidget
  static void showJSONExportDialog(
    BuildContext context, {
    required Widget jsonPreviewWidget,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Mappings JSON'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: jsonPreviewWidget,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
