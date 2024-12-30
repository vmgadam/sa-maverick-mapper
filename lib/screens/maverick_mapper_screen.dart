// MaverickMapperScreen: A Flutter widget that provides a drag-and-drop interface for mapping
// fields between RocketCyber events and SaaS Alerts configuration. The screen is divided into
// three panels: source fields, mappings, and target fields.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'events_display_screen.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';
import '../widgets/complex_mapping_editor.dart';
import '../widgets/json_preview_widget.dart';
import '../widgets/configuration_fields_widget.dart';

/// SaasField: Represents a field in the SaaS Alerts configuration.
/// Each field has a name, required status, description, type, and optional condition.
class SaasField {
  final String name; // Field identifier
  final bool required; // Whether the field is mandatory
  final String description; // Human-readable field description
  final String type; // Data type (e.g., 'string', 'number')
  final String? condition; // Optional condition for field validation
  final String defaultMode; // 'simple' or 'complex'

  SaasField({
    required this.name,
    required this.required,
    required this.description,
    required this.type,
    this.condition,
    this.defaultMode = 'simple',
  });

  /// Creates a SaasField from JSON data, with the field name provided separately
  /// since it's used as the key in the fields.json file.
  factory SaasField.fromJson(String name, Map<String, dynamic> json) {
    return SaasField(
      name: name,
      required: json['required'] ?? false,
      description: json['description'] ?? '',
      type: json['type'] ?? 'string',
      condition: json['condition'],
      defaultMode: json['defaultMode'] ?? 'simple',
    );
  }
}

/// MaverickMapperScreen: Main widget for the field mapping interface.
/// Requires API services for both RocketCyber and SaaS Alerts.
class MaverickMapperScreen extends StatefulWidget {
  final ApiService apiService;
  final SaasAlertsApiService saasAlertsApi;

  const MaverickMapperScreen({
    super.key,
    required this.apiService,
    required this.saasAlertsApi,
  });

  @override
  State<MaverickMapperScreen> createState() => _MaverickMapperScreenState();
}

class _MaverickMapperScreenState extends State<MaverickMapperScreen> {
  // Source data state management
  final List<dynamic> rcApps = []; // Available RocketCyber apps
  String? selectedRcAppId; // Currently selected app
  Map<String, dynamic> currentRcEvent = {}; // Current event data
  List<String> rcFields = []; // Available fields from event
  bool isLoadingRcApps = true; // Loading state for apps
  bool isLoadingRcEvents = false; // Loading state for events

  // SaaS Alerts fields state management
  List<SaasField> saasFields = []; // Available SaaS Alert fields
  bool isLoadingSaasFields = true; // Loading state for fields
  String? selectedSaasField; // Currently selected SaaS field

  // Mapping state management
  final List<Map<String, String>> mappings = []; // Current field mappings
  bool hasUnsavedChanges = false; // Track unsaved changes
  final TextEditingController jsonInputController = TextEditingController();
  bool showJsonInput = false; // JSON input visibility

  // Configuration fields state
  final Map<String, String> configFields = {
    'productRef': 'products/default',
    'endpointId': '0',
    'eventType': 'EVENT',
  };

  // Event types state
  List<String> eventTypes = [];
  bool isCustomEventType = false;
  final TextEditingController eventTypeController =
      TextEditingController(text: 'EVENT');

  // Search functionality
  final TextEditingController sourceSearchController = TextEditingController();
  final TextEditingController saasSearchController = TextEditingController();
  String sourceSearchQuery = ''; // Current source search term
  String saasSearchQuery = ''; // Current SaaS search term

  @override
  void initState() {
    super.initState();
    _loadRcApps();
    _loadSaasFields();
    _loadEventTypes();
  }

  @override
  void dispose() {
    sourceSearchController.dispose();
    saasSearchController.dispose();
    super.dispose();
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
            // Sort by required status first (required fields come first)
            if (a.required != b.required) {
              return a.required ? -1 : 1;
            }
            // Then sort alphabetically by name
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

  Future<void> _loadRcEvents(String appId) async {
    setState(() {
      isLoadingRcEvents = true;
      selectedRcAppId = appId;
    });

    try {
      final eventsData = await widget.apiService.getEvents(appId, pageSize: 10);
      if (eventsData != null && eventsData['data'] != null) {
        final events = eventsData['data'] as List;
        if (events.isNotEmpty) {
          setState(() {
            currentRcEvent = Map<String, dynamic>.from(events.first);
            rcFields = _getAllNestedFields([currentRcEvent]);
          });

          // Update selected app in state
          final appInfo = rcApps.firstWhere(
            (app) => app['id'].toString() == appId,
            orElse: () => {'name': 'Unknown App'},
          );
          Provider.of<MappingState>(context, listen: false)
              .setSelectedApp(appId, appInfo['name']);

          // Load existing mappings from state
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

  Future<void> _loadEventTypes() async {
    try {
      debugPrint('Loading event types...');
      final String jsonString =
          await rootBundle.loadString('config/event_types.json');
      debugPrint('Loaded JSON string: $jsonString');
      final jsonData = json.decode(jsonString);
      debugPrint('Parsed JSON data: $jsonData');
      setState(() {
        eventTypes = List<String>.from(jsonData['eventTypes']);
        debugPrint('Set event types: $eventTypes');
        // Set initial value if not already set
        if (!configFields.containsKey('eventType') ||
            configFields['eventType']!.isEmpty) {
          configFields['eventType'] = 'LOGIN_SUCCESS';
        }
        eventTypeController.text = configFields['eventType'] ?? 'LOGIN_SUCCESS';
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading event types: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        eventTypes = ['LOGIN_SUCCESS'];
        configFields['eventType'] = 'LOGIN_SUCCESS';
        eventTypeController.text = 'LOGIN_SUCCESS';
      });
    }
  }

  // Get source field usage count
  Map<String, int> get sourceFieldUsage {
    final usage = <String, int>{};
    for (final mapping in mappings) {
      final sourceField = mapping['source']!;
      usage[sourceField] = (usage[sourceField] ?? 0) + 1;
    }
    return usage;
  }

  // Get unmapped SaaS fields
  List<SaasField> get unmappedSaasFields {
    return saasFields.where((field) {
      return !mappings.any((m) => m['target'] == field.name);
    }).toList();
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

  void _addMapping(String sourceField, String targetField, bool isComplex) {
    if (sourceField.isEmpty || targetField.isEmpty) {
      debugPrint('Invalid mapping: source or target field is empty');
      return;
    }

    setState(() {
      // Remove any existing mapping for the target field
      mappings.removeWhere((m) => m['target'] == targetField);

      final mapping = {
        'source': sourceField,
        'target': targetField,
        'isComplex': isComplex.toString(),
        'jsonataExpr': '', // Initialize with empty string for complex mappings
        'tokens': '[]', // Initialize with empty array for complex mappings
      };

      mappings.add(mapping);
      hasUnsavedChanges = true;

      // Update state
      if (selectedRcAppId != null) {
        final appInfo = rcApps.firstWhere(
          (app) => app['id'].toString() == selectedRcAppId,
          orElse: () => {'name': 'Unknown App', 'id': selectedRcAppId},
        );

        Provider.of<MappingState>(context, listen: false).setMappings(
            selectedRcAppId!,
            appInfo['name'] ?? 'Unknown App',
            List.from(mappings));
      }

      if (isComplex) {
        final field = saasFields.firstWhere(
          (f) => f.name == targetField,
          orElse: () => SaasField(
            name: targetField,
            required: false,
            description: '',
            type: 'string',
          ),
        );
        _showComplexMappingEditor(field);
      }
    });
  }

  Future<void> _saveMappings() async {
    if (selectedRcAppId == null) return;

    try {
      final appInfo = rcApps.firstWhere(
        (app) => app['id'].toString() == selectedRcAppId,
        orElse: () => {'name': 'Unknown App'},
      );

      // Update state
      Provider.of<MappingState>(context, listen: false)
          .setMappings(selectedRcAppId!, appInfo['name'], List.from(mappings));

      setState(() {
        hasUnsavedChanges = false;
      });
    } catch (e) {
      debugPrint('Error saving mappings: $e');
    }
  }

  void _removeMapping(int index) {
    setState(() {
      mappings.removeAt(index);
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

  void _handleJsonInput() {
    try {
      final jsonData = json.decode(jsonInputController.text);
      setState(() {
        currentRcEvent = Map<String, dynamic>.from(jsonData);
        rcFields = _getAllNestedFields([currentRcEvent]);
        showJsonInput = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: $e')),
      );
    }
  }

  // Filter source fields based on search
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

  // Filter SaaS fields based on search
  List<SaasField> get filteredSaasFields {
    if (saasSearchQuery.isEmpty) return unmappedSaasFields;
    return unmappedSaasFields.where((field) {
      return field.name.toLowerCase().contains(saasSearchQuery.toLowerCase()) ||
          field.description
              .toLowerCase()
              .contains(saasSearchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildDraggableField(String field, bool isSource) {
    if (field.isEmpty) {
      debugPrint('Invalid field: empty field name');
      return const SizedBox.shrink();
    }

    final usageCount = sourceFieldUsage[field] ?? 0;
    final isUsed = usageCount > 0;
    final value = _getNestedValue(currentRcEvent, field)?.toString() ?? '';

    return Draggable<Map<String, dynamic>>(
      data: {
        'field': field,
        'isSource': isSource,
      },
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blue.withOpacity(0.8),
          child: Text(
            field,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.grey.withOpacity(0.3),
        ),
        child: Text(field),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: isUsed ? Colors.green.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(field)),
                if (usageCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$usageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropTarget(SaasField field) {
    if (field.name.isEmpty) {
      debugPrint('Invalid SaaS field: empty field name');
      return const SizedBox.shrink();
    }

    final isMapped = mappings.any((m) => m['target'] == field.name);
    final isComplex = field.defaultMode == 'complex';

    return DragTarget<Map<String, dynamic>>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Colors.blue
                  : field.required
                      ? Colors.red
                      : Colors.grey,
            ),
            color: candidateData.isNotEmpty
                ? Colors.blue.withOpacity(0.1)
                : isMapped
                    ? Colors.green.withOpacity(0.1)
                    : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (field.required)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.star, size: 16, color: Colors.red),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(field.name),
                        if (field.description.isNotEmpty)
                          Text(
                            field.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  // Mode toggle button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeToggleButton(
                          !isComplex,
                          'Simple',
                          Icons.arrow_forward,
                          () {
                            if (!isMapped) {
                              setState(() {
                                selectedSaasField = field.name;
                              });
                            }
                          },
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                        _buildModeToggleButton(
                          isComplex,
                          'Complex',
                          Icons.code,
                          () {
                            if (!isMapped) {
                              _showComplexMappingEditor(field);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      onWillAccept: (data) {
        return data != null &&
            data['isSource'] == true &&
            data['field'] != null &&
            !isMapped;
      },
      onAccept: (data) {
        if (data['field'] != null) {
          _addMapping(data['field'], field.name, isComplex);
        }
      },
    );
  }

  Widget _buildModeToggleButton(
    bool isSelected,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: isSelected ? Colors.blue.shade50 : Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.blue : null,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the complex mapping editor dialog for creating and editing JSONata expressions.
  /// This editor provides a visual interface for building expressions using drag-and-drop
  /// and supports both field references and text literals.
  ///
  /// @param field The SaaS Alerts field being mapped
  void _showComplexMappingEditor(SaasField field) {
    // Initialize or retrieve the existing mapping for this field
    var mapping = mappings.firstWhere(
      (m) => m['target'] == field.name,
      orElse: () => {
        'source': '',
        'target': field.name,
        'isComplex': 'true',
        'jsonataExpr': '',
        'tokens': '[]', // Store tokens as JSON string for persistence
      },
    );

    // Parse stored tokens into a list of maps
    List<Map<String, String>> tokens = List<Map<String, String>>.from(json
        .decode(mapping['tokens']!)
        .map((t) => Map<String, String>.from(t)));

    // Store the original tokens state for cancellation
    final originalTokens = List<Map<String, String>>.from(tokens);

    // Show the complex mapping editor dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Complex Mapping for ${field.name}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ComplexMappingEditor(
            sourceFields: rcFields,
            currentEvent: currentRcEvent,
            initialTokens: tokens,
            onSave: (expression, updatedTokens) {
              setState(() {
                if (mappings.any((m) => m['target'] == field.name)) {
                  // Update existing mapping
                  final existingMapping =
                      mappings.firstWhere((m) => m['target'] == field.name);
                  existingMapping['jsonataExpr'] = expression;
                  existingMapping['tokens'] = json.encode(updatedTokens);
                  existingMapping['isComplex'] = 'true';
                  existingMapping['source'] =
                      ''; // Ensure source is empty for complex mappings
                } else {
                  // Add new mapping
                  mappings.add({
                    'source': '',
                    'target': field.name,
                    'isComplex': 'true',
                    'jsonataExpr': expression,
                    'tokens': json.encode(updatedTokens),
                  });
                }
                hasUnsavedChanges = true;
              });
            },
          ),
        ),
      ),
    );
  }

  void _exportAsCSV() {
    final csvContent = _generateCSVContent();

    // Show the CSV in a dialog instead of downloading
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Export'),
        content: SingleChildScrollView(
          child: SelectableText(csvContent),
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

  void _exportAsJSON() {
    final jsonData = _generateJsonPreview();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // Show the JSON in a dialog instead of downloading
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Export'),
        content: SingleChildScrollView(
          child: SelectableText(jsonString),
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Mappings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV Format'),
              subtitle: const Text('Export as spreadsheet-compatible CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportAsCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON Format'),
              subtitle: const Text('Export as structured JSON with metadata'),
              onTap: () {
                Navigator.pop(context);
                _exportAsJSON();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleMappingMode(Map<String, String> mapping) {
    final field = saasFields.firstWhere(
      (f) => f.name == mapping['target'],
      orElse: () => SaasField(
        name: mapping['target']!,
        required: false,
        description: '',
        type: 'string',
      ),
    );

    if (mapping['isComplex'] == 'true') {
      // Switch to simple mode
      setState(() {
        mapping['isComplex'] = 'false';
        mapping.remove('jsonataExpr');
        mapping['source'] =
            mapping['source'] ?? ''; // Ensure source is not null
      });
    } else {
      // Switch to complex mode
      setState(() {
        mapping['isComplex'] = 'true';
        mapping['source'] =
            mapping['source'] ?? ''; // Ensure source is not null
      });
      _showComplexMappingEditor(field);
    }
  }

  Widget _buildMappingRow(Map<String, String> mapping) {
    final targetField = saasFields.firstWhere(
      (f) => f.name == mapping['target'],
      orElse: () => SaasField(
        name: mapping['target']!,
        required: false,
        description: '',
        type: 'string',
      ),
    );

    final isComplex = mapping['isComplex'] == 'true';

    return Card(
      child: ListTile(
        title: Text(isComplex
            ? '[Complex Expression] → ${mapping['target']}'
            : '${mapping['source']} → ${mapping['target']}'),
        subtitle: Text(targetField.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isComplex)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showComplexMappingEditor(targetField),
                tooltip: 'Edit JSONata Expression',
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeMapping(mappings.indexOf(mapping)),
              tooltip: 'Remove Mapping',
            ),
          ],
        ),
      ),
    );
  }

  // Generate JSON preview
  Map<String, dynamic> _generateJsonPreview() {
    final mappingSchema = <String, dynamic>{};
    for (var mapping in mappings) {
      if (mapping['isComplex'] == 'true') {
        // For complex mappings, store the expression directly without wrapping in an object
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

  // Update preview widget to use the generated JSON
  Widget _buildJsonPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: JsonPreviewWidget(
        jsonData: _generateJsonPreview(),
        onExport: mappings.isNotEmpty ? _exportAsJSON : null,
      ),
    );
  }

  // Configuration section widget
  Widget _buildConfigSection() {
    return ConfigurationFieldsWidget(
      configFields: configFields,
      eventTypes: eventTypes,
      eventTypeController: eventTypeController,
      onConfigFieldChanged: (key, value) {
        setState(() {
          configFields[key] = value;
        });
      },
    );
  }

  String _generateCSVContent() {
    final csvRows = <String>[];

    // Add header row
    csvRows.add(
        '"Source App","Source Field","Source Sample Data","Source Record ID",' +
            '"SaaS Alerts Field","SaaS Alerts Sample Data","SaaS Alerts Record ID"');

    // Add data rows
    for (final mapping in mappings) {
      final sourceField = mapping['source']!;
      final targetField = mapping['target']!;
      final sourceValue = _getNestedValue(currentRcEvent, sourceField);
      final appName = rcApps.firstWhere(
        (app) => app['id'].toString() == selectedRcAppId,
        orElse: () => {'name': 'Unknown App'},
      )['name'];

      csvRows.add(
        '"$appName","$sourceField","$sourceValue","${currentRcEvent['id'] ?? ''}",' +
            '"$targetField","","${currentRcEvent['id'] ?? ''}"',
      );
    }

    return csvRows.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final sortedMappings = List<Map<String, String>>.from(mappings)
      ..sort((a, b) => (a['target'] ?? '').compareTo(b['target'] ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maverick Mapper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: selectedRcAppId == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventsDisplayScreen(
                          apiService: widget.apiService,
                          saasAlertsApi: widget.saasAlertsApi,
                          selectedAppId: selectedRcAppId,
                        ),
                      ),
                    );

                    if (result != null && result['mappingsUpdated'] == true) {
                      // Reload mappings from state
                      final mappingState =
                          Provider.of<MappingState>(context, listen: false);
                      final updatedMappings =
                          mappingState.getMappings(selectedRcAppId!);
                      setState(() {
                        mappings.clear();
                        mappings.addAll(updatedMappings);
                        hasUnsavedChanges = false;
                      });
                    }
                  },
            tooltip: 'View Mapped Events',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Source Fields
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Source Fields',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!showJsonInput) ...[
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
                          if (value != null) {
                            _loadRcEvents(value);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: sourceSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search fields or values...',
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
                  ],
                  if (showJsonInput)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: jsonInputController,
                            maxLines: 10,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Paste JSON here',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _handleJsonInput,
                            child: const Text('Parse JSON'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredSourceFields.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _buildDraggableField(
                              filteredSourceFields[index], true),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Center panel - Mappings
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          'Mappings',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Current Mappings JSON'),
                                content: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: JsonPreviewWidget(
                                    jsonData: _generateJsonPreview(),
                                    onExport: mappings.isNotEmpty
                                        ? _exportAsJSON
                                        : null,
                                    showExportButton: true,
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
                          },
                          tooltip: 'View JSON',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: sortedMappings.length,
                            itemBuilder: (context, index) {
                              return _buildMappingRow(sortedMappings[index]);
                            },
                          ),
                        ),
                        if (mappings.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.table_chart),
                              label: const Text('Export as CSV'),
                              onPressed: _exportAsCSV,
                            ),
                          ),
                        const Divider(),
                        // Configuration section for special fields
                        _buildConfigSection(),
                        const Divider(),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _buildJsonPreview(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right panel - SaaS Alerts Fields
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SaaS Alerts Fields',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Tooltip(
                          message: 'Required fields are marked with a star',
                          child: Row(
                            children: const [
                              Icon(Icons.star, size: 16, color: Colors.red),
                              SizedBox(width: 4),
                              Text('Required'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: saasSearchController,
                      decoration: const InputDecoration(
                        hintText: 'Search fields or descriptions...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          saasSearchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredSaasFields.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _buildDropTarget(filteredSaasFields[index]),
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
    );
  }
}
