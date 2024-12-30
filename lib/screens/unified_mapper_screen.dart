import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';
import 'package:flutter/services.dart';
import '../widgets/complex_mapping_editor.dart';

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

class UnifiedMapperScreen extends StatefulWidget {
  final ApiService apiService;
  final SaasAlertsApiService saasAlertsApi;

  const UnifiedMapperScreen({
    super.key,
    required this.apiService,
    required this.saasAlertsApi,
  });

  @override
  State<UnifiedMapperScreen> createState() => _UnifiedMapperScreenState();
}

class _UnifiedMapperScreenState extends State<UnifiedMapperScreen> {
  // Source data state
  final List<dynamic> rcApps = [];
  String? selectedRcAppId;
  Map<String, dynamic> currentRcEvent = {};
  List<String> rcFields = [];
  bool isLoadingRcApps = true;
  bool isLoadingRcEvents = false;

  // SaaS Alerts fields state
  List<SaasField> saasFields = [];
  bool isLoadingSaasFields = true;

  // Mapping state
  List<Map<String, dynamic>> mappings = [];
  bool hasUnsavedChanges = false;
  final TextEditingController jsonInputController = TextEditingController();
  bool showJsonInput = false;

  // Events display state
  List<Map<String, dynamic>> rcEvents = [];

  // Search functionality
  final TextEditingController sourceSearchController = TextEditingController();
  final TextEditingController saasSearchController = TextEditingController();
  String sourceSearchQuery = '';
  String saasSearchQuery = '';

  // Configuration fields state
  final Map<String, String> configFields = {
    'productRef': 'products/default',
    'endpointId': '0',
    'eventType': 'EVENT',
  };

  @override
  void initState() {
    super.initState();
    _loadRcApps();
    _loadSaasFields();
  }

  @override
  void dispose() {
    sourceSearchController.dispose();
    saasSearchController.dispose();
    jsonInputController.dispose();
    super.dispose();
  }

  // Helper getters
  Map<String, int> get sourceFieldUsage {
    final usage = <String, int>{};
    for (final mapping in mappings) {
      if (mapping['isComplex'] != 'true' && mapping['source'] != null) {
        final sourceField = mapping['source'] as String;
        usage[sourceField] = (usage[sourceField] ?? 0) + 1;
      }
    }
    return usage;
  }

  List<SaasField> get unmappedSaasFields {
    return saasFields.where((field) {
      return !mappings.any((m) => m['target'] == field.name);
    }).toList();
  }

  List<String> get filteredSourceFields {
    if (sourceSearchQuery.isEmpty) return rcFields;
    return rcFields.where((field) {
      final value =
          _getNestedValue(currentRcEvent, field)?.toString().toLowerCase() ??
              '';
      return field.toLowerCase().contains(sourceSearchQuery.toLowerCase()) ||
          value.contains(sourceSearchQuery.toLowerCase());
    }).toList();
  }

  List<SaasField> get filteredSaasFields {
    if (saasSearchQuery.isEmpty) return unmappedSaasFields;
    return unmappedSaasFields.where((field) {
      return field.name.toLowerCase().contains(saasSearchQuery.toLowerCase()) ||
          field.description
              .toLowerCase()
              .contains(saasSearchQuery.toLowerCase());
    }).toList();
  }

  // Loading functions
  Future<void> _loadRcApps() async {
    try {
      final response = await widget.apiService.getApps();
      if (response != null) {
        setState(() {
          rcApps.clear();
          rcApps.addAll(response['data'] ?? []);
          isLoadingRcApps = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading RC apps: $e');
      setState(() {
        isLoadingRcApps = false;
      });
    }
  }

  Future<void> _loadSaasFields() async {
    try {
      final String jsonString =
          await rootBundle.loadString('config/fields.json');
      final jsonData = json.decode(jsonString);
      final fields = jsonData['fields'] as Map<String, dynamic>;

      setState(() {
        saasFields = fields.entries
            .map((e) => SaasField.fromJson(e.key, e.value))
            .toList()
          ..sort((a, b) {
            if (a.required != b.required) {
              return a.required ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          });
        isLoadingSaasFields = false;
      });
    } catch (e) {
      debugPrint('Error loading SaaS fields: $e');
      setState(() {
        isLoadingSaasFields = false;
      });
    }
  }

  Future<void> _loadRcEvents(String appId) async {
    setState(() {
      isLoadingRcEvents = true;
      selectedRcAppId = appId;
    });

    try {
      final eventsData = await widget.apiService.getEvents(appId, pageSize: 20);
      if (eventsData != null && eventsData['data'] != null) {
        final events = eventsData['data'] as List;
        if (events.isNotEmpty) {
          setState(() {
            currentRcEvent = Map<String, dynamic>.from(events.first);
            rcFields = _getAllNestedFields([currentRcEvent]);
            rcEvents = events.map((e) => Map<String, dynamic>.from(e)).toList();
          });

          final appInfo = rcApps.firstWhere(
            (app) => app['id'].toString() == appId,
            orElse: () => {'name': 'Unknown App'},
          );
          Provider.of<MappingState>(context, listen: false)
              .setSelectedApp(appId, appInfo['name']);

          final existingMappings =
              Provider.of<MappingState>(context, listen: false)
                  .getMappings(appId);
          if (existingMappings.isNotEmpty) {
            setState(() {
              mappings.clear();
              mappings.addAll(existingMappings);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading RC events: $e');
    } finally {
      setState(() {
        isLoadingRcEvents = false;
      });
    }
  }

  // Mapping functions
  void _addMapping(String sourceField, String targetField, bool isComplex) {
    setState(() {
      // Remove any existing mapping for this target field
      mappings.removeWhere((m) => m['target'] == targetField);

      // Create the new mapping - always create a simple mapping when using the dropdown
      final mapping = {
        'source': sourceField,
        'target': targetField,
        'isComplex': 'false',
        'tokens': '[]',
        'jsonataExpr': '',
      };

      mappings.add(mapping);
      hasUnsavedChanges = true;

      // Update state provider
      if (selectedRcAppId != null) {
        final appInfo = rcApps.firstWhere(
          (app) => app['id'].toString() == selectedRcAppId,
          orElse: () => {'name': 'Unknown App'},
        );
        Provider.of<MappingState>(context, listen: false).setMappings(
            selectedRcAppId!, appInfo['name'], List.from(mappings));
      }
    });
  }

  void _removeMapping(String fieldName) {
    setState(() {
      mappings.removeWhere((m) => m['target'] == fieldName);
      if (selectedRcAppId != null) {
        final appInfo = rcApps.firstWhere(
          (app) => app['id'].toString() == selectedRcAppId,
          orElse: () => {'name': 'Unknown App'},
        );
        Provider.of<MappingState>(context, listen: false).setMappings(
            selectedRcAppId!, appInfo['name'], List.from(mappings));
      }
      hasUnsavedChanges = true;
    });
  }

  // Helper functions
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
      Map<String, dynamic> rcEvent, Map<String, dynamic> mapping) {
    if (mapping.isEmpty) return '';

    try {
      if (mapping['isComplex'] == 'true' && mapping['tokens'] != null) {
        final tokens = List<Map<String, String>>.from(json
            .decode(mapping['tokens']!)
            .map((t) => Map<String, String>.from(t)));

        final parts = tokens.map((token) {
          if (token['type'] == 'field') {
            final fieldPath = token['value']!.substring(1); // Remove $ prefix
            return _getNestedValue(rcEvent, fieldPath)?.toString() ?? '';
          } else if (token['type'] == 'text') {
            // Remove the quotes from the text value for preview
            return token['value']!.substring(1, token['value']!.length - 1);
          }
          return '';
        }).toList();

        return parts.join('');
      } else if (mapping['source'] != null && mapping['source']!.isNotEmpty) {
        return _getNestedValue(rcEvent, mapping['source']!) ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('Error evaluating mapping: $e');
      return '';
    }
  }

  void _showComplexMappingEditor(SaasField field) {
    // Get existing tokens if this is an edit
    List<Map<String, String>> initialTokens = [];
    final existingMapping = mappings.firstWhere(
      (m) => m['target'] == field.name,
      orElse: () => {},
    );

    if (existingMapping.isNotEmpty && existingMapping['tokens'] != null) {
      try {
        initialTokens = List<Map<String, String>>.from(json
            .decode(existingMapping['tokens']!)
            .map((t) => Map<String, String>.from(t)));
      } catch (e) {
        debugPrint('Error parsing tokens: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complex Mapping for ${field.name}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ComplexMappingEditor(
            sourceFields: rcFields,
            currentEvent: currentRcEvent,
            initialTokens: initialTokens,
            onSave: (expression, tokens) {
              setState(() {
                // Remove any existing mapping
                mappings.removeWhere((m) => m['target'] == field.name);

                // Add new complex mapping
                final newMapping = {
                  'target': field.name,
                  'isComplex': 'true',
                  'jsonataExpr': expression,
                  'tokens': json.encode(tokens),
                };
                mappings.add(newMapping);

                // Update state provider
                if (selectedRcAppId != null) {
                  final appInfo = rcApps.firstWhere(
                    (app) => app['id'].toString() == selectedRcAppId,
                    orElse: () => {'name': 'Unknown App'},
                  );
                  Provider.of<MappingState>(context, listen: false).setMappings(
                      selectedRcAppId!, appInfo['name'], List.from(mappings));
                }

                hasUnsavedChanges = true;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedMappings = List<Map<String, dynamic>>.from(mappings)
      ..sort((a, b) => (a['target'] ?? '').compareTo(b['target'] ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Mapper'),
        actions: [
          if (hasUnsavedChanges)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () {
                // Save mappings
                if (selectedRcAppId != null) {
                  final appInfo = rcApps.firstWhere(
                    (app) => app['id'].toString() == selectedRcAppId,
                    orElse: () => {'name': 'Unknown App'},
                  );
                  Provider.of<MappingState>(context, listen: false).setMappings(
                      selectedRcAppId!, appInfo['name'], List.from(mappings));
                  setState(() {
                    hasUnsavedChanges = false;
                  });
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          // Top section - Source Fields and Mappings
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Source Fields
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButton<String>(
                            value: selectedRcAppId,
                            hint: const Text('Select App'),
                            isExpanded: true,
                            items: rcApps.map((app) {
                              return DropdownMenuItem(
                                value: app['id'].toString(),
                                child: Text(app['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) _loadRcEvents(value);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: sourceSearchController,
                            decoration: const InputDecoration(
                              hintText: 'Search source fields...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                sourceSearchQuery = value;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredSourceFields.length,
                            itemBuilder: (context, index) {
                              final field = filteredSourceFields[index];
                              return Draggable<Map<String, dynamic>>(
                                data: {
                                  'field': field,
                                  'isSource': true,
                                },
                                feedback: Material(
                                  elevation: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.blue.withOpacity(0.8),
                                    child: Text(
                                      field,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                child: Card(
                                  child: ListTile(
                                    title: Text(field),
                                    subtitle: Text(
                                      _getNestedValue(currentRcEvent, field) ??
                                          '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Current Mappings
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Current Mappings',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: sortedMappings.length,
                            itemBuilder: (context, index) {
                              final mapping = sortedMappings[index];
                              final targetField = saasFields.firstWhere(
                                (f) => f.name == mapping['target'],
                                orElse: () => SaasField(
                                  name: mapping['target'] ?? '',
                                  required: false,
                                  description: '',
                                  type: 'string',
                                ),
                              );
                              return Card(
                                child: ListTile(
                                  leading: targetField.required
                                      ? const Icon(Icons.star,
                                          color: Colors.red)
                                      : null,
                                  title: Text(
                                    mapping['isComplex'] == 'true'
                                        ? '[Complex Mapping] → ${mapping['target']}'
                                        : '${mapping['source'] ?? ''} → ${mapping['target']}',
                                  ),
                                  subtitle: Text(
                                    targetField.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _removeMapping(mapping['target'] ?? ''),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Bottom section - Events Table with Droppable Columns
          Expanded(
            child: rcEvents.isEmpty
                ? const Center(child: Text('Select an app to view events'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Data Table
                          DataTable(
                            columns: [
                              const DataColumn(label: Text('RC Event ID')),
                              ...saasFields.map((field) => DataColumn(
                                    label: SizedBox(
                                      height: 56, // Fixed height for the header
                                      child: DragTarget<Map<String, dynamic>>(
                                        onWillAccept: (data) =>
                                            data != null &&
                                            data['field'] != null,
                                        onAccept: (data) {
                                          if (data['field'] != null) {
                                            _addMapping(
                                              data['field'] as String,
                                              field.name,
                                              false,
                                            );
                                          }
                                        },
                                        builder: (context, candidateData,
                                                rejectedData) =>
                                            Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: candidateData.isNotEmpty
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    field.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: field.required
                                                          ? Colors.red
                                                          : null,
                                                    ),
                                                  ),
                                                  if (field.required)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 4),
                                                      child: Icon(
                                                        Icons.star,
                                                        size: 12,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  const SizedBox(width: 4),
                                                  Tooltip(
                                                    message: field.description,
                                                    child: const Icon(
                                                      Icons.info_outline,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              SizedBox(
                                                width: 180,
                                                height: 24,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          mappings.any((m) =>
                                                                  m['target'] ==
                                                                  field.name)
                                                              ? Text(
                                                                  mappings.firstWhere((m) => m['target'] == field.name)[
                                                                              'isComplex'] ==
                                                                          'true'
                                                                      ? '[Complex Mapping]'
                                                                      : mappings.firstWhere((m) =>
                                                                          m['target'] ==
                                                                          field
                                                                              .name)['source']!,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                )
                                                              : Container(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    border: Border.all(
                                                                        color: Colors
                                                                            .grey
                                                                            .shade300),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(4),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .drag_indicator,
                                                                        size:
                                                                            14,
                                                                        color: candidateData.isNotEmpty
                                                                            ? Colors.blue
                                                                            : Colors.grey.withOpacity(0.5),
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              4),
                                                                      Expanded(
                                                                        child:
                                                                            InkWell(
                                                                          onTap:
                                                                              () {
                                                                            final TextEditingController
                                                                                searchController =
                                                                                TextEditingController();
                                                                            String
                                                                                searchQuery =
                                                                                '';

                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return StatefulBuilder(
                                                                                  builder: (context, setState) {
                                                                                    final filteredFields = rcFields.where((field) {
                                                                                      final value = _getNestedValue(rcEvents.first, field)?.toString().toLowerCase() ?? '';
                                                                                      return field.toLowerCase().contains(searchQuery.toLowerCase()) || value.toLowerCase().contains(searchQuery.toLowerCase());
                                                                                    }).toList();

                                                                                    return AlertDialog(
                                                                                      title: Column(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                          Text(field.name, style: const TextStyle(fontSize: 16)),
                                                                                          const SizedBox(height: 8),
                                                                                          TextField(
                                                                                            controller: searchController,
                                                                                            decoration: const InputDecoration(
                                                                                              hintText: 'Search fields or values...',
                                                                                              prefixIcon: Icon(Icons.search),
                                                                                              isDense: true,
                                                                                              border: OutlineInputBorder(),
                                                                                            ),
                                                                                            onChanged: (value) {
                                                                                              setState(() {
                                                                                                searchQuery = value;
                                                                                              });
                                                                                            },
                                                                                            autofocus: true,
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                      content: SizedBox(
                                                                                        width: 400,
                                                                                        height: 300,
                                                                                        child: ListView.builder(
                                                                                          itemCount: filteredFields.length,
                                                                                          itemBuilder: (context, index) {
                                                                                            final sourceField = filteredFields[index];
                                                                                            final sampleValue = _getNestedValue(rcEvents.first, sourceField);
                                                                                            return ListTile(
                                                                                              title: Text(sourceField),
                                                                                              subtitle: Text(
                                                                                                sampleValue?.toString() ?? 'null',
                                                                                                style: TextStyle(
                                                                                                  color: Colors.grey[600],
                                                                                                  fontStyle: FontStyle.italic,
                                                                                                ),
                                                                                              ),
                                                                                              onTap: () {
                                                                                                _addMapping(sourceField, field.name, false);
                                                                                                Navigator.of(context).pop();
                                                                                              },
                                                                                            );
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            'Select field',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 12,
                                                                              color: field.required ? Colors.red : Colors.grey,
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                    ),
                                                    if (!mappings.any((m) =>
                                                        m['target'] ==
                                                        field.name))
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.code),
                                                        tooltip:
                                                            'Create Complex Mapping',
                                                        onPressed: () =>
                                                            _showComplexMappingEditor(
                                                                field),
                                                        iconSize: 16,
                                                      ),
                                                    if (mappings.any((m) =>
                                                        m['target'] ==
                                                        field.name))
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.clear),
                                                        onPressed: () =>
                                                            _removeMapping(
                                                                field.name),
                                                        iconSize: 16,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                            rows: rcEvents.map((event) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(event['id'].toString())),
                                  ...saasFields.map((field) {
                                    final mapping = mappings.firstWhere(
                                      (m) => m['target'] == field.name,
                                      orElse: () => {},
                                    );
                                    final value =
                                        _evaluateMapping(event, mapping);
                                    return DataCell(
                                      Text(
                                        value.isEmpty ? '' : value,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
