import 'package:flutter/material.dart';
import '../../models/saved_mapping_sort_field.dart';

class SavedMappingTableHeader extends StatelessWidget {
  final bool hasSelection;
  final bool allSelected;
  final SavedMappingSortField sortField;
  final bool sortAscending;
  final VoidCallback onSelectAll;
  final ValueChanged<SavedMappingSortField> onSort;

  const SavedMappingTableHeader({
    super.key,
    required this.hasSelection,
    required this.allSelected,
    required this.sortField,
    required this.sortAscending,
    required this.onSelectAll,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: hasSelection ? (bool? value) => onSelectAll() : null,
            tristate: false,
          ),
          Expanded(
            flex: 3,
            child: _buildSortableHeader(
              'Event Name',
              SavedMappingSortField.eventName,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader(
              'Product',
              SavedMappingSortField.product,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader(
              'Total Fields',
              SavedMappingSortField.totalFields,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader(
              'Required Fields',
              SavedMappingSortField.requiredFields,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader(
              'Last Modified',
              SavedMappingSortField.lastModified,
            ),
          ),
          const SizedBox(width: 120), // Actions column
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String text, SavedMappingSortField field) {
    return InkWell(
      onTap: () => onSort(field),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (sortField == field)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
    );
  }
}
