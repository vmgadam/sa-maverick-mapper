import 'package:flutter/material.dart';
import '../../models/saved_mapping_sort_field.dart';

class SelectionHeader extends StatelessWidget {
  final bool hasSelection;
  final bool allSelected;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onViewAllJson;
  final VoidCallback onExportAll;
  final VoidCallback? onDeleteSelected;

  const SelectionHeader({
    super.key,
    required this.hasSelection,
    required this.allSelected,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onViewAllJson,
    required this.onExportAll,
    this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Saved Mappings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 16),
        if (hasSelection) ...[
          Text('$selectedCount selected'),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('Clear Selection'),
            onPressed: onClearSelection,
          ),
          if (onDeleteSelected != null)
            TextButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete Selected'),
              onPressed: onDeleteSelected,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
        ] else
          TextButton.icon(
            icon: const Icon(Icons.select_all),
            label: const Text('Select All'),
            onPressed: onSelectAll,
          ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: 'View All JSON',
          onPressed: onViewAllJson,
        ),
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Export All',
          onPressed: onExportAll,
        ),
      ],
    );
  }
}
