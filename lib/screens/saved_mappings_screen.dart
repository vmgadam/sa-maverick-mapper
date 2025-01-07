import 'package:flutter/material.dart';
import '../models/saved_mapping.dart';
import '../models/saved_mapping_sort_field.dart';
import '../widgets/saved_mappings/saved_mapping_table_header.dart';
import '../widgets/saved_mappings/saved_mapping_table_row.dart';
import '../widgets/saved_mappings/selection_header.dart';

class SavedMappingsScreen extends StatefulWidget {
  final List<SavedMapping> mappings;
  final Function(SavedMapping) onViewJson;
  final Function(SavedMapping) onExport;
  final Function() onViewAllJson;
  final Function() onExportAll;
  final Function(SavedMapping) onLoadMapping;
  final Function(SavedMapping) onDuplicateMapping;
  final Function(String) onDeleteMapping;

  const SavedMappingsScreen({
    super.key,
    required this.mappings,
    required this.onViewJson,
    required this.onExport,
    required this.onViewAllJson,
    required this.onExportAll,
    required this.onLoadMapping,
    required this.onDuplicateMapping,
    required this.onDeleteMapping,
  });

  @override
  State<SavedMappingsScreen> createState() => _SavedMappingsScreenState();
}

class _SavedMappingsScreenState extends State<SavedMappingsScreen> {
  final Set<String> _selectedMappings = {};
  SavedMappingSortField _sortField = SavedMappingSortField.eventName;
  bool _sortAscending = true;
  String _searchQuery = '';

  List<SavedMapping> get _sortedMappings {
    final filteredMappings = widget.mappings.where((mapping) {
      final searchLower = _searchQuery.toLowerCase();
      return mapping.eventName.toLowerCase().contains(searchLower) ||
          mapping.product.toLowerCase().contains(searchLower);
    }).toList();

    filteredMappings.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case SavedMappingSortField.eventName:
          comparison = a.eventName.compareTo(b.eventName);
          break;
        case SavedMappingSortField.product:
          comparison = a.product.compareTo(b.product);
          break;
        case SavedMappingSortField.totalFields:
          comparison = a.totalFieldsMapped.compareTo(b.totalFieldsMapped);
          break;
        case SavedMappingSortField.requiredFields:
          comparison = a.requiredFieldsMapped.compareTo(b.requiredFieldsMapped);
          break;
        case SavedMappingSortField.lastModified:
          comparison = a.modifiedAt.compareTo(b.modifiedAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredMappings;
  }

  void _toggleSort(SavedMappingSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  void _toggleSelection(String eventName) {
    setState(() {
      if (_selectedMappings.contains(eventName)) {
        _selectedMappings.remove(eventName);
      } else {
        _selectedMappings.add(eventName);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedMappings.length == _sortedMappings.length) {
        _selectedMappings.clear();
      } else {
        _selectedMappings
            .addAll(_sortedMappings.map((mapping) => mapping.eventName));
      }
    });
  }

  void _deleteSelected() {
    for (var eventName in _selectedMappings) {
      widget.onDeleteMapping(eventName);
    }
    setState(() {
      _selectedMappings.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedMappings.isNotEmpty)
          SelectionHeader(
            selectedCount: _selectedMappings.length,
            onClearSelection: () {
              setState(() {
                _selectedMappings.clear();
              });
            },
            onDeleteSelected: _deleteSelected,
          ),
        SavedMappingTableHeader(
          hasSelection: _sortedMappings.isNotEmpty,
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSort: _toggleSort,
          onSelectAll: (selected) {
            if (selected ?? false) {
              _selectAll();
            } else {
              setState(() {
                _selectedMappings.clear();
              });
            }
          },
          allSelected: _selectedMappings.length == _sortedMappings.length,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _sortedMappings.length,
            itemBuilder: (context, index) {
              final mapping = _sortedMappings[index];
              return SavedMappingTableRow(
                mapping: mapping,
                isSelected: _selectedMappings.contains(mapping.eventName),
                onSelect: (selected) {
                  if (selected ?? false) {
                    _selectedMappings.add(mapping.eventName);
                  } else {
                    _selectedMappings.remove(mapping.eventName);
                  }
                  setState(() {});
                },
                onViewJson: () => widget.onViewJson(mapping),
                onExport: () => widget.onExport(mapping),
                onLoad: () => widget.onLoadMapping(mapping),
                onDuplicate: () => widget.onDuplicateMapping(mapping),
                onDelete: () => widget.onDeleteMapping(mapping.eventName),
              );
            },
          ),
        ),
      ],
    );
  }
}
