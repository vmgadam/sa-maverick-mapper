import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/saas_alerts_api_service.dart';
import 'state/mapping_state.dart';
import 'screens/mapper_selection_screen.dart';
import 'config/api_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(
      baseUrl: ApiConfig.rcBaseUrl,
      apiToken: ApiConfig.rcApiToken,
    );

    final saasAlertsApi = SaasAlertsApiService(
      apiKey: ApiConfig.saasAlertsApiKey,
    );

    return ChangeNotifierProvider(
      create: (context) => MappingState(),
      child: MaterialApp(
        title: 'Maverick Mapper',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: MapperSelectionScreen(
          apiService: apiService,
          saasAlertsApi: saasAlertsApi,
        ),
      ),
    );
  }
}
