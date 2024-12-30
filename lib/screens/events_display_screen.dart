import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';
import 'package:flutter/services.dart';

// Custom scroll behavior to prevent horizontal overscroll
class NoHorizontalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class SaasField {
  final String name;
  final bool required;
  final String description;
  final String type;
  final String defaultMode;

  SaasField({
    required this.name,
    required this.required,
    required this.description,
    required this.type,
    this.defaultMode = 'simple',
  });

  factory SaasField.fromJson(String name, Map<String, dynamic> json) {
    return SaasField(
      name: name,
      required: json['required'] ?? false,
      description: json['description'] ?? '',
      type: json['type'] ?? 'string',
      defaultMode: json['defaultMode'] ?? 'simple',
    );
  }
}

class EventsDisplayScreen extends StatefulWidget {
  final ApiService apiService;
  final SaasAlertsApiService saasAlertsApi;
  final String? selectedAppId;

  const EventsDisplayScreen({
    super.key,
    required this.apiService,
    required this.saasAlertsApi,
    this.selectedAppId,
  });

  @override
  State<EventsDisplayScreen> createState() => _EventsDisplayScreenState();
}

class _EventsDisplayScreenState extends State<EventsDisplayScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> rcEvents = [];
  List<Map<String, String>> fieldMappings = [];
  List<SaasField> saasFields = [];
  List<String> sourceFields = [];
  bool hasUnsavedChanges = false;
  String _searchQuery = '';

  List<String> get filteredSourceFields {
    if (_searchQuery.isEmpty) return sourceFields;
    return sourceFields
        .where(
            (field) => field.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMappingsAndEvents();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.browserBack ||
          event.logicalKey == LogicalKeyboardKey.browserForward) {
        // Return true to indicate we've handled the event
        return;
      }
    }
  }

  Future<void> _loadMappingsAndEvents() async {
    try {
      // Load mappings from provider
      final mappingState = Provider.of<MappingState>(context, listen: false);
      final List<Map<String, String>> mappings = widget.selectedAppId != null
          ? List<Map<String, String>>.from(
              mappingState.getMappings(widget.selectedAppId!))
          : [];

      // Load SaaS Alerts fields from API service
      final fieldsData = await widget.saasAlertsApi.getFields();
      if (fieldsData == null) {
        throw Exception('Failed to load fields from SaasAlertsApiService');
      }
      final fields = fieldsData['fields'] as Map<String, dynamic>;

      final List<SaasField> allFields =
          fields.entries.map((e) => SaasField.fromJson(e.key, e.value)).toList()
            ..sort((a, b) {
              // Sort by required status first (required fields come first)
              if (a.required != b.required) {
                return a.required ? -1 : 1;
              }
              // Then sort alphabetically by name
              return a.name.compareTo(b.name);
            });

      setState(() {
        fieldMappings = mappings;
        saasFields = allFields;
        debugPrint('Loaded ${fieldMappings.length} mappings');
        debugPrint('Loaded ${saasFields.length} fields');
      });

      // Load RC events
      await _loadRcEvents();
    } catch (e, stackTrace) {
      debugPrint('Error loading mappings and events: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<String> _getAllNestedFields(List<dynamic> data, [String prefix = '']) {
    final fields = <String>{};

    for (var item in data) {
      if (item is Map<String, dynamic>) {
        item.forEach((key, value) {
          final fieldName = prefix.isEmpty ? key : '$prefix.$key';
          if (value is Map<String, dynamic>) {
            fields.addAll(_getAllNestedFields([value], fieldName));
          } else if (value is List) {
            fields.addAll(_getAllNestedFields(value, fieldName));
          } else {
            fields.add(fieldName);
          }
        });
      }
    }

    return fields.toList()..sort();
  }

  void _addMapping(String sourceField, String targetField) {
    setState(() {
      // Remove any existing mapping for the target field
      fieldMappings.removeWhere((m) => m['target'] == targetField);

      final mapping = {
        'source': sourceField,
        'target': targetField,
        'isComplex': 'false',
      };

      fieldMappings.add(mapping);
      hasUnsavedChanges = true;
    });
  }

  Future<void> _saveAndReturn() async {
    if (widget.selectedAppId != null && hasUnsavedChanges) {
      final mappingState = Provider.of<MappingState>(context, listen: false);
      final appName = mappingState.selectedAppName ?? 'Unknown App';

      // Sort mappings to match the order in the mapper screen
      final sortedMappings = List<Map<String, String>>.from(fieldMappings)
        ..sort((a, b) => (a['target'] ?? '').compareTo(b['target'] ?? ''));

      // Update state with sorted mappings
      mappingState.setMappings(widget.selectedAppId!, appName, sortedMappings);

      // Pop with result to update mapper screen
      Navigator.of(context).pop({'mappingsUpdated': true});
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadRcEvents() async {
    try {
      debugPrint('Loading RC events for app ID: ${widget.selectedAppId}');
      final eventsData = await widget.apiService.getEvents(
        widget.selectedAppId!,
        pageSize: 20,
      );

      if (eventsData != null && eventsData['data'] != null) {
        final events = eventsData['data'] as List;
        setState(() {
          rcEvents = events.map((e) => Map<String, dynamic>.from(e)).toList();
          // Extract source fields from the first event
          if (events.isNotEmpty) {
            sourceFields = _getAllNestedFields([events.first]);

            // Auto-map matching fields that aren't already mapped
            for (var sourceField in sourceFields) {
              // Check if this source field matches any unmapped SaaS Alerts field
              for (var saasField in saasFields) {
                if (saasField.name == sourceField &&
                    !fieldMappings.any((m) => m['target'] == saasField.name)) {
                  debugPrint('Auto-mapping matching field: ${saasField.name}');
                  fieldMappings.add({
                    'source': sourceField,
                    'target': saasField.name,
                    'isComplex': 'false',
                  });
                  hasUnsavedChanges = true;
                }
              }
            }
          }
        });
        debugPrint('Loaded ${rcEvents.length} RC events');
        debugPrint('Loaded ${sourceFields.length} source fields');
        if (hasUnsavedChanges) {
          debugPrint('Added automatic mappings for matching fields');
        }
      } else {
        debugPrint('No events data returned from API');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading RC events: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading events: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic value = data;

    for (final part in parts) {
      if (value is! Map<String, dynamic>) return null;
      value = value[part];
    }

    return value?.toString() ?? 'null';
  }

  String _evaluateMapping(
      Map<String, dynamic> rcEvent, Map<String, String> mapping) {
    if (mapping.isEmpty) {
      return 'No mapping defined';
    }

    final isComplex = mapping['isComplex'] == 'true';
    final jsonataExpr = mapping['jsonataExpr'];
    final rcField = mapping['source'];

    if (isComplex && jsonataExpr != null) {
      // TODO: Implement JSONata expression evaluation
      return 'JSONata: $jsonataExpr';
    } else if (rcField != null && rcField.isNotEmpty) {
      final value = _getNestedValue(rcEvent, rcField);
      debugPrint('Mapping field $rcField to value: $value');
      return value;
    }
    return 'No mapping defined';
  }

  @override
  Widget build(BuildContext context) {
    final mappingState = Provider.of<MappingState>(context);
    final requiredFields = saasFields.where((f) => f.required).length;
    debugPrint(
        'Building UI with ${rcEvents.length} events and ${saasFields.length} fields');

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _saveAndReturn();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(mappingState.selectedAppName != null
              ? 'Mapped Events - ${mappingState.selectedAppName}'
              : 'Mapped Events'),
          actions: [
            if (hasUnsavedChanges)
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save and Return'),
                onPressed: _saveAndReturn,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: isLoading ? null : _loadRcEvents,
              tooltip: 'Refresh Events',
            ),
          ],
        ),
        body: ScrollConfiguration(
          behavior: NoHorizontalScrollBehavior(),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.selectedAppId == null
                  ? const Center(
                      child: Text('Please select an app to view mapped events'),
                    )
                  : rcEvents.isEmpty
                      ? const Center(
                          child: Text('No events found'),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Showing ${rcEvents.length} events with ${saasFields.length} fields ($requiredFields required)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Card(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        columns: [
                                          const DataColumn(
                                            label: Text('RC Event ID'),
                                          ),
                                          // Show all fields in the same order as mapper screen
                                          ...saasFields
                                              .map((field) => DataColumn(
                                                    label: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          field.name,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                field.required
                                                                    ? Colors.red
                                                                    : null,
                                                          ),
                                                        ),
                                                        if (field.required)
                                                          const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 4),
                                                            child: Icon(
                                                              Icons.star,
                                                              size: 12,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    tooltip: field.description,
                                                  )),
                                        ],
                                        rows: rcEvents.map((event) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                  Text(event['id'].toString())),
                                              // Show values for all fields
                                              ...saasFields.map((field) {
                                                final mapping =
                                                    fieldMappings.firstWhere(
                                                  (m) =>
                                                      m['target'] == field.name,
                                                  orElse: () => {},
                                                );
                                                final value = _evaluateMapping(
                                                    event, mapping);

                                                if (value ==
                                                        'No mapping defined' &&
                                                    field.defaultMode !=
                                                        'complex') {
                                                  return DataCell(
                                                    PopupMenuButton<String>(
                                                      itemBuilder: (context) =>
                                                          [
                                                        PopupMenuItem(
                                                          enabled: false,
                                                          child: SearchBar(
                                                            hintText:
                                                                'Search fields...',
                                                            onChanged: (query) {
                                                              setState(() {
                                                                _searchQuery =
                                                                    query;
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        ...filteredSourceFields
                                                            .take(
                                                                100) // Limit initial load
                                                            .map((sourceField) {
                                                          final sourceValue =
                                                              _getNestedValue(
                                                                  event,
                                                                  sourceField);
                                                          return PopupMenuItem(
                                                            value: sourceField,
                                                            child: Text(
                                                              '$sourceField (${sourceValue.toString()})',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ],
                                                      onSelected:
                                                          (sourceField) {
                                                        _addMapping(sourceField,
                                                            field.name);
                                                      },
                                                      child: Text(
                                                        'Select field',
                                                        style: TextStyle(
                                                          color: field.required
                                                              ? Colors.red
                                                              : Colors.grey,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return DataCell(
                                                  Text(
                                                    value,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: value ==
                                                                  'No mapping defined' &&
                                                              field.required
                                                          ? Colors.red
                                                          : null,
                                                      fontStyle: value ==
                                                              'No mapping defined'
                                                          ? FontStyle.italic
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}
