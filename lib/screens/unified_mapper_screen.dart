import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';
import 'package:flutter/services.dart';
import '../widgets/complex_mapping_editor.dart';
import '../widgets/json_preview_widget.dart';
import '../widgets/configuration_fields_widget.dart';
import '../services/export_service.dart';
import '../widgets/export_options_dialog.dart';
import '../widgets/searchable_dropdown.dart';

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollBehavior copyWith({
    bool? scrollbars,
    ScrollPhysics? physics,
    bool? overscroll,
    Set<PointerDeviceKind>? dragDevices,
    TargetPlatform? platform,
    Set<LogicalKeyboardKey>? pointerAxisModifiers,
    MultitouchDragStrategy? multitouchDragStrategy,
  }) {
    return CustomScrollBehavior();
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics();
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Scrollbar(
          controller: details.controller,
          thumbVisibility: true,
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class SaasField {
  final String name;
  final bool required;
  final String description;
  final String type;
  final String defaultMode;
  final String category;
  final int displayOrder;
  final List<String>? options;

  SaasField({
    required this.name,
    required this.required,
    required this.description,
    required this.type,
    this.defaultMode = 'simple',
    required this.category,
    this.displayOrder = 999,
    this.options,
  });

  factory SaasField.fromJson(String name, Map<String, dynamic> json) {
    int displayOrder = 999;
    final rawDisplayOrder = json['displayOrder'];
    if (rawDisplayOrder != null) {
      if (rawDisplayOrder is int) {
        displayOrder = rawDisplayOrder;
      } else if (rawDisplayOrder is String) {
        try {
          displayOrder = int.parse(rawDisplayOrder);
        } catch (e) {
          debugPrint('Error parsing displayOrder for $name: $e');
        }
      }
    }

    final required = json['required'] == true;
    final description = json['description']?.toString() ?? '';
    final type = json['type']?.toString().toLowerCase() ?? 'string';
    final defaultMode = json['defaultMode']?.toString() ?? 'simple';
    final category = json['category']?.toString() ?? 'Standard';

    List<String>? options;
    if (type == 'picklist') {
      try {
        if (json['options'] is List) {
          options = (json['options'] as List).map((e) => e.toString()).toList();
        }
      } catch (e) {
        debugPrint('Error parsing options: $e');
      }
    }

    return SaasField(
      name: name,
      required: required,
      description: description,
      type: type,
      defaultMode: defaultMode,
      category: category,
      displayOrder: displayOrder,
      options: options,
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
  final Map<String, String> configFields = {};

  // Input mode state
  String selectedInputMode = 'app';
  String selectedJsonMode = 'elastic';

  // Single scroll controller
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRcApps();
    _loadSaasFields();
    
    // Synchronize horizontal scrolling
    _horizontalController.addListener(() {
      if (_horizontalController.position.pixels != _horizontalController.position.pixels) {
        _horizontalController.jumpTo(_horizontalController.position.pixels);
      }
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
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

  List<SaasField> get standardFields {
    final fields =
        saasFields.where((field) => field.category == 'Standard').toList();
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

  List<SaasField> get configurationFields {
    final fields = saasFields.where((field) => field.category == 'Configuration').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return fields;
  }

  List<Map<String, dynamic>> get configurationFieldsForWidget {
    final fields = configurationFields.map((field) {
      final Map<String, dynamic> fieldData = {
        'name': field.name,
        'required': field.required,
        'description': field.description,
        'type': field.type,
        'options': field.options,
      };
      return fieldData;
    }).toList();
    return fields;
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
      final jsonData = await widget.saasAlertsApi.getFields();
      if (jsonData == null) {
        throw Exception('Failed to load fields from SaasAlertsApiService');
      }

      final fields = jsonData['fields'] as Map<String, dynamic>;
      final loadedFields = fields.entries.map((e) => SaasField.fromJson(e.key, e.value)).toList();

      setState(() {
        saasFields = loadedFields;
        isLoadingSaasFields = false;

        for (var field in loadedFields) {
          if (field.type == 'picklist' && field.options != null && field.options!.isNotEmpty) {
            configFields[field.name] = field.options!.first;
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading SaaS fields: $e');
      debugPrint('Stack trace: $stackTrace');
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

          setState(() {
            mappings.clear();
            mappings.addAll(existingMappings);

            for (var sourceField in rcFields) {
              for (var saasField in saasFields) {
                if (saasField.name == sourceField &&
                    !mappings.any((m) => m['target'] == saasField.name)) {
                  mappings.add({
                    'source': sourceField,
                    'target': saasField.name,
                    'isComplex': 'false',
                  });
                }
              }
            }

            if (mappings.length > existingMappings.length) {
              hasUnsavedChanges = true;
              Provider.of<MappingState>(context, listen: false)
                  .setMappings(appId, appInfo['name'], List.from(mappings));
            }
          });
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
            final fieldPath = token['value']!.substring(1);
            return _getNestedValue(rcEvent, fieldPath)?.toString() ?? '';
          } else if (token['type'] == 'text') {
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

  // Add this method to generate JSON preview
  Map<String, dynamic> _generateJsonPreview() {
    final mappingSchema = <String, dynamic>{};
    for (var mapping in mappings) {
      if (mapping['isComplex'] == 'true') {
        mappingSchema[mapping['target']!] = mapping['jsonataExpr'] ?? '';
      } else {
        mappingSchema[mapping['target']!] = mapping['source'];
      }
    }

    return {
      'accountKey': {'field': 'data.id', 'type': 'id'},
      'dateKeyField': 'data.createdAt',
      'endpointId': int.tryParse(configFields['endpointId'] ?? '0') ?? 0,
      'endpointName': 'events',
      'eventFilter':
          '{\n  "query": {\n    "bool": {\n      "must": [],\n      "filter": [],\n      "should": [],\n      "must_not": []\n    }\n  }\n}',
      'eventType': configFields['eventType'] ?? 'EVENT',
      'eventTypeKey': configFields['eventType'] ?? 'EVENT',
      'productRef': {
        '__ref__': configFields['productRef'] ?? 'products/default'
      },
      'userKeyField': 'data.userId',
      'schema': mappingSchema,
    };
  }

  // Add this method to show JSON export dialog
  void _showJsonExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Mappings JSON'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: JsonPreviewWidget(
            jsonData: _generateJsonPreview(),
            showExportButton: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Add this method to handle configuration field changes
  void _handleConfigFieldChange(String key, String value) {
    setState(() {
      configFields[key] = value;
    });
  }

  // Add export methods
  void _exportAsCSV() {
    final csvContent = ExportService.generateCSVContent(
      mappings: mappings,
      currentEvent: currentRcEvent,
      selectedAppId: selectedRcAppId,
      apps: rcApps,
      getNestedValue: _getNestedValue,
      saasFields: saasFields,
    );
    ExportService.showCSVExportDialog(context, csvContent);
  }

  void _exportAsJSON() {
    ExportService.showJSONExportDialog(
      context,
      jsonPreviewWidget: JsonPreviewWidget(
        jsonData: _generateJsonPreview(),
        showExportButton: false,
      ),
    );
  }

  void _showExportOptions() {
    ExportOptionsDialog.show(
      context,
      onCSVExport: _exportAsCSV,
      onJSONExport: _exportAsJSON,
    );
  }

  void _parseJson() {
    try {
      final jsonData = json.decode(jsonInputController.text);

      if (selectedJsonMode == 'elastic') {
        // Handle Elastic Raw format - process entire JSON structure
        setState(() {
          currentRcEvent = Map<String, dynamic>.from(jsonData);
          rcFields = _getAllNestedFields([currentRcEvent]);
          rcEvents = [currentRcEvent];
          selectedRcAppId = null; // Clear selected app

          // Auto-map matching fields that aren't already mapped
          for (var sourceField in rcFields) {
            for (var saasField in saasFields) {
              final isMatching = saasField.name == sourceField;
              final isAlreadyMapped =
                  mappings.any((m) => m['target'] == saasField.name);

              if (isMatching && !isAlreadyMapped) {
                mappings.add({
                  'source': sourceField,
                  'target': saasField.name,
                  'isComplex': 'false',
                });
                hasUnsavedChanges = true;
              }
            }
          }

          // Auto-map special fields if they exist
          if (jsonData['_source']?['product']?['endpoint']?['id'] != null) {
            configFields['endpointId'] =
                jsonData['_source']['product']['endpoint']['id'].toString();
          }
        });
      } else {
        // Handle misc JSON format
        setState(() {
          currentRcEvent = Map<String, dynamic>.from(jsonData);
          rcFields = _getAllNestedFields([currentRcEvent]);
          rcEvents = [currentRcEvent];
          selectedRcAppId = null; // Clear selected app

          // Auto-map matching fields that aren't already mapped
          for (var sourceField in rcFields) {
            for (var saasField in saasFields) {
              final isMatching = saasField.name == sourceField;
              final isAlreadyMapped =
                  mappings.any((m) => m['target'] == saasField.name);

              if (isMatching && !isAlreadyMapped) {
                mappings.add({
                  'source': sourceField,
                  'target': saasField.name,
                  'isComplex': 'false',
                });
                hasUnsavedChanges = true;
              }
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: $e')),
      );
    }
  }

  void _clearJson() {
    jsonInputController.clear();
  }

  void _confirmAndParseJson() {
    if (mappings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'Parsing new JSON will discard all current mappings. Do you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _parseJson();
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } else {
      _parseJson();
    }
  }

  List<DataColumn> _buildDataColumns() {
    final List<DataColumn> columns = [];
    final sortedFields = standardFields;

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

  Widget _buildMappingControl(SaasField field) {
    return Row(
      children: [
        Expanded(
          child: mappings.any((m) => m['target'] == field.name)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    mappings.firstWhere((m) => m['target'] == field.name)['isComplex'] == 'true'
                        ? '[Complex Mapping]'
                        : mappings.firstWhere((m) => m['target'] == field.name)['source']!,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : SearchableDropdown(
                  items: rcFields.map((sourceField) {
                    final sampleValue = _getNestedValue(rcEvents.first, sourceField);
                    return SearchableDropdownItem(
                      value: sourceField,
                      label: sourceField,
                      subtitle: sampleValue?.toString() ?? 'null',
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
                      _addMapping(value, field.name, false);
                    }
                  },
                ),
        ),
        if (!mappings.any((m) => m['target'] == field.name))
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Create Complex Mapping',
            onPressed: () => _showComplexMappingEditor(field),
            iconSize: 16,
          ),
        if (mappings.any((m) => m['target'] == field.name))
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _removeMapping(field.name),
            iconSize: 16,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedMappings = List<Map<String, dynamic>>.from(mappings)
      ..sort((a, b) => (a['target'] ?? '').compareTo(b['target'] ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.flight_takeoff, size: 24), // Fighter plane icon
            SizedBox(width: 8), // Space between icon and text
            Text('Maverick Mapper'),
          ],
        ),
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
          // Top section - Configuration Fields and Current Mappings
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Configuration Fields
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Input Source',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'app',
                                    label: Text('Select App'),
                                    icon: Icon(Icons.apps),
                                  ),
                                  ButtonSegment(
                                    value: 'json',
                                    label: Text('Paste JSON'),
                                    icon: Icon(Icons.code),
                                  ),
                                ],
                                selected: {selectedInputMode},
                                onSelectionChanged: (Set<String> newSelection) {
                                  if (mappings.isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Warning'),
                                        content: const Text(
                                            'Changing input source will discard all current mappings. Do you want to continue?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                mappings.clear();
                                                selectedInputMode =
                                                    newSelection.first;
                                                selectedRcAppId = null;
                                                jsonInputController.clear();
                                                currentRcEvent = {};
                                                rcFields = [];
                                                rcEvents = [];
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Continue'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      selectedInputMode = newSelection.first;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (selectedInputMode == 'app')
                            DropdownButton<String>(
                              value: selectedRcAppId,
                              hint: const Text('Select an application'),
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
                            )
                          else
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'elastic',
                                        label: Text('Elastic Raw'),
                                      ),
                                      ButtonSegment(
                                        value: 'misc',
                                        label: Text('Misc'),
                                      ),
                                    ],
                                    selected: {selectedJsonMode},
                                    onSelectionChanged:
                                        (Set<String> newSelection) {
                                      setState(() {
                                        selectedJsonMode = newSelection.first;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: TextFormField(
                                                  controller:
                                                      jsonInputController,
                                                  maxLines: null,
                                                  decoration:
                                                      const InputDecoration
                                                          .collapsed(
                                                    hintText:
                                                        'Paste JSON here...',
                                                  ),
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: _clearJson,
                                                    icon: const Icon(
                                                        Icons.clear,
                                                        size: 18),
                                                    label: const Text('Clear'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        _confirmAndParseJson,
                                                    icon: const Icon(
                                                        Icons.check,
                                                        size: 18),
                                                    label: const Text('Parse'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
                          child: Row(
                            children: [
                              Text(
                                'Current Mappings',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                onPressed: _showJsonExportDialog,
                                tooltip: 'View JSON',
                              ),
                              IconButton(
                                icon: const Icon(Icons.download, size: 20),
                                onPressed: _showExportOptions,
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
                                (f) => f.name == mapping['target'],
                                orElse: () => SaasField(
                                  name: mapping['target'] ?? '',
                                  required: false,
                                  description: '',
                                  type: 'string',
                                  category: 'Standard',
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
          const Divider(),
          // Bottom section - Events Table
          Expanded(
            child: rcEvents.isEmpty
                ? const Center(child: Text('Select an app to view events'))
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      physics: const ClampingScrollPhysics(),
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const ClampingScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: DataTable(
                          horizontalMargin: 16,
                          columnSpacing: 16,
                          headingRowHeight: 100,
                          columns: _buildDataColumns(),
                          rows: rcEvents.map((event) {
                            return DataRow(
                              cells: standardFields.map((field) {
                                final mapping = mappings.firstWhere(
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
                        ),
                      ),
                    ),
                  ),
          ),
          const Divider(),
          ConfigurationFieldsWidget(
            configFields: configFields,
            onConfigFieldChanged: _handleConfigFieldChange,
            configurationFields: configurationFieldsForWidget,
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _EventDataSource extends DataTableSource {
  final List<Map<String, dynamic>> events;
  final List<SaasField> fields;
  final List<Map<String, dynamic>> mappings;
  final Function(Map<String, dynamic>, Map<String, dynamic>) evaluateMapping;

  _EventDataSource(this.events, this.fields, this.mappings, this.evaluateMapping);

  @override
  DataRow? getRow(int index) {
    if (index >= events.length) return null;
    final event = events[index];
    return DataRow(
      cells: fields.map((field) {
        final mapping = mappings.firstWhere(
          (m) => m['target'] == field.name,
          orElse: () => {},
        );
        final value = evaluateMapping(event, mapping);
        return DataCell(
          Text(
            value.isEmpty ? '' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => events.length;

  @override
  int get selectedRowCount => 0;
}
