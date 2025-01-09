import 'package:flutter/material.dart';

class BulkDeleteDialog extends StatelessWidget {
  final int count;
  final VoidCallback onConfirm;

  const BulkDeleteDialog({
    super.key,
    required this.count,
    required this.onConfirm,
  });

  static Future<bool> show({
    required BuildContext context,
    required int count,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BulkDeleteDialog(
        count: count,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text(
          'Are you sure you want to delete $count selected mapping${count == 1 ? '' : 's'}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
