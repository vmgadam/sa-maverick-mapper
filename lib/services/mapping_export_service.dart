import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_mapping.dart';
import '../widgets/json_preview_widget.dart';

class MappingExportService {
  /// Formats a single mapping for export, maintaining backward compatibility
  static Map<String, dynamic> formatSingleMapping(SavedMapping mapping) {
    return {
      'accountKey': {'field': 'data.id', 'type': 'id'},
      'dateKeyField': 'data.createdAt',
      'endpointId':
          int.tryParse(mapping.configFields['endpointId'] ?? '0') ?? 0,
      'endpointName': 'events',
      'eventFilter': mapping.query.isNotEmpty
          ? mapping.query
          : '{\n  "query": {\n    "bool": {\n      "must": [],\n      "filter": [],\n      "should": [],\n      "must_not": []\n    }\n  }\n}',
      'eventType': mapping.configFields['eventType'] ?? 'EVENT',
      'eventTypeKey': mapping.configFields['eventType'] ?? 'EVENT',
      'productRef': {
        '__ref__': mapping.configFields['productRef'] ?? 'products/default'
      },
      'userKeyField': 'data.userId',
      'schema': mapping.mappings,
      'metadata': {
        'name': mapping.name,
        'product': mapping.product,
        'totalFieldsMapped': mapping.totalFieldsMapped,
        'requiredFieldsMapped': mapping.requiredFieldsMapped,
        'totalRequiredFields': mapping.totalRequiredFields,
        'createdAt': mapping.createdAt.toIso8601String(),
        'modifiedAt': mapping.modifiedAt.toIso8601String(),
      },
    };
  }

  /// Formats multiple mappings for export
  static Map<String, dynamic> formatMultipleMappings(
      List<SavedMapping> mappings) {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'mappings': mappings.map((m) => formatSingleMapping(m)).toList(),
    };
  }

  /// Shows the export dialog for a single mapping
  static void showSingleMappingExportDialog(
    BuildContext context,
    SavedMapping mapping,
  ) {
    final jsonData = formatSingleMapping(mapping);
    _showExportDialog(context, jsonData);
  }

  /// Shows the export dialog for multiple mappings
  static void showMultipleMappingsExportDialog(
    BuildContext context,
    List<SavedMapping> mappings,
  ) {
    final jsonData = formatMultipleMappings(mappings);
    _showExportDialog(context, jsonData);
  }

  /// Internal method to show the export dialog
  static void _showExportDialog(
    BuildContext context,
    Map<String, dynamic> jsonData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Mappings'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: JsonPreviewWidget(
                  jsonData: jsonData,
                  showExportButton: false,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              final jsonString =
                  const JsonEncoder.withIndent('  ').convert(jsonData);
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exported mappings copied to clipboard'),
                ),
              );
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            onPressed: () {
              // TODO: Implement file download
              // This will be platform-specific and may require additional packages
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download functionality coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
