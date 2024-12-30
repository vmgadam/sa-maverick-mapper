import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/saas_alerts_api_service.dart';
import 'screens/maverick_mapper_screen.dart';
import 'config/api_config.dart';
import 'state/mapping_state.dart';

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
      apiKey:
          'ZjhhYTk1MTctYzYzMS00MTQ1LTlhOWItNjQyZTdmMWI1ZWM5OjVOZHFyWTlHVEg4MDhERkpYaVVF',
    );

    return ChangeNotifierProvider(
      create: (_) => MappingState(),
      child: MaterialApp(
        title: 'Maverick Mapper',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: MaverickMapperScreen(
          apiService: apiService,
          saasAlertsApi: saasAlertsApi,
        ),
      ),
    );
  }
}
