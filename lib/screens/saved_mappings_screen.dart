import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../state/mapping_state.dart';
import '../models/saved_mapping.dart';
import '../widgets/mapping_preview_dialog.dart';
import '../widgets/bulk_field_update_dialog.dart';
import '../services/mapping_export_service.dart';

class SavedMappingsScreen extends StatefulWidget {
  const SavedMappingsScreen({super.key});

  @override
  State<SavedMappingsScreen> createState() => _SavedMappingsScreenState();
}

class _SavedMappingsScreenState extends State<SavedMappingsScreen> {
  final Set<SavedMapping> _selectedMappings = {};

  void _handleRowSelect(SavedMapping mapping, bool? selected) {
    setState(() {
      if (selected ?? false) {
        _selectedMappings.add(mapping);
      } else {
        _selectedMappings.remove(mapping);
      }
    });
  }

  void _handleSelectAll(bool? selected) {
    setState(() {
      if (selected ?? false) {
        _selectedMappings.addAll(context.read<MappingState>().savedMappings);
      } else {
        _selectedMappings.clear();
      }
    });
  }

  void _handleLoad(SavedMapping mapping) {
    // TODO: Load mapping and navigate back
    Navigator.pop(context);
  }

  void _handlePreview(SavedMapping mapping) {
    showDialog(
      context: context,
      builder: (context) => MappingPreviewDialog(mapping: mapping),
    );
  }

  void _handleDuplicate(SavedMapping mapping) {
    context.read<MappingState>().duplicateSavedMapping(mapping);
  }

  void _handleDelete(SavedMapping mapping) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mapping'),
        content: Text('Are you sure you want to delete "${mapping.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MappingState>().deleteSavedMapping(mapping);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleBulkDelete() {
    if (_selectedMappings.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Mappings'),
        content: Text(
            'Are you sure you want to delete ${_selectedMappings.length} mapping(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<MappingState>()
                  .deleteSavedMappings(_selectedMappings.toList());
              setState(() => _selectedMappings.clear());
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleBulkExport() {
    if (_selectedMappings.isEmpty) return;
    _exportMappings(context, _selectedMappings.toList());
  }

  void _handleRevertLastBulk() {
    context.read<MappingState>().revertLastBulkOperation();
  }

  void _loadMapping(BuildContext context, SavedMapping mapping) {
    final mappingState = Provider.of<MappingState>(context, listen: false);
    final currentMappings = mappingState.getCurrentMappings();

    if (currentMappings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'Loading a new mapping will discard any unsaved changes. Would you like to save your changes first?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close SavedMappingsScreen
                // Return to UnifiedMapperScreen without loading
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                mappingState.loadSavedMapping(mapping);
                Navigator.pop(context); // Close SavedMappingsScreen
              },
              child: const Text('Discard and Load'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show save dialog in UnifiedMapperScreen
                Navigator.pop(
                    context, {'action': 'save_and_load', 'mapping': mapping});
              },
              child: const Text('Save First'),
            ),
          ],
        ),
      );
    } else {
      mappingState.loadSavedMapping(mapping);
      Navigator.pop(context); // Close SavedMappingsScreen
    }
  }

  void _confirmBulkDelete(BuildContext context, List<SavedMapping> mappings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Mappings'),
        content: Text(
            'Are you sure you want to delete ${mappings.length} mapping(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MappingState>().deleteSavedMappings(mappings);
              Navigator.pop(context);
              setState(() {
                _selectedMappings.clear();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportMappings(BuildContext context, List<SavedMapping> mappings) {
    MappingExportService.showMultipleMappingsExportDialog(context, mappings);
  }

  void _handleBulkFieldUpdate() {
    if (_selectedMappings.isEmpty) return;

    // Get all available fields from the first mapping
    final firstMapping = _selectedMappings.first;
    final availableFields = firstMapping.mappings
        .where((m) => m['source'] != null)
        .map((m) => m['source'] as String)
        .toSet()
        .toList();

    // Create sample values map
    final sampleValues = Map.fromEntries(
      availableFields.map((field) => MapEntry(field, field)),
    );

    showDialog(
      context: context,
      builder: (context) => BulkFieldUpdateDialog(
        selectedMappings: _selectedMappings.toList(),
        availableFields: availableFields,
        sampleValues: sampleValues,
      ),
    ).then((newMapping) {
      if (newMapping != null) {
        context.read<MappingState>().bulkUpdateMappings(
          _selectedMappings.toList(),
          (mapping) {
            final updatedMappings =
                List<Map<String, dynamic>>.from(mapping.mappings);
            // Update or add the new mapping
            final index = updatedMappings
                .indexWhere((m) => m['target'] == newMapping['target']);
            if (index != -1) {
              updatedMappings[index] = Map<String, dynamic>.from(newMapping);
            } else {
              updatedMappings.add(Map<String, dynamic>.from(newMapping));
            }

            return mapping.copyWith(
              mappings: updatedMappings,
              modifiedAt: DateTime.now(),
              totalFieldsMapped: updatedMappings.length,
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MappingState>(
      builder: (context, mappingState, child) {
        final savedMappings = mappingState.savedMappings;
        final selectedMappings = _selectedMappings.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Mappings'),
            actions: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedMappings.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextButton.icon(
                          key: const Key('bulk_update_button'),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: Text(
                              'Update Field (${selectedMappings.length})',
                              style: const TextStyle(color: Colors.white)),
                          onPressed: _handleBulkFieldUpdate,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextButton.icon(
                          key: const Key('bulk_delete_button'),
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: Text('Delete (${selectedMappings.length})',
                              style: const TextStyle(color: Colors.white)),
                          onPressed: () =>
                              _confirmBulkDelete(context, selectedMappings),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextButton.icon(
                          key: const Key('bulk_export_button'),
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: Text('Export (${selectedMappings.length})',
                              style: const TextStyle(color: Colors.white)),
                          onPressed: () =>
                              _exportMappings(context, selectedMappings),
                        ),
                      ),
                    ],
                    if (mappingState.lastBulkOperation != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextButton.icon(
                          key: const Key('revert_bulk_button'),
                          icon: const Icon(Icons.undo, color: Colors.white),
                          label: const Text('Revert Last Bulk Action',
                              style: TextStyle(color: Colors.white)),
                          onPressed: _handleRevertLastBulk,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: Consumer<MappingState>(
            builder: (context, state, child) {
              final mappings = state.savedMappings;
              final hasQueries = mappings.map((m) => m.query).toSet();

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: true,
                    columns: [
                      DataColumn(
                        label: Checkbox(
                          value: _selectedMappings.length == mappings.length &&
                              mappings.isNotEmpty,
                          onChanged: mappings.isEmpty ? null : _handleSelectAll,
                          tristate: true,
                        ),
                      ),
                      const DataColumn(label: Text('Name')),
                      const DataColumn(label: Text('Product')),
                      const DataColumn(
                        label: Text('Fields Mapped'),
                        numeric: true,
                      ),
                      const DataColumn(
                        label: Text('Required Fields'),
                        numeric: true,
                      ),
                      const DataColumn(label: Text('Last Modified')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: mappings.map((mapping) {
                      final hasDuplicateQuery =
                          hasQueries.contains(mapping.query) &&
                              mappings
                                      .where((m) => m.query == mapping.query)
                                      .length >
                                  1;

                      return DataRow(
                        selected: _selectedMappings.contains(mapping),
                        onSelectChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedMappings.add(mapping);
                            } else {
                              _selectedMappings.remove(mapping);
                            }
                          });
                        },
                        cells: [
                          DataCell(Checkbox(
                            value: _selectedMappings.contains(mapping),
                            onChanged: (selected) =>
                                _handleRowSelect(mapping, selected),
                          )),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(mapping.name),
                                if (hasDuplicateQuery)
                                  Tooltip(
                                    message: 'Duplicate query detected',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(Text(mapping.product)),
                          DataCell(Text('${mapping.totalFieldsMapped}')),
                          DataCell(Text(
                            '${mapping.requiredFieldsMapped}/${mapping.totalRequiredFields}',
                            style: TextStyle(
                              color: mapping.requiredFieldsMapped <
                                      mapping.totalRequiredFields
                                  ? Colors.red
                                  : null,
                            ),
                          )),
                          DataCell(Text(
                            mapping.modifiedAt
                                .toLocal()
                                .toString()
                                .split('.')[0],
                          )),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _loadMapping(context, mapping),
                                  tooltip: 'Load Mapping',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => _handleDuplicate(mapping),
                                  tooltip: 'Duplicate Mapping',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _handleDelete(mapping),
                                  tooltip: 'Delete Mapping',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
