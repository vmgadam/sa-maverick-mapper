import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/saved_mapping.dart';
import '../../models/saved_mapping_sort_field.dart';
import '../../state/saved_mappings_state.dart';
import 'saved_mapping_table_header.dart';
import 'saved_mapping_table_row.dart';
import 'selection_header.dart';
import 'bulk_delete_dialog.dart';

class SavedMappingsSection extends StatefulWidget {
  final Function(SavedMapping) onLoadMapping;
  final Function(SavedMapping) onDuplicateMapping;
  final Function(String) onDeleteMapping;
  final Function(SavedMapping) onViewJson;
  final Function(SavedMapping) onExport;
  final Function() onViewAllJson;
  final Function() onExportAll;

  const SavedMappingsSection({
    super.key,
    required this.onLoadMapping,
    required this.onDuplicateMapping,
    required this.onDeleteMapping,
    required this.onViewJson,
    required this.onExport,
    required this.onViewAllJson,
    required this.onExportAll,
  });

  @override
  State<SavedMappingsSection> createState() => _SavedMappingsSectionState();
}

class _SavedMappingsSectionState extends State<SavedMappingsSection> {
  SavedMappingSortField _sortField = SavedMappingSortField.eventName;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Initialize product in a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<SavedMappingsState>(context, listen: false);
      if (state.selectedProduct == null) {
        state.setSelectedProduct('Elastic');
      }
    });
  }

  Future<void> _handleBulkDelete(BuildContext context, SavedMappingsState state,
      List<String> selectedMappings) async {
    final confirmed = await BulkDeleteDialog.show(
      context: context,
      count: selectedMappings.length,
      onConfirm: () {
        state.deleteMappings(state.selectedProduct!, selectedMappings);
      },
    );

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${selectedMappings.length} mapping${selectedMappings.length == 1 ? '' : 's'} deleted'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedMappingsState>(
      builder: (context, state, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectionHeader(
                  hasSelection: state.hasSelection,
                  allSelected:
                      state.isAllSelected(state.selectedProduct ?? 'Elastic'),
                  selectedCount: state.selectedMappings.length,
                  onSelectAll: () =>
                      state.selectAll(state.selectedProduct ?? 'Elastic'),
                  onClearSelection: state.clearSelection,
                  onViewAllJson: widget.onViewAllJson,
                  onExportAll: widget.onExportAll,
                  onDeleteSelected: state.selectedMappings.isNotEmpty
                      ? () => _handleBulkDelete(
                          context, state, List.from(state.selectedMappings))
                      : null,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildMappingsList(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMappingsList(BuildContext context, SavedMappingsState state) {
    final mappings = state.getMappings(state.selectedProduct ?? 'Elastic');

    return Column(
      children: [
        SavedMappingTableHeader(
          hasSelection: state.hasSelection,
          allSelected: state.isAllSelected(state.selectedProduct ?? 'Elastic'),
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSelectAll: () =>
              state.selectAll(state.selectedProduct ?? 'Elastic'),
          onSort: (field) {
            setState(() {
              if (_sortField == field) {
                _sortAscending = !_sortAscending;
              } else {
                _sortField = field;
                _sortAscending = true;
              }
            });
          },
        ),
        Expanded(
          child: mappings.isEmpty
              ? const Center(
                  child: Text('No saved mappings found'),
                )
              : ListView.builder(
                  itemCount: mappings.length,
                  itemBuilder: (context, index) {
                    final mapping = mappings[index];
                    return SavedMappingTableRow(
                      mapping: mapping,
                      isSelected: state.isSelected(mapping.eventName),
                      onSelect: () => state.toggleSelection(mapping.eventName),
                      onLoad: () => widget.onLoadMapping(mapping),
                      onDuplicate: () => widget.onDuplicateMapping(mapping),
                      onDelete: () => widget.onDeleteMapping(mapping.eventName),
                      onViewJson: () => widget.onViewJson(mapping),
                      onExport: () => widget.onExport(mapping),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
