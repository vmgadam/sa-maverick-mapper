import 'package:flutter/material.dart';
import '../models/saved_mapping.dart';
import './complex_mapping_editor.dart';
import 'dart:convert';

class BulkFieldUpdateDialog extends StatefulWidget {
  final List<SavedMapping> selectedMappings;
  final List<String> availableFields;
  final Map<String, String> sampleValues;

  const BulkFieldUpdateDialog({
    super.key,
    required this.selectedMappings,
    required this.availableFields,
    required this.sampleValues,
  });

  @override
  State<BulkFieldUpdateDialog> createState() => _BulkFieldUpdateDialogState();
}

class _BulkFieldUpdateDialogState extends State<BulkFieldUpdateDialog> {
  String? selectedField;
  List<Map<String, String>> tokens = [];
  bool isComplex = false;
  String? simpleFieldValue;

  @override
  void initState() {
    super.initState();
    if (widget.availableFields.isNotEmpty) {
      simpleFieldValue = widget.availableFields.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all unique target fields from selected mappings
    final targetFields = widget.selectedMappings
        .expand((m) => m.mappings)
        .map((m) => m['target'] as String)
        .toSet()
        .toList()
      ..sort();

    return AlertDialog(
      title: const Text('Bulk Field Update'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update the selected field in all selected mappings:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('target_field_dropdown'),
                    value: selectedField,
                    decoration: const InputDecoration(
                      labelText: 'Field to Update',
                    ),
                    items: targetFields.map((field) {
                      return DropdownMenuItem(
                        value: field,
                        child: Text(field),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedField = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Simple'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Complex'),
                      ),
                    ],
                    selected: {isComplex},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        isComplex = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isComplex) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('field_selector_dropdown'),
                      value: simpleFieldValue,
                      decoration: const InputDecoration(
                        labelText: 'Source Field',
                      ),
                      items: widget.availableFields.map((field) {
                        final sampleValue = widget.sampleValues[field] ?? '';
                        return DropdownMenuItem(
                          value: field,
                          child: Text('$field ($sampleValue)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          simpleFieldValue = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              ComplexMappingEditor(
                sourceFields: widget.availableFields,
                currentEvent: widget.sampleValues,
                initialTokens: tokens,
                sampleValues: widget.sampleValues,
                onSave: (expression, newTokens) {
                  setState(() {
                    tokens = newTokens;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('apply_button'),
          onPressed: () {
            if (isComplex && tokens.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please configure the complex mapping'),
                ),
              );
              return;
            }
            Navigator.of(context).pop({
              'field': selectedField,
              'isComplex': isComplex,
              'mapping': isComplex ? jsonEncode(tokens) : simpleFieldValue,
            });
          },
          child: const Text('Apply to Selected'),
        ),
      ],
    );
  }
}
