import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/saved_mapping.dart';
import '../widgets/json_preview_widget.dart';

class ExportService {
  static void exportMapping(SavedMapping mapping, String format) {
    switch (format) {
      case 'json':
        _exportMappingAsJson(mapping);
        break;
      case 'csv':
        _exportMappingAsCsv(mapping);
        break;
    }
  }

  static void exportMappings(List<SavedMapping> mappings, String format) {
    switch (format) {
      case 'json':
        _exportMappingsAsJson(mappings);
        break;
      case 'csv':
        _exportMappingsAsCsv(mappings);
        break;
    }
  }

  static void _exportMappingAsJson(SavedMapping mapping) {
    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(mapping.toJson());
    // TODO: Implement file download
  }

  static void _exportMappingsAsJson(List<SavedMapping> mappings) {
    final jsonList = mappings.map((m) => m.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);
    // TODO: Implement file download
  }

  static void _exportMappingAsCsv(SavedMapping mapping) {
    // TODO: Implement CSV export for single mapping
  }

  static void _exportMappingsAsCsv(List<SavedMapping> mappings) {
    // TODO: Implement CSV export for multiple mappings
  }

  static String generateCSVContent({
    required List<Map<String, dynamic>> mappings,
    required Map<String, dynamic> currentEvent,
    required String? selectedAppId,
    required List<dynamic> apps,
    required Function(Map<String, dynamic>, String) getNestedValue,
    required List<dynamic> saasFields,
  }) {
    final csvRows = <String>[];
    csvRows.add(
        '"Product Name","Source App","Source Field Name","SaaS Alerts Field Name","SaaS Alerts Field Description"');

    for (final mapping in mappings) {
      final targetField = mapping['target']!;
      final isComplex = mapping['isComplex'] == 'true';
      final appName = apps.firstWhere(
        (app) => app['id'].toString() == selectedAppId,
        orElse: () => {'name': 'Unknown App'},
      )['name'];

      final saasField = saasFields.firstWhere(
        (field) => field['name'] == targetField,
        orElse: () => {'name': targetField, 'description': ''},
      );

      final sourceField =
          isComplex ? mapping['jsonataExpr'] ?? '' : mapping['source'] ?? '';

      csvRows.add([
        'RocketCyber',
        appName,
        sourceField,
        targetField,
        saasField['description'],
      ]
          .map((field) => '"${field.toString().replaceAll('"', '""')}"')
          .join(','));
    }

    return csvRows.join('\n');
  }

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

  static void showJSONExportDialog(BuildContext context,
      {required Widget jsonPreviewWidget}) {
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
