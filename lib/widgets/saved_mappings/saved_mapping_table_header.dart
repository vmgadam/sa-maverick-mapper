import 'package:flutter/material.dart';
import '../../models/saved_mapping_sort_field.dart';

class SavedMappingTableHeader extends StatelessWidget {
  final bool hasSelection;
  final bool? allSelected;
  final SavedMappingSortField? sortField;
  final bool sortAscending;
  final ValueChanged<bool?> onSelectAll;
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

  Widget _buildSortIcon(SavedMappingSortField field) {
    if (sortField != field) {
      return const SizedBox(width: 24);
    }
    return Icon(
      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
    );
  }

  Widget _buildSortButton(
    SavedMappingSortField field,
    String label,
    BuildContext context,
  ) {
    return TextButton(
      onPressed: () => onSort(field),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: 4),
          _buildSortIcon(field),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          if (hasSelection)
            Checkbox(
              value: allSelected,
              tristate: true,
              onChanged: onSelectAll,
            ),
          Expanded(
            flex: 2,
            child: _buildSortButton(
              SavedMappingSortField.eventName,
              'Name',
              context,
            ),
          ),
          Expanded(
            child: _buildSortButton(
              SavedMappingSortField.product,
              'Product',
              context,
            ),
          ),
          Expanded(
            child: _buildSortButton(
              SavedMappingSortField.totalFields,
              'Fields',
              context,
            ),
          ),
          Expanded(
            child: _buildSortButton(
              SavedMappingSortField.requiredFields,
              'Required',
              context,
            ),
          ),
          Expanded(
            child: _buildSortButton(
              SavedMappingSortField.lastModified,
              'Modified',
              context,
            ),
          ),
          const SizedBox(width: 120), // Space for action buttons
        ],
      ),
    );
  }
}
