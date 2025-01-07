import 'package:flutter/material.dart';
import '../models/saas_field.dart';

class CurrentMappingsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> mappings;
  final List<SaasField> saasFields;
  final VoidCallback onViewJson;
  final VoidCallback onExport;
  final Function(String) onRemoveMapping;
  final Function(SaasField) onEditComplexMapping;
  final bool hasRemovedFields;

  const CurrentMappingsWidget({
    super.key,
    required this.mappings,
    required this.saasFields,
    required this.onViewJson,
    required this.onExport,
    required this.onRemoveMapping,
    required this.onEditComplexMapping,
    this.hasRemovedFields = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedMappings = List<Map<String, dynamic>>.from(mappings)
      ..sort((a, b) => (a['target'] as String? ?? '')
          .compareTo(b['target'] as String? ?? ''));

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Current Mappings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: onViewJson,
                  tooltip: 'View JSON',
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  onPressed: onExport,
                  tooltip: 'Export Mappings',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedMappings.length,
              itemBuilder: (context, index) {
                final mapping = sortedMappings[index];
                final targetField = saasFields.firstWhere(
                  (f) => f.name == (mapping['target'] as String? ?? ''),
                  orElse: () => SaasField(
                    name: mapping['target'] as String? ?? '',
                    required: false,
                    description: '',
                    type: 'string',
                    category: 'Standard',
                    displayOrder: 999,
                  ),
                );
                return Card(
                  child: ListTile(
                    leading: targetField.required
                        ? const Icon(Icons.star, color: Colors.red)
                        : null,
                    title: Text(
                      mapping['isComplex'] == 'true'
                          ? '[Complex Mapping] → ${mapping['target']}'
                          : '${mapping['source'] ?? ''} → ${mapping['target']}',
                      style: TextStyle(
                        color: hasRemovedFields ? Colors.red : null,
                      ),
                    ),
                    subtitle: Text(
                      targetField.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mapping['isComplex'] == 'true')
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => onEditComplexMapping(targetField),
                            tooltip: 'Edit Complex Mapping',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => onRemoveMapping(
                              mapping['target'] as String? ?? ''),
                          tooltip: 'Remove Mapping',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
