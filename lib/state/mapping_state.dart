import 'package:flutter/foundation.dart';

class MappingState extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _appMappings = {};
  String? _selectedAppId;
  String? _selectedAppName;

  String? get selectedAppId => _selectedAppId;
  String? get selectedAppName => _selectedAppName;

  void setSelectedApp(String appId, String appName) {
    _selectedAppId = appId;
    _selectedAppName = appName;
    notifyListeners();
  }

  List<Map<String, String>> getMappings(String appId) {
    return (_appMappings[appId]?['mappings'] as List<Map<String, String>>?) ?? [];
  }

  void setMappings(String appId, String appName, List<Map<String, String>> mappings) {
    _appMappings[appId] = {
      'appId': appId,
      'appName': appName,
      'mappings': mappings,
      'timestamp': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }

  void clearMappings(String appId) {
    _appMappings.remove(appId);
    notifyListeners();
  }

  bool hasMappings(String appId) {
    return _appMappings.containsKey(appId);
  }
} 