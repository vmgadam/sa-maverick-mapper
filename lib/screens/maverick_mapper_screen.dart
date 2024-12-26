// MaverickMapperScreen: A Flutter widget that provides a drag-and-drop interface for mapping
// fields between RocketCyber events and SaaS Alerts configuration. The screen is divided into
// three panels: source fields, mappings, and target fields.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'dart:html' as html;

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
    setState(() {
      // Remove any existing mapping for the target field
      mappings.removeWhere((m) => m['target'] == targetField);

      final mapping = {
        'source': sourceField,
        'target': targetField,
        'isComplex': isComplex.toString(),
      };

      mappings.add(mapping);

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
        // Keep the source field when showing complex editor
        _showComplexMappingEditor(field);
      }
    });
  }

  void _removeMapping(int index) {
    setState(() {
      mappings.removeAt(index);
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
        return data != null && data['isSource'] == true && !isMapped;
      },
      onAccept: (data) {
        _addMapping(data['field'], field.name, isComplex);
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

    // Initialize the tokens list from stored JSON
    if (!mapping.containsKey('tokens')) {
      mapping['tokens'] = '[]';
    }
    // Parse stored tokens into a list of maps
    List<Map<String, String>> tokens = List<Map<String, String>>.from(json
        .decode(mapping['tokens']!)
        .map((t) => Map<String, String>.from(t)));

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
          String text =
              token['value']!.substring(1, token['value']!.length - 1);
          parts.add("'$text'");
        }
      }
      return parts.join('');
    }

    /// Evaluates the current expression using sample data.
    /// Replaces field references with actual values from the current event.
    String evaluateExpression() {
      try {
        return tokens
            .where((token) => token['type'] != 'operator')
            .map((token) {
          if (token['type'] == 'field') {
            final fieldPath = token['value']!.substring(1); // Remove $ prefix
            return _getNestedValue(currentRcEvent, fieldPath)?.toString() ?? '';
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

    // Store the original tokens state for cancellation
    final originalTokens = List<Map<String, String>>.from(tokens);

    // Show the complex mapping editor dialog
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Complex Mapping for ${field.name}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                // List of draggable source fields
                                Expanded(
                                  child: ListView(
                                    children: rcFields.map((field) {
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
                                        childWhenDragging:
                                            const SizedBox.shrink(),
                                        child: Card(
                                          child: ListTile(
                                            dense: true,
                                            title: Text('\$${field}'),
                                            subtitle: Text(
                                              _getNestedValue(
                                                          currentRcEvent, field)
                                                      ?.toString() ??
                                                  '',
                                              style:
                                                  const TextStyle(fontSize: 10),
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
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
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
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        'Enter text to add to the expression',
                                                    border:
                                                        OutlineInputBorder(),
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
                                                        setDialogState(() {
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
                                            setDialogState(() {
                                              tokens.add({
                                                'type': 'text',
                                                'value': '" "'
                                              });
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () => setDialogState(
                                              () => tokens.clear()),
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
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        // Display tokens as draggable chips
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (var i = 0;
                                                i < tokens.length;
                                                i++) ...[
                                              Draggable<Map<String, dynamic>>(
                                                data: {
                                                  'index': i,
                                                  'token': tokens[i]
                                                },
                                                feedback: Material(
                                                  elevation: 4,
                                                  child: Chip(
                                                    label: Text(
                                                        tokens[i]['value']!),
                                                    backgroundColor: tokens[i]
                                                                ['type'] ==
                                                            'field'
                                                        ? Colors.blue.shade100
                                                        : Colors.green.shade100,
                                                  ),
                                                ),
                                                childWhenDragging: Opacity(
                                                  opacity: 0.5,
                                                  child: Chip(
                                                    label: Text(
                                                        tokens[i]['value']!),
                                                    backgroundColor: tokens[i]
                                                                ['type'] ==
                                                            'field'
                                                        ? Colors.blue.shade100
                                                        : Colors.green.shade100,
                                                  ),
                                                ),
                                                // Make each token a drop target for reordering
                                                child: DragTarget<
                                                    Map<String, dynamic>>(
                                                  onWillAccept: (data) =>
                                                      data != null &&
                                                      data['index'] != i,
                                                  onAccept: (data) {
                                                    setDialogState(() {
                                                      final fromIndex =
                                                          data['index'] as int;
                                                      final toIndex = i;

                                                      // Handle token reordering
                                                      if (fromIndex < toIndex) {
                                                        final itemToMove =
                                                            tokens[fromIndex];
                                                        tokens.removeAt(
                                                            fromIndex);
                                                        tokens.insert(
                                                            toIndex - 1,
                                                            itemToMove);
                                                      } else {
                                                        final itemToMove =
                                                            tokens[fromIndex];
                                                        tokens.removeAt(
                                                            fromIndex);
                                                        tokens.insert(toIndex,
                                                            itemToMove);
                                                      }
                                                    });
                                                  },
                                                  builder: (context,
                                                      candidateData,
                                                      rejectedData) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        border: candidateData
                                                                .isNotEmpty
                                                            ? Border.all(
                                                                color:
                                                                    Colors.blue,
                                                                width: 2)
                                                            : null,
                                                      ),
                                                      child: Chip(
                                                        label: Text(tokens[i]
                                                            ['value']!),
                                                        backgroundColor:
                                                            tokens[i]['type'] ==
                                                                    'field'
                                                                ? Colors.blue
                                                                    .shade100
                                                                : Colors.green
                                                                    .shade100,
                                                        deleteIcon: const Icon(
                                                            Icons.close,
                                                            size: 16),
                                                        onDeleted: () =>
                                                            setDialogState(() {
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                              setDialogState(() {
                                tokens.add(data);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Restore original state on cancel
                tokens = originalTokens;
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tokens.isNotEmpty) {
                  final expression = buildExpression();
                  Navigator.pop(dialogContext);

                  // Update the parent widget's state
                  setState(() {
                    if (mappings.any((m) => m['target'] == field.name)) {
                      // Update existing mapping
                      final existingMapping =
                          mappings.firstWhere((m) => m['target'] == field.name);
                      existingMapping['jsonataExpr'] = expression;
                      existingMapping['tokens'] = json.encode(tokens);
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
                        'tokens': json.encode(tokens),
                      });
                    }
                    hasUnsavedChanges = true;
                  });
                } else {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsCSV() {
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

    final csvContent = csvRows.join('\n');
    _downloadFile(csvContent, 'maverick_mapper_export.csv', 'text/csv');
  }

  void _exportAsJSON() {
    final jsonData = _generateJsonPreview();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // Create a Blob containing the JSON data
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);

    // Create a download URL and trigger the download
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'mappingConfig.json')
      ..click();

    // Clean up
    html.Url.revokeObjectUrl(url);
  }

  void _downloadFile(String content, String filename, String mimeType) {
    // Create a Blob containing the data
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create a link element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    html.document.body!.children.add(anchor);
    anchor.click();

    // Clean up
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.code, size: 16),
            const SizedBox(width: 8),
            Text(
              'JSON Preview',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (mappings.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _exportAsJSON,
                tooltip: 'Export JSON',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ')
                  .convert(_generateJsonPreview()),
            ),
          ),
        ),
      ],
    );
  }

  // Configuration section widget
  Widget _buildConfigSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Fields',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Product Reference',
                    hintText: 'products/default',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(
                    text: configFields['productRef'],
                  ),
                  onChanged: (value) {
                    setState(() {
                      configFields['productRef'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Endpoint ID',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(
                    text: configFields['endpointId'],
                  ),
                  onChanged: (value) {
                    setState(() {
                      configFields['endpointId'] = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Event Type with dropdown and custom input
          Row(
            children: [
              Expanded(
                child: isCustomEventType
                    ? TextField(
                        decoration: const InputDecoration(
                          labelText: 'Custom Event Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        controller: eventTypeController,
                        onChanged: (value) {
                          setState(() {
                            configFields['eventType'] = value;
                          });
                        },
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Event Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        value: eventTypes.contains(configFields['eventType'])
                            ? configFields['eventType']
                            : eventTypes.first,
                        items: [
                          ...eventTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }),
                          const DropdownMenuItem<String>(
                            value: 'CUSTOM',
                            child: Text('CUSTOM'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            if (value == 'CUSTOM') {
                              isCustomEventType = true;
                              eventTypeController.text = '';
                              configFields['eventType'] = '';
                            } else if (value != null) {
                              isCustomEventType = false;
                              configFields['eventType'] = value;
                              eventTypeController.text = value;
                            }
                          });
                        },
                      ),
              ),
              if (isCustomEventType)
                IconButton(
                  icon: const Icon(Icons.list),
                  tooltip: 'Show predefined types',
                  onPressed: () {
                    setState(() {
                      isCustomEventType = false;
                      configFields['eventType'] = eventTypes.first;
                      eventTypeController.text = eventTypes.first;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.paste),
            onPressed: () {
              setState(() {
                showJsonInput = true;
              });
            },
            tooltip: 'Paste JSON',
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
                    child: Text(
                      'Mappings',
                      style: Theme.of(context).textTheme.titleMedium,
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
