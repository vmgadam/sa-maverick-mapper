import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';
import '../state/saved_mappings_state.dart';
import '../widgets/complex_mapping_editor.dart';
import '../widgets/json_preview_widget.dart';
import '../widgets/configuration_fields_widget.dart';
import '../services/export_service.dart';
import '../widgets/export_options_dialog.dart';
import '../widgets/searchable_dropdown.dart';
import '../services/field_mapping_service.dart';
import '../widgets/saved_mappings/saved_mappings_section.dart';
import '../models/saved_mapping.dart';
import '../models/saas_field.dart';
import '../widgets/event_name_input.dart';
import '../widgets/behaviors/custom_scroll_behavior.dart';
import '../widgets/elastic/elastic_input_section.dart';
import '../widgets/mapping_table/mapping_table_section.dart';
import '../mixins/elastic_data_mixin.dart';
import '../mixins/mapping_state_mixin.dart';

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

class _UnifiedMapperScreenState extends State<UnifiedMapperScreen>
    with ElasticDataMixin, MappingStateMixin {
  // Source data state
  final List<dynamic> rcApps = [];
  Map<String, dynamic> currentRcEvent = {};
  List<String> rcFields = [];
  bool isLoadingRcApps = true;
  bool isLoadingRcEvents = false;

  // Event name state
  final TextEditingController eventNameController = TextEditingController();

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

  // Add tracking for currently loaded mapping
  SavedMapping? currentLoadedMapping;

  // Add timer for debouncing
  Timer? _debounceTimer;
  bool _isProcessingRequest = false;
  bool _isProcessingResponse = false;

  @override
  void initState() {
    super.initState();
    _loadSaasFields();

    // Remove text change listeners
    _horizontalController.addListener(() {
      if (_horizontalController.position.pixels !=
          _horizontalController.position.pixels) {
        _horizontalController.jumpTo(_horizontalController.position.pixels);
      }
    });

    eventNameController.addListener(_updateCanParse);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _horizontalController.dispose();
    sourceSearchController.dispose();
    saasSearchController.dispose();
    jsonInputController.dispose();
    elasticRequestController.dispose();
    elasticResponseController.dispose();
    eventNameController.dispose();
    eventNameController.removeListener(_updateCanParse);
    super.dispose();
  }

  // Simplify canParse to only check if fields have content
  bool get canParse => eventNameController.text.isNotEmpty;

  void _updateCanParse() {
    setState(() {
      // This will trigger a rebuild with the updated canParse value
    });
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
    final fields = saasFields
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

  List<SaasField> get configurationFields {
    final fields = saasFields
        .where((field) => field.category.toLowerCase() == 'configuration')
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

        // Initialize configuration fields with default values
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
      rcEvents.clear();
      rcFields.clear();
    });

    try {
      final eventsData = await widget.apiService
          .getEvents(appId, pageSize: selectedRecordLimit);
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

          // Set the selected product in SavedMappingsState
          Provider.of<SavedMappingsState>(context, listen: false)
              .setSelectedProduct(appInfo['name']);

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

      // Create the new mapping
      final mapping = {
        'source': sourceField,
        'target': targetField,
        'isComplex': 'false',
        'tokens': '[]',
        'jsonataExpr': '',
      };

      mappings.add(mapping);
      hasUnsavedChanges = true;

      // Update state provider if we have a current loaded mapping
      if (currentLoadedMapping != null) {
        Provider.of<MappingState>(context, listen: false).setMappings(
          'Elastic',
          currentLoadedMapping!.product,
          List.from(mappings),
        );
      }
    });
  }

  void _removeMapping(String fieldName) {
    setState(() {
      mappings.removeWhere((m) => m['target'] == fieldName);
      if (currentLoadedMapping != null) {
        Provider.of<MappingState>(context, listen: false).setMappings(
          'Elastic',
          currentLoadedMapping!.product,
          List.from(mappings),
        );
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
                if (currentLoadedMapping != null) {
                  Provider.of<MappingState>(context, listen: false).setMappings(
                    'Elastic',
                    currentLoadedMapping!.product,
                    List.from(mappings),
                  );
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
  void _showJsonExportDialog(dynamic mapping) {
    showDialog(
      context: context,
      builder: (context) => JsonPreviewWidget(
        jsonContent: mapping is SavedMapping
            ? const JsonEncoder.withIndent('  ').convert(mapping.toJson())
            : const JsonEncoder.withIndent('  ').convert(
                (mapping as List<SavedMapping>)
                    .map((m) => m.toJson())
                    .toList()),
        title: mapping is SavedMapping ? 'Mapping JSON' : 'All Mappings JSON',
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
      selectedAppId: currentLoadedMapping?.product ?? 'Elastic',
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
        jsonContent:
            const JsonEncoder.withIndent('  ').convert(_generateJsonPreview()),
      ),
    );
  }

  void _showExportOptions(dynamic mapping) {
    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        onExport: (format) {
          if (mapping is SavedMapping) {
            ExportService.exportMapping(mapping, format);
          } else {
            ExportService.exportMappings(mapping as List<SavedMapping>, format);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _clearJson() {
    elasticRequestController.clear();
    elasticResponseController.clear();
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

      // Get the first hit's fields to extract product type
      final firstHit = hits[0];
      final fields = firstHit['fields'] as Map<String, dynamic>;
      final productType = fields['product.type']?[0] as String? ?? 'Elastic';

      // Set the selected product in SavedMappingsState
      Provider.of<SavedMappingsState>(context, listen: false)
          .setSelectedProduct(productType);

      setState(() {
        // Store productType in configFields
        configFields['productType'] = productType;

        // Store raw samples
        final rawSamples = hits!
            .take(selectedRecordLimit)
            .map((hit) => Map<String, dynamic>.from(hit['fields']))
            .toList();

        // Use only the fields object for mapping, not the Elasticsearch metadata
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
                return tokens.any((token) =>
                    token['field'] != null &&
                    !newRcFields.contains(token['field']));
              } catch (e) {
                return true; // Remove if tokens can't be parsed
              }
            }
            return true; // Remove if no tokens
          }
          // For simple mappings, check if the source field exists
          return !newRcFields.contains(mapping['source']);
        });

        rcFields = newRcFields;
        rcEvents = rawSamples;

        // Auto-map fields based on exact matches
        for (final sourceField in rcFields) {
          // Get the value from the current event
          final sourceValue = _getNestedValue(currentRcEvent, sourceField);
          if (sourceValue == null) continue;

          // Check against all fields (both standard and configuration)
          for (final saasField in saasFields) {
            final isAlreadyMapped =
                mappings.any((m) => m['target'] == saasField.name);
            if (isAlreadyMapped) continue;

            // Check for exact field name match
            final isMatching =
                sourceField.toLowerCase() == saasField.name.toLowerCase();

            if (isMatching) {
              if (saasField.category.toLowerCase() == 'configuration') {
                // For configuration fields, store in configFields
                configFields[saasField.name] = sourceValue.toString();
              } else {
                // For standard fields, add to mappings
                mappings.add({
                  'source': sourceField,
                  'target': saasField.name,
                  'isComplex': 'false',
                });
              }
              hasUnsavedChanges = true;
            }
          }
        }

        // Set the query section if available
        if (querySection != null) {
          configFields['eventFilter'] = querySection;
        }
      });

      // Clear input fields after successful parse
      elasticRequestController.clear();
      elasticResponseController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: $e')),
      );
    }
  }

  Future<void> _saveCurrentMapping() async {
    if (eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an event name'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    // Extract product type from current event
    String productType = 'Elastic';
    if (currentRcEvent.containsKey('product.type')) {
      final types = currentRcEvent['product.type'];
      if (types is List && types.isNotEmpty) {
        productType = types[0].toString();
      }
    }

    final savedMapping = SavedMapping(
      eventName: eventNameController.text,
      product: productType,
      query: '',
      mappings: mappings
          .map((m) => Map<String, String>.from({
                'source': m['source']?.toString() ?? '',
                'target': m['target']?.toString() ?? '',
                'isComplex': m['isComplex']?.toString() ?? 'false',
                'tokens': m['tokens']?.toString() ?? '[]',
                'jsonataExpr': m['jsonataExpr']?.toString() ?? '',
              }))
          .toList(),
      configFields: Map<String, dynamic>.from(configFields),
      totalFieldsMapped: mappings.length,
      requiredFieldsMapped: mappings
          .where((m) => saasFields
              .firstWhere(
                (f) => f.name == m['target'],
                orElse: () => SaasField(
                  name: '',
                  required: false,
                  description: '',
                  type: 'string',
                  category: 'Standard',
                  displayOrder: 999,
                ),
              )
              .required)
          .length,
      totalRequiredFields: saasFields.where((f) => f.required).length,
      rawSamples: List<Map<String, dynamic>>.from(rcEvents),
      createdAt: now,
      modifiedAt: now,
    );

    try {
      Provider.of<SavedMappingsState>(context, listen: false)
          .createMapping(savedMapping);

      // Set as current loaded mapping after successful save
      setState(() {
        currentLoadedMapping = savedMapping;
        hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mapping saved successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mapping: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      rethrow;
    }
  }

  void _saveMapping() {
    if (currentLoadedMapping == null) return;

    if (eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an event name'),
        ),
      );
      return;
    }

    // Create updated mapping
    final updatedMapping = currentLoadedMapping!.copyWith(
      eventName: eventNameController.text,
      mappings: mappings
          .map((m) => Map<String, String>.from({
                'source': m['source']?.toString() ?? '',
                'target': m['target']?.toString() ?? '',
                'isComplex': m['isComplex']?.toString() ?? 'false',
                'tokens': m['tokens']?.toString() ?? '[]',
                'jsonataExpr': m['jsonataExpr']?.toString() ?? '',
              }))
          .toList(),
      configFields: Map<String, dynamic>.from(configFields),
      totalFieldsMapped: mappings.length,
      requiredFieldsMapped: mappings
          .where((m) => saasFields
              .firstWhere(
                (f) => f.name == m['target'],
                orElse: () => SaasField(
                  name: '',
                  required: false,
                  description: '',
                  type: 'string',
                  category: 'Standard',
                  displayOrder: 999,
                ),
              )
              .required)
          .length,
      modifiedAt: DateTime.now(),
    );

    // Update the mapping in SavedMappingsState
    final state = Provider.of<SavedMappingsState>(context, listen: false);
    if (state.selectedProduct != null) {
      state.updateMapping(state.selectedProduct!,
          currentLoadedMapping!.eventName, updatedMapping);

      setState(() {
        // Update the current loaded mapping reference
        currentLoadedMapping = updatedMapping;
        hasUnsavedChanges = false;
      });

      // Update MappingState
      Provider.of<MappingState>(context, listen: false)
          .setMappings('Elastic', updatedMapping.product, List.from(mappings));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mapping updated successfully'),
        ),
      );
    }
  }

  void _handleLoadMapping(SavedMapping mappingToLoad) {
    // If there are unsaved changes, show confirmation dialog
    if (hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Would you like to save them before loading the selected mapping?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await _saveCurrentMapping(); // Wait for save to complete
                  _loadSelectedMapping(
                      mappingToLoad); // Then load the selected mapping
                } catch (e) {
                  // Save failed, don't load the new mapping
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _loadSelectedMapping(mappingToLoad); // Load without saving
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      _loadSelectedMapping(mappingToLoad);
    }
  }

  void _loadSelectedMapping(SavedMapping mapping) {
    setState(() {
      mappings.clear();
      mappings.addAll(mapping.mappings);
      eventNameController.text = mapping.eventName;
      currentLoadedMapping = mapping;
      hasUnsavedChanges = false;

      // Load raw samples into rcEvents and extract fields
      rcEvents = List<Map<String, dynamic>>.from(mapping.rawSamples);
      if (rcEvents.isNotEmpty) {
        currentRcEvent = Map<String, dynamic>.from(rcEvents.first);
        rcFields = _getAllNestedFields([currentRcEvent]);
      }

      // Update state provider
      Provider.of<MappingState>(context, listen: false)
          .setMappings('Elastic', mapping.product, List.from(mappings));

      // Also load configuration fields
      configFields.clear();
      configFields.addAll(Map<String, String>.from(mapping.configFields));
    });
  }

  // Helper function for compute
  static dynamic jsonTryParse(String text) {
    return json.decode(text);
  }

  // Add this method to show mapping config
  void _showMappingConfig(SavedMapping mapping) {
    showDialog(
      context: context,
      builder: (context) => JsonPreviewWidget(
        jsonContent: const JsonEncoder.withIndent('  ')
            .convert(mapping.toMappingConfig()),
        title: 'Mapping Configuration',
      ),
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
            Icon(Icons.flight_takeoff, size: 24),
            SizedBox(width: 8),
            Text('Maverick Mapper'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElasticInputSection(
                    requestController: elasticRequestController,
                    responseController: elasticResponseController,
                    eventNameController: eventNameController,
                    selectedRecordLimit: selectedRecordLimit,
                    recordLimits: recordLimits,
                    onClear: _clearJson,
                    onParse: _confirmAndParseJson,
                    onRecordLimitChanged: (value) {
                      setState(() {
                        selectedRecordLimit = value;
                      });
                    },
                    hasUnsavedChanges: hasUnsavedChanges,
                    canParse: canParse,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SavedMappingsSection(
                    onViewJson: (mapping) => _showJsonExportDialog(mapping),
                    onExport: (mapping) => _showExportOptions(mapping),
                    onViewAllJson: () {
                      final state = Provider.of<SavedMappingsState>(context,
                          listen: false);
                      if (state.selectedProduct != null) {
                        final mappings =
                            state.getMappings(state.selectedProduct!);
                        _showJsonExportDialog(mappings);
                      }
                    },
                    onExportAll: () {
                      final state = Provider.of<SavedMappingsState>(context,
                          listen: false);
                      if (state.selectedProduct != null) {
                        final mappings =
                            state.getMappings(state.selectedProduct!);
                        _showExportOptions(mappings);
                      }
                    },
                    onLoadMapping: _handleLoadMapping,
                    onDuplicateMapping: (mapping) {
                      final state = Provider.of<SavedMappingsState>(context,
                          listen: false);
                      if (state.selectedProduct != null) {
                        state.duplicateMapping(
                            state.selectedProduct!, mapping.eventName);
                      }
                    },
                    onDeleteMapping: (name) {
                      final state = Provider.of<SavedMappingsState>(context,
                          listen: false);
                      if (state.selectedProduct != null) {
                        state.deleteMapping(state.selectedProduct!, name);
                      }
                    },
                    onViewConfig: _showMappingConfig,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                'Event Fields',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.info_outline, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'These fields are used to map the RAW event data to the PROCESSED event data',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star,
                                  size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              const Text(
                                'are required',
                                style: TextStyle(fontSize: 12),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (hasUnsavedChanges &&
                                        currentLoadedMapping != null)
                                      TextButton.icon(
                                        icon: const Icon(Icons.save, size: 20),
                                        label: const Text('Save'),
                                        onPressed: _saveMapping,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                      ),
                                    if (hasUnsavedChanges)
                                      const SizedBox(width: 4),
                                    TextButton.icon(
                                      icon: const Icon(Icons.save_as, size: 20),
                                      label: const Text('Save As'),
                                      onPressed: _saveCurrentMapping,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLoadingSaasFields)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else if (standardFields.isEmpty)
                          const Center(
                            child: Text('No fields available'),
                          )
                        else
                          Expanded(
                            child: MappingTableSection(
                              sourceFields: rcFields,
                              saasFields: saasFields,
                              currentEvent: currentRcEvent,
                              mappings: mappings,
                              onAddMapping: _addMapping,
                              onRemoveMapping: _removeMapping,
                              sourceSearchController: sourceSearchController,
                              saasSearchController: saasSearchController,
                              horizontalController: _horizontalController,
                              rcEvents: rcEvents,
                              onShowComplexEditor: _showComplexMappingEditor,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const Divider(),
          rcEvents.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    ConfigurationFieldsWidget(
                      configFields: configFields,
                      onConfigFieldChanged: _handleConfigFieldChange,
                      configurationFields: configurationFieldsForWidget,
                    ),
                    const Divider(),
                  ],
                ),
        ],
      ),
    );
  }
}
