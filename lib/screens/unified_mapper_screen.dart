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
import '../services/field_mapping_service.dart';
import './saved_mappings_screen.dart';
import '../models/saved_mapping.dart';
import '../services/mapping_export_service.dart';

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
  String selectedInputMode = 'elastic';
  int selectedRecordLimit = 5;
  final List<int> recordLimits = [1, 5, 10, 20, 50, 100, 200];

  // Elastic Raw input state
  final TextEditingController elasticRequestController =
      TextEditingController();
  final TextEditingController elasticResponseController =
      TextEditingController();
  int selectedElasticTab = 0; // 0 for Request, 1 for Response

  // Single scroll controller
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSaasFields();

    // Synchronize horizontal scrolling
    _horizontalController.addListener(() {
      if (_horizontalController.position.pixels !=
          _horizontalController.position.pixels) {
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
    elasticRequestController.dispose();
    elasticResponseController.dispose();
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
      final value = FieldMappingService.getNestedValue(currentRcEvent, field)
          .toLowerCase();
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
    final fields = saasFields
        .where((field) => field.category == 'Configuration')
        .toList()
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
      final loadedFields = fields.entries
          .map((e) => SaasField.fromJson(e.key, e.value))
          .toList();

      setState(() {
        saasFields = loadedFields;
        isLoadingSaasFields = false;

        for (var field in loadedFields) {
          if (field.type == 'picklist' &&
              field.options != null &&
              field.options!.isNotEmpty) {
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
    if (data.isEmpty) return [];
    return FieldMappingService.getAllFields(
        data.first as Map<String, dynamic>, prefix);
  }

  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    return FieldMappingService.getNestedValue(data, path);
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

    // Create sample values map
    final sampleValues = Map.fromEntries(
      rcFields.map((field) {
        String value = _getNestedValue(rcEvents.first, field).toString();
        // Limit sample value length to prevent rendering issues
        if (value.length > 50) {
          value = '${value.substring(0, 47)}...';
        }
        return MapEntry(field, value);
      }),
    );

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
            sampleValues: sampleValues,
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
    // Create a temporary SavedMapping from current state
    final currentMapping = SavedMapping(
      name: 'Current Mapping',
      product: selectedRcAppId ?? 'Unknown',
      query: elasticRequestController.text,
      mappings: mappings,
      configFields: configFields,
      totalFieldsMapped: mappings.length,
      requiredFieldsMapped: _calculateRequiredFieldsMapped(),
      totalRequiredFields: _calculateTotalRequiredFields(),
    );

    MappingExportService.showSingleMappingExportDialog(context, currentMapping);
  }

  void _showExportOptions() {
    ExportOptionsDialog.show(
      context,
      onCSVExport: _exportAsCSV,
      onJSONExport: _exportAsJSON,
    );
  }

  void _clearJson() {
    if (selectedInputMode == 'elastic') {
      elasticRequestController.clear();
      elasticResponseController.clear();
    } else {
      jsonInputController.clear();
    }
  }

  void _confirmAndParseJson() {
    if (mappings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'Parsing new JSON could result in fields becoming unmapped if they are no longer present in the new JSON file. Do you want to continue?'),
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

  void _parseJson() {
    try {
      if (selectedInputMode == 'elastic') {
        // Parse both request and response data
        final requestData = elasticRequestController.text.isNotEmpty
            ? json.decode(elasticRequestController.text)
            : null;
        final responseData = elasticResponseController.text.isNotEmpty
            ? json.decode(elasticResponseController.text)
            : null;

        if (responseData == null) {
          throw Exception('Response data is required for Elastic Raw format');
        }

        // Parse the rawResponse which contains the actual Elastic data
        final rawResponse = responseData['rawResponse'];
        if (rawResponse == null) {
          throw Exception('No rawResponse found in Elastic data');
        }

        // Parse or use the raw response
        final elasticData =
            rawResponse is String ? json.decode(rawResponse) : rawResponse;

        // Extract hits from response data
        List? hits;
        if (elasticData['hits']?['hits'] != null) {
          hits = elasticData['hits']['hits'] as List?;
        }

        if (hits == null || hits.isEmpty) {
          throw Exception(
              'No records found in Elastic Response data. Please check the data format.');
        }

        // Extract query from request if available
        String? querySection;
        if (requestData != null && requestData['query'] != null) {
          querySection = json.encode(requestData['query']);
        }

        setState(() {
          // Use only the fields object for mapping, not the Elasticsearch metadata
          final firstHit = hits![0];
          currentRcEvent = Map<String, dynamic>.from(firstHit['fields']);
          final newRcFields = _getAllNestedFields([currentRcEvent]);

          // Remove mappings where the source field no longer exists
          mappings.removeWhere((mapping) {
            if (mapping['isComplex'] == 'true') {
              // For complex mappings, check each field in the tokens
              if (mapping['tokens'] != null) {
                try {
                  final tokens = List<Map<String, String>>.from(json
                      .decode(mapping['tokens']!)
                      .map((t) => Map<String, String>.from(t)));

                  // Check each field token and mark removed fields
                  bool hasChanges = false;
                  for (var i = 0; i < tokens.length; i++) {
                    if (tokens[i]['type'] == 'field') {
                      final fieldPath = tokens[i]['value']!
                          .substring(1); // Remove the $ prefix
                      if (!newRcFields.contains(fieldPath)) {
                        tokens[i]['value'] = '$fieldPath(removed)';
                        tokens[i]['type'] = 'text';
                        hasChanges = true;
                      }
                    }
                  }

                  if (hasChanges) {
                    mapping['tokens'] = json.encode(tokens);
                    hasUnsavedChanges = true;
                  }
                } catch (e) {
                  debugPrint('Error processing complex mapping tokens: $e');
                }
              }
              return false; // Keep complex mappings
            }
            return !newRcFields.contains(mapping[
                'source']); // Remove simple mappings if field doesn't exist
          });

          // Update rcFields and rcEvents
          rcFields = newRcFields;
          rcEvents = hits
              .take(selectedRecordLimit)
              .map((hit) => Map<String, dynamic>.from(hit['fields']))
              .toList();
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
          if (currentRcEvent['product.endpoint.id'] != null) {
            final endpointId =
                _getNestedValue(currentRcEvent, 'product.endpoint.id');
            if (endpointId != null) {
              configFields['endpointId'] = endpointId.toString();
            }
          }

          // Set the query section if available
          if (querySection != null) {
            configFields['eventFilter'] = querySection;
          }
        });
      } else {
        // Handle JSON format
        final jsonData = json.decode(jsonInputController.text);
        setState(() {
          currentRcEvent = Map<String, dynamic>.from(jsonData);
          final newRcFields = _getAllNestedFields([currentRcEvent]);

          // Remove mappings where the source field no longer exists
          mappings.removeWhere((mapping) {
            if (mapping['isComplex'] == 'true') return false;
            return !newRcFields.contains(mapping['source']);
          });

          // Update rcFields and rcEvents
          rcFields = newRcFields;
          rcEvents = [currentRcEvent];
          selectedRcAppId = null;

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
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          mappings.firstWhere((m) => m['target'] == field.name)[
                                      'isComplex'] ==
                                  'true'
                              ? _getComplexMappingPreview(mappings
                                  .firstWhere((m) => m['target'] == field.name))
                              : mappings.firstWhere(
                                  (m) => m['target'] == field.name)['source']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasRemovedFields(mappings.firstWhere(
                                    (m) => m['target'] == field.name))
                                ? Colors.red
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (mappings.firstWhere(
                            (m) => m['target'] == field.name)['isComplex'] ==
                        'true')
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        tooltip: 'Edit Complex Mapping',
                        onPressed: () => _showComplexMappingEditor(field),
                      ),
                  ],
                )
              : SearchableDropdown(
                  items: rcFields.map((sourceField) {
                    String sampleValue =
                        _getNestedValue(rcEvents.first, sourceField).toString();
                    // Limit sample value length to prevent rendering issues
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

  String _getComplexMappingPreview(Map<String, dynamic> mapping) {
    if (mapping['tokens'] == null) return '[Complex Mapping]';
    try {
      final tokens = List<Map<String, String>>.from(json
          .decode(mapping['tokens']!)
          .map((t) => Map<String, String>.from(t)));

      final preview = tokens.map((token) {
        if (token['type'] == 'field') {
          return '\$${token['value']!.substring(1)}'; // Add back the $ for fields
        } else if (token['value']!.endsWith('(removed)')) {
          return token['value']; // Keep the removal marker as is
        } else {
          return token['value']!.substring(
              1, token['value']!.length - 1); // Remove quotes for text
        }
      }).join(' ');

      return preview;
    } catch (e) {
      return '[Complex Mapping]';
    }
  }

  bool _hasRemovedFields(Map<String, dynamic> mapping) {
    if (mapping['isComplex'] != 'true' || mapping['tokens'] == null)
      return false;
    try {
      final tokens = List<Map<String, String>>.from(json
          .decode(mapping['tokens']!)
          .map((t) => Map<String, String>.from(t)));
      return tokens.any((t) => t['value']?.endsWith('(removed)') ?? false);
    } catch (e) {
      return false;
    }
  }

  void _showSaveAsDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final mappingState = Provider.of<MappingState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Mapping As'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mapping Name',
                  hintText: 'Enter a name for this mapping',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.length > 200) {
                    return 'Name must be 200 characters or less';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final name = nameController.text;
                final appInfo = selectedRcAppId != null
                    ? rcApps.firstWhere(
                        (app) => app['id'].toString() == selectedRcAppId,
                        orElse: () => {'name': 'Unknown App'},
                      )
                    : {'name': 'Unknown App'};

                // Create the saved mapping
                final savedMapping = SavedMapping(
                  name: name,
                  product: appInfo['name'],
                  query: _getCurrentQuery() ?? '',
                  mappings: List.from(mappings),
                  configFields: Map.from(configFields),
                  totalFieldsMapped: mappings.length,
                  requiredFieldsMapped: mappings
                      .where((m) => saasFields
                          .firstWhere((f) => f.name == m['target'])
                          .required)
                      .length,
                  totalRequiredFields:
                      saasFields.where((f) => f.required).length,
                );

                // Check for duplicate queries
                final duplicates =
                    mappingState.findMappingsWithQuery(savedMapping.query);
                if (duplicates.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Duplicate Query Found'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The following mappings use the same query:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...duplicates.map((m) => Text('• ${m.name}')),
                          const SizedBox(height: 16),
                          const Text('Do you want to continue saving?'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            mappingState.addSavedMapping(savedMapping);
                            Navigator.pop(context); // Close duplicate warning
                            Navigator.pop(context); // Close save dialog
                            setState(() => hasUnsavedChanges = false);
                          },
                          child: const Text('Save Anyway'),
                        ),
                      ],
                    ),
                  );
                } else {
                  mappingState.addSavedMapping(savedMapping);
                  Navigator.pop(context);
                  setState(() => hasUnsavedChanges = false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _getCurrentQuery() {
    if (selectedInputMode == 'elastic') {
      try {
        final requestData = json.decode(elasticRequestController.text);
        if (requestData['query'] != null) {
          return json.encode(requestData['query']);
        }
      } catch (e) {
        debugPrint('Error getting query from elastic request: $e');
      }
    }
    return null;
  }

  int _calculateRequiredFieldsMapped() {
    return mappings.where((m) {
      final targetField = saasFields.firstWhere(
        (f) => f.name == m['target'],
        orElse: () => SaasField(
          name: '',
          description: '',
          type: 'string',
          category: 'default',
          required: false,
        ),
      );
      return targetField.required;
    }).length;
  }

  int _calculateTotalRequiredFields() {
    return saasFields.where((f) => f.required).length;
  }

  Widget _buildSaveButton() {
    return IconButton(
      key: const Key('save_button'),
      icon: const Icon(Icons.save),
      onPressed: hasUnsavedChanges ? _showSaveDialog : null,
      tooltip: 'Save Mapping',
    );
  }

  Future<void> _showSaveDialog() async {
    final mappingState = Provider.of<MappingState>(context, listen: false);
    final TextEditingController nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Mapping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Mapping Name',
                hintText: 'Enter a name for this mapping',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                mappingState.setMappings(
                  selectedRcAppId!,
                  nameController.text,
                  mappings.map((m) => Map<String, String>.from(m)).toList(),
                );
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        hasUnsavedChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Mapper'),
        actions: [
          IconButton(
            key: const Key('save_button'),
            icon: const Icon(Icons.save),
            onPressed: _showSaveDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: elasticRequestController,
                          maxLines: null,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Paste Elastic Request JSON here...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: elasticResponseController,
                          maxLines: null,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Paste Elastic Response JSON here...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ... rest of the existing code ...
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDataSource extends DataTableSource {
  final List<Map<String, dynamic>> events;
  final List<SaasField> fields;
  final List<Map<String, dynamic>> mappings;
  final Function(Map<String, dynamic>, Map<String, dynamic>) evaluateMapping;

  _EventDataSource(
      this.events, this.fields, this.mappings, this.evaluateMapping);

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
