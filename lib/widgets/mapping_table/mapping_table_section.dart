import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/saas_field.dart';
import '../../services/field_mapping_service.dart';
import 'package:provider/provider.dart';
import '../../state/mapping_state.dart';
import '../../widgets/searchable_dropdown.dart';

class MappingTableSection extends StatefulWidget {
  final List<String> sourceFields;
  final List<SaasField> saasFields;
  final Map<String, dynamic> currentEvent;
  final List<Map<String, dynamic>> mappings;
  final Function(String, String, bool) onAddMapping;
  final Function(String) onRemoveMapping;
  final TextEditingController sourceSearchController;
  final TextEditingController saasSearchController;
  final ScrollController horizontalController;
  final List<dynamic> rcEvents;
  final Function(SaasField) onShowComplexEditor;

  const MappingTableSection({
    super.key,
    required this.sourceFields,
    required this.saasFields,
    required this.currentEvent,
    required this.mappings,
    required this.onAddMapping,
    required this.onRemoveMapping,
    required this.sourceSearchController,
    required this.saasSearchController,
    required this.horizontalController,
    required this.rcEvents,
    required this.onShowComplexEditor,
  });

  @override
  State<MappingTableSection> createState() => _MappingTableSectionState();
}

class _MappingTableSectionState extends State<MappingTableSection> {
  String sourceSearchQuery = '';
  String saasSearchQuery = '';

  // Helper getters
  Map<String, int> get sourceFieldUsage {
    final usage = <String, int>{};
    for (final mapping in widget.mappings) {
      if (mapping['isComplex'] != 'true' && mapping['source'] != null) {
        final sourceField = mapping['source'] as String;
        usage[sourceField] = (usage[sourceField] ?? 0) + 1;
      }
    }
    return usage;
  }

  List<String> get filteredSourceFields {
    if (sourceSearchQuery.isEmpty) return widget.sourceFields;
    return widget.sourceFields.where((field) {
      final value =
          FieldMappingService.getNestedValue(widget.currentEvent, field)
              .toLowerCase();
      return field.toLowerCase().contains(sourceSearchQuery.toLowerCase()) ||
          value.contains(sourceSearchQuery.toLowerCase());
    }).toList();
  }

  List<SaasField> get standardFields {
    final fields = widget.saasFields
        .where((field) => field.category.toLowerCase() == 'standard')
        .toList();
    fields.sort((a, b) {
      // First sort by displayOrder
      final orderComparison = a.displayOrder.compareTo(b.displayOrder);
      if (orderComparison != 0) {
        return orderComparison;
      }
      // Then sort alphabetically by name
      return a.name.compareTo(b.name);
    });
    return fields;
  }

  String _getComplexMappingPreview(Map<String, dynamic> mapping) {
    if (mapping['tokens'] == null) return '[Complex Mapping]';
    try {
      final tokens = List<Map<String, String>>.from(json
          .decode(mapping['tokens']!)
          .map((t) => Map<String, String>.from(t)));

      final preview = tokens.map((token) {
        if (token['type'] == 'field') {
          return '\$${token['value']!.substring(1)}';
        } else if (token['value']!.endsWith('(removed)')) {
          return token['value'];
        } else {
          return token['value']!.substring(1, token['value']!.length - 1);
        }
      }).join(' ');

      return preview;
    } catch (e) {
      return '[Complex Mapping]';
    }
  }

  bool _hasRemovedFields(Map<String, dynamic> mapping) {
    if (mapping['isComplex'] != 'true' || mapping['tokens'] == null) {
      return false;
    }
    try {
      final tokens = List<Map<String, String>>.from(json
          .decode(mapping['tokens']!)
          .map((t) => Map<String, String>.from(t)));
      return tokens.any((t) => t['value']?.endsWith('(removed)') ?? false);
    } catch (e) {
      return false;
    }
  }

  Widget _buildMappingControl(SaasField field) {
    return Row(
      children: [
        Expanded(
          child: widget.mappings.any((m) => m['target'] == field.name)
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          widget.mappings.firstWhere((m) =>
                                      m['target'] == field.name)['isComplex'] ==
                                  'true'
                              ? _getComplexMappingPreview(widget.mappings
                                  .firstWhere((m) => m['target'] == field.name))
                              : widget.mappings.firstWhere(
                                  (m) => m['target'] == field.name)['source']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasRemovedFields(widget.mappings.firstWhere(
                                    (m) => m['target'] == field.name))
                                ? Colors.red
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.mappings.firstWhere(
                            (m) => m['target'] == field.name)['isComplex'] ==
                        'true')
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        tooltip: 'Edit Complex Mapping',
                        onPressed: () => widget.onShowComplexEditor(field),
                      ),
                  ],
                )
              : SearchableDropdown(
                  items: widget.sourceFields.map((sourceField) {
                    String sampleValue = FieldMappingService.getNestedValue(
                            widget.rcEvents.first, sourceField)
                        .toString();
                    if (sampleValue.length > 50) {
                      sampleValue = '${sampleValue.substring(0, 47)}...';
                    }
                    return SearchableDropdownItem(
                      value: sourceField,
                      label: sourceField,
                      subtitle: sampleValue,
                    );
                  }).toList(),
                  hint: Text(
                    'Select field to map',
                    style: TextStyle(
                      fontSize: 12,
                      color: field.required ? Colors.red : Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onAddMapping(value, field.name, false);
                    }
                  },
                ),
        ),
        if (!widget.mappings.any((m) => m['target'] == field.name))
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Create Complex Mapping',
            onPressed: () => widget.onShowComplexEditor(field),
            iconSize: 16,
          ),
        if (widget.mappings.any((m) => m['target'] == field.name))
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => widget.onRemoveMapping(field.name),
            iconSize: 16,
          ),
      ],
    );
  }

  List<DataColumn> _buildDataColumns() {
    final List<DataColumn> columns = [];
    final sortedFields = standardFields;

    if (sortedFields.isEmpty) {
      columns.add(const DataColumn(label: Text('')));
      return columns;
    }

    columns.addAll(sortedFields.map((field) => DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      field.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: field.required ? Colors.red : null,
                      ),
                    ),
                    if (field.required)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star, size: 12, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 180,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildMappingControl(field),
                ),
              ],
            ),
          ),
        )));

    return columns;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: widget.horizontalController,
      child: SingleChildScrollView(
        child: DataTable(
          columns: _buildDataColumns(),
          rows: widget.rcEvents.map((event) {
            return DataRow(
              cells: standardFields.map((field) {
                final mapping = widget.mappings.firstWhere(
                  (m) => m['target'] == field.name,
                  orElse: () => {},
                );
                final value = _evaluateMapping(event, mapping);
                return DataCell(
                  Text(
                    value.isEmpty ? '' : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            );
          }).toList(),
          showCheckboxColumn: false,
          horizontalMargin: 12,
        ),
      ),
    );
  }

  String _evaluateMapping(
      Map<String, dynamic> event, Map<String, dynamic> mapping) {
    if (mapping.isEmpty) return '';

    try {
      if (mapping['isComplex'] == 'true' && mapping['tokens'] != null) {
        final tokens = List<Map<String, String>>.from(json
            .decode(mapping['tokens']!)
            .map((t) => Map<String, String>.from(t)));

        final parts = tokens.map((token) {
          if (token['type'] == 'field') {
            final fieldPath = token['value']!.substring(1);
            return FieldMappingService.getNestedValue(event, fieldPath)
                    ?.toString() ??
                '';
          } else if (token['type'] == 'text') {
            return token['value']!.substring(1, token['value']!.length - 1);
          }
          return '';
        }).toList();

        return parts.join('');
      } else if (mapping['source'] != null && mapping['source']!.isNotEmpty) {
        return FieldMappingService.getNestedValue(event, mapping['source']!) ??
            '';
      }
      return '';
    } catch (e) {
      debugPrint('Error evaluating mapping: $e');
      return '';
    }
  }
}
