import 'package:flutter/material.dart';
import 'dart:convert';

/// A widget that provides a drag-and-drop interface for building complex field mappings.
/// It allows users to combine source fields and text literals into expressions.
class ComplexMappingEditor extends StatefulWidget {
  /// The list of available source fields that can be dragged into the expression
  final List<String> sourceFields;

  /// The current event data used for previewing the expression
  final Map<String, dynamic> currentEvent;

  /// The initial tokens in the expression (optional)
  final List<Map<String, String>> initialTokens;

  /// Callback when the expression is saved
  final void Function(String expression, List<Map<String, String>> tokens)
      onSave;

  const ComplexMappingEditor({
    super.key,
    required this.sourceFields,
    required this.currentEvent,
    required this.onSave,
    this.initialTokens = const [],
  });

  @override
  State<ComplexMappingEditor> createState() => _ComplexMappingEditorState();
}

class _ComplexMappingEditorState extends State<ComplexMappingEditor> {
  late List<Map<String, String>> tokens;

  @override
  void initState() {
    super.initState();
    tokens = List<Map<String, String>>.from(widget.initialTokens);
  }

  /// Builds a JSONata expression from the current tokens.
  /// Handles proper formatting of field references and text literals,
  /// and ensures correct operator placement.
  String buildExpression() {
    final List<String> parts = [];
    for (var token in tokens) {
      if (token['type'] == 'field') {
        // Add & operator if this isn't the first token
        if (parts.isNotEmpty) {
          parts.add(' & '); // Add spaces around & for readability
        }
        parts.add(token['value']!);
      } else if (token['type'] == 'text') {
        if (parts.isNotEmpty) {
          parts.add(' & '); // Add spaces around & for readability
        }
        // For text tokens, use single quotes without adding extra spaces
        String text = token['value']!.substring(1, token['value']!.length - 1);
        parts.add("'$text'");
      }
    }
    return parts.join('');
  }

  /// Evaluates the current expression using sample data.
  /// Replaces field references with actual values from the current event.
  String evaluateExpression() {
    try {
      return tokens.where((token) => token['type'] != 'operator').map((token) {
        if (token['type'] == 'field') {
          final fieldPath = token['value']!.substring(1); // Remove $ prefix
          return _getNestedValue(widget.currentEvent, fieldPath)?.toString() ??
              '';
        } else if (token['type'] == 'text') {
          // Remove the quotes from the text value for preview
          return token['value']!.substring(1, token['value']!.length - 1);
        }
        return '';
      }).join('');
    } catch (e) {
      return 'Error evaluating expression';
    }
  }

  /// Gets a nested value from a map using a dot-notation path
  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic value = data;

    for (final key in keys) {
      if (value is Map) {
        value = value[key];
      } else {
        return null;
      }
    }

    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Build your expression by dragging fields. A space and "&" will be automatically added between fields.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left panel - Available fields for dragging
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Source Fields:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        // List of draggable source fields
                        Expanded(
                          child: ListView(
                            children: widget.sourceFields.map((field) {
                              return Draggable<Map<String, String>>(
                                // Data passed during drag operation
                                data: {
                                  'type': 'field',
                                  'value': '\$${field}',
                                },
                                // Visual feedback during drag
                                feedback: Material(
                                  elevation: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.blue.withOpacity(0.8),
                                    child: Text('\$${field}',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                ),
                                // Placeholder while dragging
                                childWhenDragging: const SizedBox.shrink(),
                                child: Card(
                                  child: ListTile(
                                    dense: true,
                                    title: Text('\$${field}'),
                                    subtitle: Text(
                                      _getNestedValue(
                                                  widget.currentEvent, field)
                                              ?.toString() ??
                                          '',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Right panel - Expression builder
              Expanded(
                child: Card(
                  child: DragTarget<Map<String, String>>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: candidateData.isNotEmpty
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          color: candidateData.isNotEmpty
                              ? Colors.blue.withOpacity(0.1)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Expression builder controls
                            Row(
                              children: [
                                const Text('Expression:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                // Add Text button
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Text'),
                                  onPressed: () {
                                    final textController =
                                        TextEditingController();
                                    // Show dialog for text input
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Add Text'),
                                        content: TextField(
                                          controller: textController,
                                          maxLength: 255,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Enter text to add to the expression',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (textController
                                                  .text.isNotEmpty) {
                                                setState(() {
                                                  tokens.add({
                                                    'type': 'text',
                                                    'value':
                                                        '"${textController.text}"',
                                                  });
                                                });
                                                Navigator.pop(context);
                                              }
                                            },
                                            child: const Text('Add'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Add Space button
                                TextButton.icon(
                                  icon: const Icon(Icons.space_bar),
                                  label: const Text('Add Space'),
                                  onPressed: () {
                                    setState(() {
                                      tokens.add(
                                          {'type': 'text', 'value': '" "'});
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => tokens.clear()),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Token display area
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                // Display tokens as draggable chips
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var i = 0; i < tokens.length; i++) ...[
                                      Draggable<Map<String, dynamic>>(
                                        data: {'index': i, 'token': tokens[i]},
                                        feedback: Material(
                                          elevation: 4,
                                          child: Chip(
                                            label: Text(tokens[i]['value']!),
                                            backgroundColor:
                                                tokens[i]['type'] == 'field'
                                                    ? Colors.blue.shade100
                                                    : Colors.green.shade100,
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.5,
                                          child: Chip(
                                            label: Text(tokens[i]['value']!),
                                            backgroundColor:
                                                tokens[i]['type'] == 'field'
                                                    ? Colors.blue.shade100
                                                    : Colors.green.shade100,
                                          ),
                                        ),
                                        // Make each token a drop target for reordering
                                        child: DragTarget<Map<String, dynamic>>(
                                          onWillAccept: (data) =>
                                              data != null &&
                                              data['index'] != i,
                                          onAccept: (data) {
                                            setState(() {
                                              final fromIndex =
                                                  data['index'] as int;
                                              final toIndex = i;

                                              // Handle token reordering
                                              if (fromIndex < toIndex) {
                                                final itemToMove =
                                                    tokens[fromIndex];
                                                tokens.removeAt(fromIndex);
                                                tokens.insert(
                                                    toIndex - 1, itemToMove);
                                              } else {
                                                final itemToMove =
                                                    tokens[fromIndex];
                                                tokens.removeAt(fromIndex);
                                                tokens.insert(
                                                    toIndex, itemToMove);
                                              }
                                            });
                                          },
                                          builder: (context, candidateData,
                                              rejectedData) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                border: candidateData.isNotEmpty
                                                    ? Border.all(
                                                        color: Colors.blue,
                                                        width: 2)
                                                    : null,
                                              ),
                                              child: Chip(
                                                label:
                                                    Text(tokens[i]['value']!),
                                                backgroundColor:
                                                    tokens[i]['type'] == 'field'
                                                        ? Colors.blue.shade100
                                                        : Colors.green.shade100,
                                                deleteIcon: const Icon(
                                                    Icons.close,
                                                    size: 16),
                                                onDeleted: () => setState(() {
                                                  tokens.removeAt(i);
                                                }),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Expression preview
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Preview:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    evaluateExpression(),
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onWillAccept: (data) => true,
                    onAccept: (data) {
                      setState(() {
                        tokens.add(data);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        ButtonBar(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tokens.isNotEmpty) {
                  final expression = buildExpression();
                  widget.onSave(expression, List.from(tokens));
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
