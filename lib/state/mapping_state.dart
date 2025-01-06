import 'package:flutter/foundation.dart';
import '../models/saved_mapping.dart';

class BulkOperation {
  final List<SavedMapping> mappings;
  final List<SavedMapping> originalState;

  BulkOperation({
    required this.mappings,
    required this.originalState,
  });
}

class MappingState extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _appMappings = {};
  final List<SavedMapping> _savedMappings = [];
  List<Map<String, dynamic>> _currentMappings = [];
  String? _currentProduct;
  BulkOperation? _lastBulkOperation;
  String? _selectedAppId;
  String? _selectedAppName;

  String? get selectedAppId => _selectedAppId;
  String? get selectedAppName => _selectedAppName;
  List<SavedMapping> get savedMappings => List.unmodifiable(_savedMappings);
  BulkOperation? get lastBulkOperation => _lastBulkOperation;

  void setSelectedApp(String appId, String appName) {
    _selectedAppId = appId;
    _selectedAppName = appName;
    notifyListeners();
  }

  List<Map<String, String>> getMappings(String appId) {
    return (_appMappings[appId]?['mappings'] as List<Map<String, String>>?) ??
        [];
  }

  void setMappings(
      String appId, String appName, List<Map<String, String>> mappings) {
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

  // New methods for saved mappings
  void addSavedMapping(SavedMapping mapping) {
    _savedMappings.add(mapping);
    notifyListeners();
  }

  void updateSavedMapping(SavedMapping mapping) {
    final index = _savedMappings.indexWhere(
        (m) => m.name == mapping.name && m.product == mapping.product);
    if (index != -1) {
      _savedMappings[index] = mapping.copyWith(modifiedAt: DateTime.now());
      notifyListeners();
    }
  }

  void deleteSavedMapping(SavedMapping mapping) {
    _savedMappings.removeWhere(
        (m) => m.name == mapping.name && m.product == mapping.product);
    notifyListeners();
  }

  void deleteSavedMappings(List<SavedMapping> mappings) {
    for (final mapping in mappings) {
      _savedMappings.removeWhere(
          (m) => m.name == mapping.name && m.product == mapping.product);
    }
    notifyListeners();
  }

  SavedMapping? duplicateSavedMapping(SavedMapping mapping, {String? newName}) {
    final duplicate = SavedMapping.duplicate(mapping, newName: newName);
    _savedMappings.add(duplicate);
    notifyListeners();
    return duplicate;
  }

  List<SavedMapping> findMappingsWithQuery(String query) {
    return savedMappings.where((m) => m.query == query).toList();
  }

  void bulkUpdateMappings(
      List<SavedMapping> mappings, Function(SavedMapping) updateFn) {
    // Store current state for revert
    _lastBulkOperation = BulkOperation(
      mappings: List.from(mappings),
      originalState: List.from(_savedMappings),
    );

    // Apply updates
    for (final mapping in mappings) {
      final index = _savedMappings.indexWhere(
          (m) => m.name == mapping.name && m.product == mapping.product);
      if (index != -1) {
        _savedMappings[index] = updateFn(mapping);
      }
    }
    notifyListeners();
  }

  void revertLastBulkOperation() {
    if (_lastBulkOperation != null) {
      _savedMappings.clear();
      _savedMappings.addAll(_lastBulkOperation!.originalState);
      _lastBulkOperation = null;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getCurrentMappings() {
    return _currentMappings;
  }

  void loadSavedMapping(SavedMapping mapping) {
    _currentMappings = List.from(mapping.mappings);
    _currentProduct = mapping.product;
    notifyListeners();
  }
}
