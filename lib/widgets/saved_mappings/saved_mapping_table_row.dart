import 'package:flutter/material.dart';
import '../../models/saved_mapping.dart';

class SavedMappingTableRow extends StatelessWidget {
  final SavedMapping mapping;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onLoad;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onViewJson;
  final VoidCallback onExport;
  final VoidCallback onViewConfig;

  const SavedMappingTableRow({
    super.key,
    required this.mapping,
    required this.isSelected,
    required this.onSelect,
    required this.onLoad,
    required this.onDuplicate,
    required this.onDelete,
    required this.onViewJson,
    required this.onExport,
    required this.onViewConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
            : null,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) => onSelect(),
                ),
                Expanded(
                  flex: 3,
                  child: Text(mapping.eventName),
                ),
                Expanded(
                  flex: 2,
                  child: Text(mapping.product),
                ),
                Expanded(
                  flex: 2,
                  child: Text(mapping.totalFieldsMapped.toString()),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                      '${mapping.requiredFieldsMapped}/${mapping.totalRequiredFields}'),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatDate(mapping.modifiedAt),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'View Config',
                        onPressed: onViewConfig,
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Load',
                        onPressed: onLoad,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Duplicate',
                        onPressed: onDuplicate,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
