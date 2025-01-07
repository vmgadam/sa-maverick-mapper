import 'package:flutter/material.dart';

class SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;

  const SelectionHeader({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear Selection'),
            onPressed: onClearSelection,
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete Selected'),
            onPressed: onDeleteSelected,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
