import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'package:provider/provider.dart';
import '../state/mapping_state.dart';

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
  List<String> saasFields = [];
  List<String> requiredSaasFields = [];

  @override
  void initState() {
    super.initState();
    _loadMappingsAndEvents();
  }

  Future<void> _loadMappingsAndEvents() async {
    if (widget.selectedAppId == null) {
      debugPrint('No app ID provided');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      debugPrint('Loading mappings for app ID: ${widget.selectedAppId}');
      
      // Get mappings from state
      final mappingState = Provider.of<MappingState>(context, listen: false);
      final mappings = mappingState.getMappings(widget.selectedAppId!);
      
      // Load required SaaS Alerts fields
      final saasAlertsFields = await widget.saasAlertsApi.getFields();
      final requiredFields = <String>[];
      final allSaasFields = <String>[];
      
      if (saasAlertsFields != null) {
        saasAlertsFields.forEach((key, value) {
          allSaasFields.add(key);
          if (value['required'] == true) {
            requiredFields.add(key);
          }
        });
      }
      
      setState(() {
        fieldMappings = mappings;
        requiredSaasFields = requiredFields;
        
        // Combine all SaaS fields, mapped fields, and required fields
        final allFields = <String>{};
        allFields.addAll(allSaasFields); // Add all SaaS fields
        allFields.addAll(fieldMappings.map((m) => m['target']!)); // Add mapped fields
        allFields.addAll(requiredSaasFields); // Add required fields
        
        // Sort fields alphabetically
        saasFields = allFields.toList()..sort();
        
        debugPrint('Loaded ${fieldMappings.length} mappings');
        debugPrint('Required fields: $requiredSaasFields');
        debugPrint('All fields: $saasFields');
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
        });
        debugPrint('Loaded ${rcEvents.length} RC events');
        debugPrint('First event: ${rcEvents.isNotEmpty ? json.encode(rcEvents.first) : "no events"}');
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

  String _evaluateMapping(Map<String, dynamic> rcEvent, Map<String, String> mapping) {
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
    debugPrint('Building UI with ${rcEvents.length} events and ${saasFields.length} fields');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(mappingState.selectedAppName != null 
          ? 'Mapped Events - ${mappingState.selectedAppName}' 
          : 'Mapped Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadRcEvents,
            tooltip: 'Refresh Events',
          ),
        ],
      ),
      body: isLoading
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
                            'Showing ${rcEvents.length} events with ${saasFields.length} fields (${requiredSaasFields.length} required)',
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
                                      // First show required fields
                                      ...requiredSaasFields.map(
                                        (field) => DataColumn(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                field,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.only(left: 4),
                                                child: Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Then show other fields
                                      ...saasFields
                                          .where((field) => !requiredSaasFields.contains(field))
                                          .map(
                                            (field) => DataColumn(
                                              label: Text(
                                                field,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                    rows: rcEvents.map((event) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(event['id'].toString())),
                                          // First show required fields
                                          ...requiredSaasFields.map((field) {
                                            final mapping = fieldMappings.firstWhere(
                                              (m) => m['target'] == field,
                                              orElse: () => {},
                                            );
                                            final value = _evaluateMapping(event, mapping);
                                            
                                            return DataCell(
                                              Text(
                                                value,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: value == 'No mapping defined' ? Colors.red : null,
                                                  fontStyle: value == 'No mapping defined' ? FontStyle.italic : null,
                                                ),
                                              ),
                                            );
                                          }),
                                          // Then show other fields
                                          ...saasFields
                                              .where((field) => !requiredSaasFields.contains(field))
                                              .map((field) {
                                            final mapping = fieldMappings.firstWhere(
                                              (m) => m['target'] == field,
                                              orElse: () => {},
                                            );
                                            final value = _evaluateMapping(event, mapping);
                                            
                                            return DataCell(
                                              Text(
                                                value,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontStyle: value == 'No mapping defined' ? FontStyle.italic : null,
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
    );
  }
} 