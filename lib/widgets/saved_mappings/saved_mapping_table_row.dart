import 'package:flutter/material.dart';
import '../../models/saved_mapping.dart';

class SavedMappingTableRow extends StatelessWidget {
  final SavedMapping mapping;
  final bool isSelected;
  final Function(bool?) onSelect;
  final Function() onLoad;
  final Function() onDuplicate;
  final Function() onDelete;
  final Function() onViewJson;
  final Function() onExport;

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
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: onSelect,
      ),
      title: Text(mapping.eventName),
      subtitle: Text('${mapping.totalFieldsMapped} fields mapped'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'View JSON',
            onPressed: onViewJson,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: onExport,
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
    );
  }
}
