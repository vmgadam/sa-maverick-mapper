import 'dart:convert';
import 'package:flutter/material.dart';

class JsonPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> jsonData;
  final VoidCallback? onExport;
  final bool showExportButton;
  final String? title;

  const JsonPreviewWidget({
    super.key,
    required this.jsonData,
    this.onExport,
    this.showExportButton = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              const Icon(Icons.code, size: 16),
              const SizedBox(width: 8),
              Text(
                title!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (showExportButton && onExport != null)
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: onExport,
                  tooltip: 'Export JSON',
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(jsonData),
            ),
          ),
        ),
      ],
    );
  }
}
