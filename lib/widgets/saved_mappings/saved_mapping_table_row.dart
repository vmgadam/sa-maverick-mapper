import 'package:flutter/material.dart';
import '../../models/saved_mapping.dart';

class SavedMappingTableRow extends StatelessWidget {
  final SavedMapping mapping;
  final bool isSelected;
  final bool hasDuplicateQuery;
  final ValueChanged<bool>? onSelect;
  final VoidCallback? onLoad;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const SavedMappingTableRow({
    super.key,
    required this.mapping,
    this.isSelected = false,
    this.hasDuplicateQuery = false,
    this.onSelect,
    this.onLoad,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.highlightColor : null,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection checkbox
          if (onSelect != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => onSelect?.call(value ?? false),
              ),
            ),

          // Name and duplicate indicator
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mapping.name,
                    style: theme.textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasDuplicateQuery)
                  Tooltip(
                    message: 'Duplicate query detected',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Product
          Expanded(
            child: Text(
              mapping.product,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Fields mapped
          Expanded(
            child: Text(
              '${mapping.totalFieldsMapped}',
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Required fields
          Expanded(
            child: Text(
              '${mapping.requiredFieldsMapped}/${mapping.totalRequiredFields}',
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Last modified
          Expanded(
            child: Text(
              _formatDate(mapping.modifiedAt),
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Load mapping',
                onPressed: onLoad,
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Duplicate mapping',
                onPressed: onDuplicate,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete mapping',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
