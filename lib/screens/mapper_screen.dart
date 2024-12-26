import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:developer' as developer;
import 'dart:math';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';

class MapperScreen extends StatefulWidget {
  final ApiService apiService;
  final SaasAlertsApiService saasAlertsApi;
  final Function() onViewEvents;

  const MapperScreen({
    super.key,
    required this.apiService,
    required this.saasAlertsApi,
    required this.onViewEvents,
  });

  @override
  State<MapperScreen> createState() => _MapperScreenState();
}

class _MapperScreenState extends State<MapperScreen> {
  final List<dynamic> rcApps = [];
  final List<String> saasProducts = [];
  String? selectedRcAppId;
  String? selectedSaasProduct;
  String? selectedRcField;
  String? selectedSaasField;
  final List<Map<String, String>> mappings = [];
  List<Map<String, String>> savedMappings = [];
  bool hasUnsavedChanges = false;
  Map<String, dynamic> fieldsConfig = {};
  String rcSearchQuery = '';
  String saasSearchQuery = '';
  Map<String, dynamic> currentRcEvent = {};
  Map<String, dynamic> currentSaasEvent = {};
  bool isLoadingRcApps = true;
  bool isLoadingSaasProducts = true;
  bool isLoadingRcEvents = false;
  bool isLoadingSaasEvents = false;
  List<String> rcColumns = [];
  List<String> saasColumns = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadFieldsConfig();
    _initializeData();
  }

  Future<void> _loadFieldsConfig() async {
    try {
      final jsonString = await rootBundle.loadString('lib/config/fields.json');
      setState(() {
        fieldsConfig = json.decode(jsonString)['fields'];
      });
    } catch (e) {
      developer.log('Error loading fields config', error: e);
    }
  }

  Future<void> _initializeData() async {
    _prefs = await SharedPreferences.getInstance();
    final savedAppId = _prefs.getString('selected_rc_app');
    if (savedAppId != null) {
      setState(() {
        selectedRcAppId = savedAppId;
      });
    }
    await _loadRcApps();
    await _loadSaasProducts();
  }

  Future<void> _saveMappings() async {
    if (selectedRcAppId == null) return;

    final appInfo = rcApps.firstWhere(
      (app) => app['id'].toString() == selectedRcAppId,
      orElse: () => {'name': 'Unknown App'},
    );

    final mappingData = {
      'appId': selectedRcAppId,
      'appName': appInfo['name'],
      'mappings': mappings,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(
      'mappings_${selectedRcAppId}',
      json.encode(mappingData),
    );

    setState(() {
      savedMappings = List.from(mappings);
      hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mappings saved for ${appInfo['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadMappings() async {
    if (selectedRcAppId == null) return;

    final savedData = _prefs.getString('mappings_${selectedRcAppId}');
    if (savedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved mappings found for this app'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final mappingData = json.decode(savedData);
    setState(() {
      mappings.clear();
      mappings.addAll(
        (mappingData['mappings'] as List)
            .map((m) => Map<String, String>.from(m)),
      );
      savedMappings = List.from(mappings);
      hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded mappings for ${mappingData['appName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _handleAppChange(String? newAppId) async {
    if (!hasUnsavedChanges || newAppId == selectedRcAppId) return true;

    final shouldChange = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
                'You have unsaved mappings. Do you want to continue and lose these changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldChange) {
      setState(() {
        mappings.clear();
        hasUnsavedChanges = false;
      });
      return true;
    }
    return false;
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

        // Load events and mappings for the selected app
        if (selectedRcAppId != null) {
          await _loadRcEvents(selectedRcAppId!);
          await _loadMappings();
        }
      }
    } catch (e) {
      developer.log('Error loading RC apps', error: e);
      setState(() {
        isLoadingRcApps = false;
      });
    }
  }

  Future<void> _loadSaasProducts() async {
    setState(() {
      isLoadingSaasProducts = true;
    });

    try {
      // Use predefined list of products
      setState(() {
        saasProducts.clear();
        saasProducts.addAll([
          'MS',
          'G_SUITE',
          'NINJA_ONE',
          'DATTO_RMM',
          'DATTO_EDR',
          'IT_GLUE',
        ]);
        isLoadingSaasProducts = false;
      });
    } catch (e) {
      developer.log('Error loading SaaS products', error: e);
      setState(() {
        isLoadingSaasProducts = false;
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
            rcColumns = _getAllNestedColumns([currentRcEvent]);
          });
        }
      }
    } catch (e) {
      developer.log('Error loading RC events', error: e);
    } finally {
      setState(() {
        isLoadingRcEvents = false;
      });
    }
  }

  Future<void> _loadSaasEvents(String product) async {
    setState(() {
      isLoadingSaasEvents = true;
      selectedSaasProduct = product;
      currentSaasEvent = {};
      saasColumns = [];
    });

    try {
      developer.log('Loading SaaS events for product type: $product');

      final events = await widget.saasAlertsApi.getReportEventsQuery(
        timeSort: 'desc',
        product: product,
      );

      developer.log('Received ${events.length} events from query');

      if (events.isNotEmpty) {
        developer.log('First event: ${json.encode(events.first)}');
        setState(() {
          currentSaasEvent = Map<String, dynamic>.from(events.first);
          saasColumns = _getAllNestedColumns([currentSaasEvent]);
          developer
              .log('Extracted ${saasColumns.length} columns: $saasColumns');
        });
      } else {
        developer.log('No events found for product type: $product');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('No events found for $product in the last 15 minutes'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Error loading SaaS events',
          error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading events: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingSaasEvents = false;
      });
    }
  }

  List<String> get availableRcFields {
    final mappedFields = mappings.map((m) => m['rc']!).toSet();
    return rcColumns.where((field) => !mappedFields.contains(field)).toList();
  }

  List<String> get availableSaasFields {
    final mappedFields = mappings.map((m) => m['saas']!).toSet();
    return saasColumns.where((field) => !mappedFields.contains(field)).toList();
  }

  List<String> _sortFieldsHierarchically(List<String> fields) {
    // Group fields by their top-level name
    final Map<String, List<String>> fieldGroups = {};

    for (var field in fields) {
      final topLevel = field.split('.')[0];
      fieldGroups.putIfAbsent(topLevel, () => []).add(field);
    }

    // Sort each group internally
    fieldGroups.forEach((key, value) {
      value.sort((a, b) {
        final aParts = a.split('.');
        final bParts = b.split('.');

        // Compare each level
        for (var i = 0; i < min(aParts.length, bParts.length); i++) {
          final comp = aParts[i].compareTo(bParts[i]);
          if (comp != 0) return comp;
        }

        // If all common parts are equal, shorter paths come first
        return aParts.length.compareTo(bParts.length);
      });
    });

    // Sort top-level groups alphabetically and flatten
    final sortedKeys = fieldGroups.keys.toList()..sort();
    return sortedKeys.expand((key) => fieldGroups[key]!).toList();
  }

  List<String> _getAllNestedColumns(List<dynamic> events) {
    final Set<String> columns = {};
    for (var event in events) {
      if (event is Map<String, dynamic>) {
        _addNestedColumns(event, columns);
      }
    }
    return _sortFieldsHierarchically(columns.toList());
  }

  void _addNestedColumns(Map<String, dynamic> data, Set<String> columns,
      [String prefix = '']) {
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        _addNestedColumns(
            value, columns, prefix.isEmpty ? key : '$prefix.$key');
      } else if (value is List) {
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            _addNestedColumns(
                item, columns, prefix.isEmpty ? key : '$prefix.$key');
          }
        }
      } else {
        columns.add(prefix.isEmpty ? key : '$prefix.$key');
      }
    });
  }

  String? _getFieldValue(Map<String, dynamic> data, String field) {
    final parts = field.split('.');
    dynamic value = data;
    for (final part in parts) {
      if (value is! Map<String, dynamic>) return null;
      value = value[part];
    }
    return value?.toString();
  }

  Widget _buildFieldListItem(
      String field, Map<String, dynamic> event, bool isRcField) {
    final value = _getFieldValue(event, field) ?? 'null';
    final isSelected =
        isRcField ? field == selectedRcField : field == selectedSaasField;
    final fieldConfig = fieldsConfig[field] ?? {};
    final defaultMode = fieldConfig['defaultMode'] ?? 'simple';
    final isDefaultComplex = defaultMode == 'complex';

    // Only show mode toggle for SaaS Alert fields
    if (!isRcField) {
      return Card(
        elevation: isSelected ? 2 : 0,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        color: isSelected ? Colors.blue.shade100 : null,
        child: Column(
          children: [
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              field,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (fieldConfig['required'] == true)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.star,
                                    size: 8, color: Colors.red),
                              ),
                          ],
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                          field,
                          !isDefaultComplex,
                          'Simple',
                          Icons.arrow_forward,
                          () => setState(() => selectedSaasField = field),
                          isDefaultComplex,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                        _buildModeToggleButton(
                          field,
                          isDefaultComplex,
                          'Complex',
                          Icons.code,
                          () => _showComplexMappingEditor(field),
                          isDefaultComplex,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Original drag and drop implementation for RC fields
    return Draggable<Map<String, String>>(
      data: {
        'field': field,
        'isRcField': isRcField.toString(),
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          width: 300,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  field,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Text(
                ' = ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Card(
        elevation: isSelected ? 2 : 0,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: ListTile(
          selected: isSelected,
          onTap: () {
            setState(() {
              selectedRcField = field;
            });
          },
          title: Text(
            field,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggleButton(
    String field,
    bool isSelected,
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool isDefaultMode,
  ) {
    return Material(
      color: isSelected && isDefaultMode
          ? Colors.blue.shade50
          : Colors.transparent,
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
                color: isSelected && isDefaultMode ? Colors.blue : null,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected && isDefaultMode ? Colors.blue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplexMappingEditor(String saasField) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complex Mapping for $saasField'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a JSONata expression to transform the source fields.\nAvailable fields:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Show available RC fields
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Source Fields:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: rcColumns
                        .map((field) => Chip(
                              label: Text('\$${field}',
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: r'Example: $user.firstName & " " & $user.lastName',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  mappings.add({
                    'saas': saasField,
                    'isComplex': 'true',
                    'jsonataExpr': controller.text,
                  });
                  hasUnsavedChanges = true;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(Map<String, String> mapping) {
    final rcValue = _getFieldValue(currentRcEvent, mapping['rc']!) ?? 'null';
    final saasValue =
        _getFieldValue(currentSaasEvent, mapping['saas']!) ?? 'null';
    final isComplex = mapping['isComplex'] == 'true';
    final jsonataExpr = mapping['jsonataExpr'];

    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'event.${mapping['rc']} ($rcValue)',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(isComplex ? Icons.code : Icons.arrow_forward),
                onPressed: () => _toggleMappingMode(mapping),
                tooltip: isComplex
                    ? 'Switch to Simple Mode'
                    : 'Switch to Complex Mode',
              ),
              Expanded(
                child: Text(
                  'event.${mapping['saas']} ($saasValue)',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isComplex)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editJsonataExpression(mapping),
                  tooltip: 'Edit JSONata Expression',
                ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () {
                  setState(() {
                    mappings.remove(mapping);
                    hasUnsavedChanges = true;
                  });
                },
              ),
            ],
          ),
        ),
        if (isComplex && jsonataExpr != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                jsonataExpr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _toggleMappingMode(Map<String, String> mapping) {
    setState(() {
      if (mapping['isComplex'] == 'true') {
        // Switch to simple mode
        mapping['isComplex'] = 'false';
        mapping.remove('jsonataExpr');
      } else {
        // Switch to complex mode
        mapping['isComplex'] = 'true';
        _editJsonataExpression(mapping);
      }
      hasUnsavedChanges = true;
    });
  }

  void _editJsonataExpression(Map<String, String> mapping) {
    final controller = TextEditingController(text: mapping['jsonataExpr']);
    final sourceField = mapping['rc']!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit JSONata Expression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a JSONata expression to transform the source field.\nUse \$${sourceField} to reference the source field value.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText:
                    'Example: \$${sourceField} = "value" ? "mapped" : "unmapped"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                mapping['jsonataExpr'] = controller.text;
                hasUnsavedChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _generateJSONataMapping() {
    final mappingParts = mappings.map((mapping) {
      return 'saasalerts.${mapping['saas']}: rc.${mapping['rc']}';
    }).join(',\n  ');

    return '{\n  $mappingParts\n}';
  }

  void _copyMappingToClipboard() {
    final jsonataMapping = _generateJSONataMapping();
    Clipboard.setData(ClipboardData(text: jsonataMapping)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSONata mapping copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _exportMapping() {
    final jsonataMapping = _generateJSONataMapping();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSONata Mapping'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copy the mapping below (SaaS Alerts → RocketCyber):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    jsonataMapping,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
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

  Future<void> _exportMappingsToFile() async {
    if (selectedRcAppId == null) return;

    final appInfo = rcApps.firstWhere(
      (app) => app['id'].toString() == selectedRcAppId,
      orElse: () => {'name': 'Unknown App'},
    );

    final schema = <String, dynamic>{};
    for (final mapping in mappings) {
      final targetField = mapping['saas']!;
      if (mapping['isComplex'] == 'true' && mapping['jsonataExpr'] != null) {
        // For complex mappings, use the JSONata expression
        schema[targetField] = {
          'expression': mapping['jsonataExpr'],
          'sourceField': mapping['rc'],
        };
      } else {
        // For simple mappings, just use the source field
        schema[targetField] = mapping['rc'];
      }
    }

    final mappingData = {
      'appId': selectedRcAppId,
      'appName': appInfo['name'],
      'mappings': mappings,
      'schema': schema,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(mappingData);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${appInfo['name']}_mappings.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _importMappingsFromFile() async {
    try {
      final uploadInput = html.FileUploadInputElement()..accept = '.json';
      uploadInput.click();

      await uploadInput.onChange.first;
      if (uploadInput.files?.isEmpty ?? true) return;

      final file = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsText(file);

      await reader.onLoad.first;
      final jsonString = reader.result as String;
      final mappingData = json.decode(jsonString);

      setState(() {
        mappings.clear();
        mappings.addAll(
          (mappingData['mappings'] as List)
              .map((m) => Map<String, String>.from(m)),
        );
        hasUnsavedChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded mappings for ${mappingData['appName']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading mapping file'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Mapper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: widget.onViewEvents,
            tooltip: 'View Events',
          ),
        ],
      ),
      body: Column(
        children: [
          // Product Selectors
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // RC App Selector
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RocketCyber Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isLoadingRcApps)
                            const Center(child: CircularProgressIndicator())
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Application',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedRcAppId,
                              items:
                                  rcApps.map<DropdownMenuItem<String>>((app) {
                                return DropdownMenuItem<String>(
                                  value: app['id'].toString(),
                                  child: Text('${app['name']} (${app['id']})'),
                                );
                              }).toList(),
                              onChanged: (String? appId) async {
                                if (await _handleAppChange(appId)) {
                                  if (appId != null) {
                                    setState(() {
                                      selectedRcAppId = appId;
                                    });
                                    await _prefs.setString(
                                        'selected_rc_app', appId);
                                    await _loadRcEvents(appId);
                                    await _loadMappings();
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // SaaS Product Selector
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SaaS Alerts Product',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isLoadingSaasProducts)
                            const Center(child: CircularProgressIndicator())
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Product',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedSaasProduct,
                              items: saasProducts
                                  .map<DropdownMenuItem<String>>((product) {
                                return DropdownMenuItem<String>(
                                  value: product,
                                  child: Text(product),
                                );
                              }).toList(),
                              onChanged: (String? product) {
                                if (product != null) {
                                  _loadSaasEvents(product);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Field Mappers
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // RC Fields Column
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'RocketCyber Fields',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: isLoadingRcEvents
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                onPressed:
                                    selectedRcAppId == null || isLoadingRcEvents
                                        ? null
                                        : () => _loadRcEvents(selectedRcAppId!),
                                tooltip: 'Refresh sample data',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search Fields',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                rcSearchQuery = value.toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: availableRcFields.length,
                              itemBuilder: (context, index) {
                                final field = availableRcFields[index];
                                if (rcSearchQuery.isNotEmpty &&
                                    !field
                                        .toLowerCase()
                                        .contains(rcSearchQuery)) {
                                  return const SizedBox.shrink();
                                }
                                return _buildFieldListItem(
                                    field, currentRcEvent, true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // SaaS Fields Column
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'SaaS Alerts Fields',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: isLoadingSaasEvents
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                onPressed: selectedSaasProduct == null ||
                                        isLoadingSaasEvents
                                    ? null
                                    : () =>
                                        _loadSaasEvents(selectedSaasProduct!),
                                tooltip: 'Refresh sample data',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search Fields',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                saasSearchQuery = value.toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: availableSaasFields.length,
                              itemBuilder: (context, index) {
                                final field = availableSaasFields[index];
                                if (saasSearchQuery.isNotEmpty &&
                                    !field
                                        .toLowerCase()
                                        .contains(saasSearchQuery)) {
                                  return const SizedBox.shrink();
                                }
                                return _buildFieldListItem(
                                    field, currentSaasEvent, false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mapping Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (selectedRcField != null || selectedSaasField != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selectedRcField != null)
                          Text(
                            selectedRcField!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (selectedRcField != null &&
                            selectedSaasField != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Icon(Icons.arrow_forward),
                          ),
                        if (selectedSaasField != null)
                          Text(
                            selectedSaasField!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: const Text('Create Mapping'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  onPressed:
                      selectedRcField != null && selectedSaasField != null
                          ? () {
                              final fieldConfig =
                                  fieldsConfig[selectedSaasField] ?? {};
                              final defaultMode =
                                  fieldConfig['defaultMode'] ?? 'simple';
                              final isComplex = defaultMode == 'complex';

                              final mapping = {
                                'rc': selectedRcField!,
                                'saas': selectedSaasField!,
                                'isComplex': isComplex.toString(),
                              };
                              setState(() {
                                mappings.add(mapping);
                                selectedRcField = null;
                                selectedSaasField = null;
                                hasUnsavedChanges = true;
                              });
                              if (isComplex) {
                                _editJsonataExpression(mapping);
                              }
                            }
                          : null,
                ),
              ],
            ),
          ),
          // Mappings Table
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Field Mappings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (selectedRcAppId != null) ...[
                          TextButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            onPressed: _saveMappings,
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Load'),
                            onPressed: _loadMappings,
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.file_download),
                            label: const Text('Export'),
                            onPressed: _exportMappingsToFile,
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Import'),
                            onPressed: _importMappingsFromFile,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: mappings.length,
                        itemBuilder: (context, index) {
                          return _buildMappingRow(mappings[index]);
                        },
                      ),
                    ),
                    if (mappings.isNotEmpty) ...[
                      const Divider(),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label:
                              const Text('Copy JSONata Mapping to Clipboard'),
                          onPressed: _copyMappingToClipboard,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
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
