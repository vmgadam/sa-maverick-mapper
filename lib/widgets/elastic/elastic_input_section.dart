import 'package:flutter/material.dart';
import '../event_name_input.dart';

class ElasticInputSection extends StatelessWidget {
  final TextEditingController requestController;
  final TextEditingController responseController;
  final TextEditingController eventNameController;
  final int selectedRecordLimit;
  final List<int> recordLimits;
  final VoidCallback onClear;
  final VoidCallback onParse;
  final ValueChanged<int> onRecordLimitChanged;
  final bool hasUnsavedChanges;
  final bool canParse;

  const ElasticInputSection({
    super.key,
    required this.requestController,
    required this.responseController,
    required this.eventNameController,
    required this.selectedRecordLimit,
    required this.recordLimits,
    required this.onClear,
    required this.onParse,
    required this.onRecordLimitChanged,
    required this.hasUnsavedChanges,
    required this.canParse,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elastic Request/Response',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Request',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: requestController,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Paste Elastic Request JSON here...',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(8),
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Response',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: responseController,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Paste Elastic Response JSON here...',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(8),
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: EventNameInput(
                        selectedRecordLimit: selectedRecordLimit,
                        recordLimits: recordLimits,
                        onClear: onClear,
                        onParse: onParse,
                        onRecordLimitChanged: onRecordLimitChanged,
                        eventNameController: eventNameController,
                        hasUnsavedChanges: hasUnsavedChanges,
                        canParse: canParse,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
