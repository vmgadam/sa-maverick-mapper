import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/saved_mapping.dart';
import '../../models/saved_mapping_sort_field.dart';
import '../../state/saved_mappings_state.dart';
import 'saved_mapping_table_header.dart';
import 'saved_mapping_table_row.dart';
import 'selection_header.dart';

class SavedMappingsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Saved Mappings',
                  style: Theme.of(context).textTheme.titleMedium,
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
            ),
            const SizedBox(height: 16),
            Consumer<SavedMappingsState>(
              builder: (context, state, child) {
                if (state.selectedProduct == null) {
                  return const Center(
                    child: Text('Select an app to view saved mappings'),
                  );
                }

                final mappings = state.getMappings(state.selectedProduct!);
                if (mappings.isEmpty) {
                  return const Center(
                    child: Text('No saved mappings found'),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: mappings.length,
                    itemBuilder: (context, index) {
                      final mapping = mappings[index];
                      return SavedMappingTableRow(
                        mapping: mapping,
                        isSelected: state.isSelected(mapping.eventName),
                        onSelect: (selected) {
                          if (selected != null) {
                            state.toggleSelection(mapping.eventName);
                          }
                        },
                        onLoad: () => onLoadMapping(mapping),
                        onDuplicate: () => onDuplicateMapping(mapping),
                        onDelete: () => onDeleteMapping(mapping.eventName),
                        onViewJson: () => onViewJson(mapping),
                        onExport: () => onExport(mapping),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
