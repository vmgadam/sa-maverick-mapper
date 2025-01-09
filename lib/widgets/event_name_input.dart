import 'package:flutter/material.dart';

class EventNameInput extends StatelessWidget {
  final int selectedRecordLimit;
  final List<int> recordLimits;
  final VoidCallback onClear;
  final VoidCallback onParse;
  final ValueChanged<int> onRecordLimitChanged;
  final TextEditingController eventNameController;
  final bool hasUnsavedChanges;
  final bool canParse;

  const EventNameInput({
    super.key,
    required this.selectedRecordLimit,
    required this.recordLimits,
    required this.onClear,
    required this.onParse,
    required this.onRecordLimitChanged,
    required this.eventNameController,
    required this.hasUnsavedChanges,
    required this.canParse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Row(
            children: [
              const Text('Event Name'),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: Colors.red),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: eventNameController,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: OutlineInputBorder(),
                errorStyle: TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: selectedRecordLimit,
            items: recordLimits.map((limit) {
              return DropdownMenuItem<int>(
                value: limit,
                child: Text('$limit records'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onRecordLimitChanged(value);
              }
            },
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear'),
            onPressed: onClear,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Parse'),
            onPressed: canParse ? onParse : null,
          ),
        ],
      ),
    );
  }
}
