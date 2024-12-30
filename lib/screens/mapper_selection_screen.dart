import 'package:flutter/material.dart';
import 'maverick_mapper_screen.dart';
import 'unified_mapper_screen.dart';
import '../services/api_service.dart';
import '../services/saas_alerts_api_service.dart';

class MapperSelectionScreen extends StatelessWidget {
  final ApiService apiService;
  final SaasAlertsApiService saasAlertsApi;

  const MapperSelectionScreen({
    super.key,
    required this.apiService,
    required this.saasAlertsApi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mapper Interface'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose your preferred mapping interface:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Classic Mapper Card
                  SizedBox(
                    width: 300,
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MaverickMapperScreen(
                                apiService: apiService,
                                saasAlertsApi: saasAlertsApi,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.view_agenda, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Classic Mapper',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Traditional interface with separate events view',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Unified Mapper Card
                  SizedBox(
                    width: 300,
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UnifiedMapperScreen(
                                apiService: apiService,
                                saasAlertsApi: saasAlertsApi,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.view_compact, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Unified Mapper',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Combined interface with integrated events view',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
