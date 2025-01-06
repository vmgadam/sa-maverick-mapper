import 'package:flutter/material.dart';
import '../models/saved_mapping.dart';

class MappingPreviewDialog extends StatelessWidget {
  final SavedMapping mapping;

  const MappingPreviewDialog({
    super.key,
    required this.mapping,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Preview: ${mapping.name}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Product', mapping.product),
            _buildSection('Query', mapping.query),
            _buildSection(
              'Fields',
              '${mapping.totalFieldsMapped} mapped, ${mapping.requiredFieldsMapped}/${mapping.totalRequiredFields} required',
            ),
            const Divider(),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Mappings'),
                        Tab(text: 'Configuration'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildMappingsTab(),
                          _buildConfigTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: Load mapping and navigate back
            Navigator.pop(context);
          },
          child: const Text('Load This Mapping'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildMappingsTab() {
    return ListView.builder(
      itemCount: mapping.mappings.length,
      itemBuilder: (context, index) {
        final map = mapping.mappings[index];
        final isComplex = map['isComplex'] == 'true';

        return ListTile(
          leading: Icon(
            isComplex ? Icons.code : Icons.arrow_forward,
            size: 16,
          ),
          title: Text(
            isComplex
                ? '[Complex Mapping] → ${map['target']}'
                : '${map['source']} → ${map['target']}',
          ),
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return ListView(
      children: mapping.configFields.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          subtitle: Text(entry.value.toString()),
        );
      }).toList(),
    );
  }
}
