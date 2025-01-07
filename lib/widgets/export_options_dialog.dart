import 'package:flutter/material.dart';

class ExportOptionsDialog extends StatelessWidget {
  final Function(String format) onExport;

  const ExportOptionsDialog({
    super.key,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Mappings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose export format:'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('CSV Format'),
            subtitle: const Text('Export as spreadsheet-compatible CSV'),
            onTap: () {
              Navigator.pop(context);
              onExport('csv');
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('JSON Format'),
            subtitle: const Text('Export as structured JSON with metadata'),
            onTap: () {
              Navigator.pop(context);
              onExport('json');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Shows the export options dialog
  static void show(
    BuildContext context, {
    required Function(String format) onExport,
  }) {
    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        onExport: onExport,
      ),
    );
  }
}
