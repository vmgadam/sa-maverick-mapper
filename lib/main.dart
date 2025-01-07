import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/mapping_state.dart';
import 'state/saved_mappings_state.dart';
import 'screens/unified_mapper_screen.dart';
import 'services/api_service.dart';
import 'services/saas_alerts_api_service.dart';
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MappingState()),
        ChangeNotifierProvider(create: (_) => SavedMappingsState()),
      ],
      child: MaterialApp(
        title: 'Maverick Mapper',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: UnifiedMapperScreen(
          apiService: apiService,
          saasAlertsApi: saasAlertsApi,
        ),
      ),
    );
  }
}
