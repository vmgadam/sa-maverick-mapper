import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_mapping.dart';
import '../models/saved_mapping_sort_field.dart';
import '../state/saved_mappings_state.dart';
import '../widgets/saved_mappings/saved_mapping_table_header.dart';
import '../widgets/saved_mappings/saved_mapping_table_row.dart';
import '../widgets/saved_mappings/selection_header.dart';

class SavedMappingsScreen extends StatefulWidget {
  const SavedMappingsScreen({super.key});

  @override
  State<SavedMappingsScreen> createState() => _SavedMappingsScreenState();
}

class _SavedMappingsScreenState extends State<SavedMappingsScreen> {
  final Set<String> _selectedMappings = {};
  SavedMappingSortField? _sortField;
  bool _sortAscending = true;

  void _toggleSelection(SavedMapping mapping) {
    setState(() {
      if (_selectedMappings.contains(mapping.name)) {
        _selectedMappings.remove(mapping.name);
      } else {
        _selectedMappings.add(mapping.name);
      }
    });
  }

  void _toggleSelectAll(bool? selected, List<SavedMapping> mappings) {
    setState(() {
      if (selected == true) {
        _selectedMappings.addAll(mappings.map((m) => m.name));
      } else {
        _selectedMappings.clear();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMappings.clear();
    });
  }

  void _handleSort(SavedMappingSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  List<SavedMapping> _getSortedMappings(List<SavedMapping> mappings) {
    if (_sortField == null) return mappings;

    return List.of(mappings)
      ..sort((a, b) {
        int comparison;
        switch (_sortField!) {
          case SavedMappingSortField.name:
            comparison = a.name.compareTo(b.name);
            break;
          case SavedMappingSortField.product:
            comparison = a.product.compareTo(b.product);
            break;
          case SavedMappingSortField.totalFields:
            comparison = a.totalFieldsMapped.compareTo(b.totalFieldsMapped);
            break;
          case SavedMappingSortField.requiredFields:
            comparison =
                a.requiredFieldsMapped.compareTo(b.requiredFieldsMapped);
            break;
          case SavedMappingSortField.lastModified:
            comparison = a.modifiedAt.compareTo(b.modifiedAt);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedMappingsState>(
      builder: (context, state, child) {
        final product = state.selectedProduct;
        if (product == null) {
          return const Center(
            child: Text('Please select a product to view saved mappings'),
          );
        }

        final mappings =
            _getSortedMappings(state.getMappingsForProduct(product));
        final hasSelection = _selectedMappings.isNotEmpty;
        final allSelected = mappings.isNotEmpty &&
            mappings.every((m) => _selectedMappings.contains(m.name));
        final someSelected =
            mappings.any((m) => _selectedMappings.contains(m.name));

        return Column(
          children: [
            // Selection header when items are selected
            if (hasSelection)
              SelectionHeader(
                selectedCount: _selectedMappings.length,
                onClearSelection: _clearSelection,
                onDeleteSelected: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Selected Mappings'),
                      content: Text(
                        'Are you sure you want to delete ${_selectedMappings.length} '
                        'mapping${_selectedMappings.length == 1 ? '' : 's'}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            state.deleteMappings(
                                product, _selectedMappings.toList());
                            _clearSelection();
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Table header
            SavedMappingTableHeader(
              hasSelection: mappings.isNotEmpty,
              allSelected: allSelected ? true : (someSelected ? null : false),
              sortField: _sortField,
              sortAscending: _sortAscending,
              onSelectAll: (selected) => _toggleSelectAll(selected, mappings),
              onSort: _handleSort,
            ),

            // Table body
            Expanded(
              child: mappings.isEmpty
                  ? const Center(
                      child: Text('No saved mappings for this product'),
                    )
                  : ListView.builder(
                      itemCount: mappings.length,
                      itemBuilder: (context, index) {
                        final mapping = mappings[index];
                        final isSelected =
                            _selectedMappings.contains(mapping.name);
                        final hasDuplicateQuery = state
                                .findDuplicateQueries(
                                  product,
                                  mapping.query,
                                )
                                .length >
                            1;

                        return SavedMappingTableRow(
                          mapping: mapping,
                          isSelected: isSelected,
                          hasDuplicateQuery: hasDuplicateQuery,
                          onSelect: (_) => _toggleSelection(mapping),
                          onLoad: () {
                            // TODO: Implement load functionality
                          },
                          onDuplicate: () {
                            state.duplicateMapping(product, mapping.name);
                          },
                          onDelete: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Mapping'),
                                content: Text(
                                  'Are you sure you want to delete "${mapping.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      state.deleteMapping(
                                          product, mapping.name);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
