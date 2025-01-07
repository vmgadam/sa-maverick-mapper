import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/saved_mapping.dart';
import '../../models/saved_mapping_sort_field.dart';
import '../../state/saved_mappings_state.dart';
import 'saved_mapping_table_header.dart';
import 'saved_mapping_table_row.dart';
import 'selection_header.dart';

class SavedMappingsSection extends StatefulWidget {
  final VoidCallback onViewJson;
  final VoidCallback onExport;
  final Function(SavedMapping) onLoadMapping;
  final Function(SavedMapping) onDuplicateMapping;
  final Function(String) onDeleteMapping;

  const SavedMappingsSection({
    super.key,
    required this.onViewJson,
    required this.onExport,
    required this.onLoadMapping,
    required this.onDuplicateMapping,
    required this.onDeleteMapping,
  });

  @override
  State<SavedMappingsSection> createState() => _SavedMappingsSectionState();
}

class _SavedMappingsSectionState extends State<SavedMappingsSection> {
  final Set<String> _selectedMappings = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SavedMappingSortField? _sortField;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(SavedMapping mapping) {
    setState(() {
      if (_selectedMappings.contains(mapping.name)) {
        _selectedMappings.remove(mapping.name);
      } else {
        _selectedMappings.add(mapping.name);
      }
    });
  }

  void _toggleSelectAll(bool? selected, List<dynamic> mappings) {
    setState(() {
      if (selected == true) {
        _selectedMappings.addAll(mappings.map((m) => (m as SavedMapping).name));
      } else {
        _selectedMappings.clear();
      }
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

    final sortedMappings = List<SavedMapping>.from(mappings);
    sortedMappings.sort((a, b) {
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
          comparison = a.requiredFieldsMapped.compareTo(b.requiredFieldsMapped);
          break;
        case SavedMappingSortField.lastModified:
          comparison = a.modifiedAt.compareTo(b.modifiedAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    return sortedMappings;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SavedMappingsState>(context);
    final product = state.selectedProduct;
    final mappings = product != null
        ? state.getMappingsForProduct(product)
        : <SavedMapping>[];

    final filteredMappings = mappings
        .where((mapping) {
          if (_searchQuery.isEmpty) return true;
          return mapping.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              mapping.query.toLowerCase().contains(_searchQuery.toLowerCase());
        })
        .map((mapping) => mapping as SavedMapping)
        .toList();

    final sortedMappings = _getSortedMappings(filteredMappings);
    final hasSelection = _selectedMappings.isNotEmpty;
    final allSelected = sortedMappings.isNotEmpty &&
        sortedMappings.every((m) => _selectedMappings.contains(m.name));
    final someSelected =
        sortedMappings.any((m) => _selectedMappings.contains(m.name));

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Saved Mappings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: widget.onViewJson,
                  tooltip: 'View JSON',
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  onPressed: widget.onExport,
                  tooltip: 'Export Mappings',
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search mappings...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (hasSelection)
            SelectionHeader(
              selectedCount: _selectedMappings.length,
              onClearSelection: () {
                setState(() {
                  _selectedMappings.clear();
                });
              },
              onDeleteSelected: () {
                if (product != null) {
                  state.deleteMappings(product, _selectedMappings.toList());
                  setState(() {
                    _selectedMappings.clear();
                  });
                }
              },
            ),
          SavedMappingTableHeader(
            hasSelection: sortedMappings.isNotEmpty,
            allSelected: allSelected ? true : (someSelected ? null : false),
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSelectAll: (selected) =>
                _toggleSelectAll(selected, sortedMappings),
            onSort: _handleSort,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedMappings.length,
              itemBuilder: (context, index) {
                final mapping = sortedMappings[index];
                final duplicates =
                    state.findDuplicateQueries(product ?? '', mapping.query);
                final hasDuplicateQuery = duplicates.length > 1;

                return SavedMappingTableRow(
                  mapping: mapping,
                  isSelected: _selectedMappings.contains(mapping.name),
                  hasDuplicateQuery: hasDuplicateQuery,
                  onSelect: (_) => _toggleSelection(mapping),
                  onLoad: () => widget.onLoadMapping(mapping),
                  onDuplicate: () => widget.onDuplicateMapping(mapping),
                  onDelete: () => widget.onDeleteMapping(mapping.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
