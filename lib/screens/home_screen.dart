import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';
import 'mapper_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final SaasAlertsApiService saasAlertsApi;

  const HomeScreen({
    super.key,
    required this.apiService,
    required this.saasAlertsApi,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<dynamic> rcApps = [];
  String? selectedAppId;
  List<dynamic> rcEvents = [];
  bool isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final response = await widget.apiService.getApps();
      if (response != null) {
        setState(() {
          rcApps = response['data'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading apps', error: e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRocketCyberEvents(String appId) async {
    setState(() {
      isLoadingEvents = true;
      selectedAppId = appId;
      rcEvents = [];
    });

    try {
      final eventsData = await widget.apiService.getEvents(appId, pageSize: 10);
      if (eventsData != null && eventsData['data'] != null) {
        setState(() {
          rcEvents = eventsData['data'];
        });
      }
    } catch (e) {
      developer.log('Error loading events', error: e);
    } finally {
      setState(() {
        isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapperScreen(
                    apiService: widget.apiService,
                    saasAlertsApi: widget.saasAlertsApi,
                    onViewEvents: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
            tooltip: 'Field Mapper',
          ),
        ],
      ),
      body: Column(
        children: [
          // App Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Application',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedAppId,
                        items: rcApps.map<DropdownMenuItem<String>>((app) {
                          return DropdownMenuItem<String>(
                            value: app['id'].toString(),
                            child: Text('${app['name']} (${app['id']})'),
                          );
                        }).toList(),
                        onChanged: (String? appId) {
                          if (appId != null) {
                            _loadRocketCyberEvents(appId);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Events Table
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isLoadingEvents)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Created At')),
                            ],
                            rows: rcEvents.map<DataRow>((event) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(event['id'].toString())),
                                  DataCell(Text(event['type'].toString())),
                                  DataCell(
                                      Text(event['description'].toString())),
                                  DataCell(
                                      Text(event['created_at'].toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
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
