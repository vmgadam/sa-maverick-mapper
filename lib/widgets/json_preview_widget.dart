import 'dart:convert';
import 'package:flutter/material.dart';

class JsonPreviewWidget extends StatelessWidget {
  final String jsonContent;
  final VoidCallback? onExport;
  final bool showExportButton;
  final String? title;

  const JsonPreviewWidget({
    super.key,
    required this.jsonContent,
    this.onExport,
    this.showExportButton = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'JSON Preview'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showExportButton && onExport != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: onExport,
                    tooltip: 'Export JSON',
                  ),
                ],
              ),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
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
      ],
    );
  }
}
