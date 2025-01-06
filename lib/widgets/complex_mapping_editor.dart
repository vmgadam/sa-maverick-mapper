import 'package:flutter/material.dart';
import 'dart:convert';

/// A widget that provides a drag-and-drop interface for building complex field mappings.
/// It allows users to combine source fields and text literals into expressions.
class ComplexMappingEditor extends StatefulWidget {
  /// The list of available source fields that can be dragged into the expression
  final List<String> sourceFields;

  /// The current event data used for previewing the expression
  final Map<String, dynamic> currentEvent;

  /// Sample values for each field (optional)
  final Map<String, String>? sampleValues;

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
    this.sampleValues,
    this.initialTokens = const [],
  });

  @override
  State<ComplexMappingEditor> createState() => _ComplexMappingEditorState();
}

class _ComplexMappingEditorState extends State<ComplexMappingEditor> {
  String? selectedFunction;
  List<String> functionArguments = [];
  final List<String> availableFunctions = [
    'concat',
    'substring',
    'uppercase',
    'lowercase',
    'trim',
  ];

  int getFunctionArgumentCount(String function) {
    switch (function) {
      case 'concat':
        return 2;
      case 'substring':
        return 3;
      case 'uppercase':
      case 'lowercase':
      case 'trim':
        return 1;
      default:
        return 0;
    }
  }

  bool canAddFunction() {
    if (selectedFunction == null) return false;
    final requiredArgs = getFunctionArgumentCount(selectedFunction!);
    return functionArguments.length == requiredArgs &&
        functionArguments.every((arg) => arg.isNotEmpty);
  }

  String buildFunctionExpression() {
    if (selectedFunction == null) return '';
    final args = functionArguments.map((arg) => '\$${arg}').join(', ');
    final expression = '${selectedFunction}(${args})';
    final tokens = functionArguments
        .map((arg) => {
              'type': 'field',
              'value': '\$${arg}',
            })
        .toList();
    return expression;
  }

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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Complex Mapping Editor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Complex Mapping Help'),
                          content: const SingleChildScrollView(
                            child: Text(
                              'Complex mappings allow you to combine multiple fields and apply transformations.\n\n'
                              'Available functions:\n'
                              '- concat(field1, field2, ...)\n'
                              '- substring(field, start, length)\n'
                              '- uppercase(field)\n'
                              '- lowercase(field)\n'
                              '- trim(field)',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedFunction,
                          decoration: const InputDecoration(
                            labelText: 'Function',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select a function'),
                            ),
                            ...availableFunctions.map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedFunction = value;
                              if (value != null) {
                                functionArguments.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (selectedFunction != null) ...[
                    const SizedBox(height: 16),
                    ...List.generate(
                      getFunctionArgumentCount(selectedFunction!),
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: functionArguments.length > index
                                    ? functionArguments[index]
                                    : null,
                                decoration: InputDecoration(
                                  labelText: 'Argument ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                items: widget.sourceFields.map((field) {
                                  return DropdownMenuItem(
                                    value: field,
                                    child: Text(field),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      if (functionArguments.length <= index) {
                                        functionArguments.addAll(List.filled(
                                            index +
                                                1 -
                                                functionArguments.length,
                                            ''));
                                      }
                                      functionArguments[index] = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: canAddFunction()
                          ? () {
                              final expression = buildFunctionExpression();
                              final tokens = functionArguments
                                  .map((arg) => {
                                        'type': 'field',
                                        'value': '\$${arg}',
                                      })
                                  .toList();
                              widget.onSave(expression, tokens);
                              setState(() {
                                selectedFunction = null;
                                functionArguments.clear();
                              });
                            }
                          : null,
                      child: const Text('Add Function'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
