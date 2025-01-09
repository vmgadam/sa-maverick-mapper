import 'package:flutter/foundation.dart';
import '../models/saved_mapping.dart';

class SavedMappingsState extends ChangeNotifier {
  final Map<String, List<SavedMapping>> _mappings = {};
  String? selectedProduct;
  final Set<String> _selectedMappings = {};

  Set<String> get selectedMappings => Set.from(_selectedMappings);

  void setSelectedProduct(String product) {
    selectedProduct = product;
    _selectedMappings.clear();
    notifyListeners();
  }

  List<SavedMapping> getMappings(String product) {
    return _mappings[product] ?? [];
  }

  bool isSelected(String mappingName) {
    return _selectedMappings.contains(mappingName);
  }

  void toggleSelection(String mappingName) {
    if (_selectedMappings.contains(mappingName)) {
      _selectedMappings.remove(mappingName);
    } else {
      _selectedMappings.add(mappingName);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedMappings.clear();
    notifyListeners();
  }

  void createMapping(SavedMapping mapping) {
    // Initialize the product list if it doesn't exist
    if (!_mappings.containsKey(mapping.product)) {
      _mappings[mapping.product] = [];
    }

    // Check for existing mapping with same name (case-insensitive)
    final exists = _mappings[mapping.product]!.any(
        (m) => m.eventName.toLowerCase() == mapping.eventName.toLowerCase());
    if (exists) {
      throw Exception(
          'A mapping with the name "${mapping.eventName}" already exists. Please choose a different name.');
    }

    // Add the new mapping
    _mappings[mapping.product]!.add(mapping);

    // Set the selected product if not already set or if it's different
    if (selectedProduct != mapping.product) {
      selectedProduct = mapping.product;
      _selectedMappings.clear();
    }

    // Notify listeners after all state changes are complete
    notifyListeners();
  }

  void updateMapping(
      String product, String oldName, SavedMapping updatedMapping) {
    if (!_mappings.containsKey(product)) return;

    final index = _mappings[product]!
        .indexWhere((m) => m.eventName.toLowerCase() == oldName.toLowerCase());
    if (index != -1) {
      _mappings[product]![index] = updatedMapping;
      notifyListeners();
    }
  }

  void duplicateMapping(String product, String eventName) {
    if (!_mappings.containsKey(product)) return;

    final mapping = _mappings[product]!.firstWhere(
        (m) => m.eventName.toLowerCase() == eventName.toLowerCase());
    var newName = '${mapping.eventName} (Copy)';
    var counter = 1;

    // Ensure unique name
    while (_mappings[product]!
        .any((m) => m.eventName.toLowerCase() == newName.toLowerCase())) {
      counter++;
      newName = '${mapping.eventName} (Copy $counter)';
    }

    final newMapping = mapping.copyWith(
      eventName: newName,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    _mappings[product]!.add(newMapping);
    notifyListeners();
  }

  void deleteMapping(String product, String eventName) {
    if (!_mappings.containsKey(product)) return;

    _mappings[product]!.removeWhere(
        (m) => m.eventName.toLowerCase() == eventName.toLowerCase());
    notifyListeners();
  }

  void deleteMappings(String product, List<String> eventNames) {
    if (!_mappings.containsKey(product)) return;

    for (final eventName in eventNames) {
      _mappings[product]!.removeWhere(
          (m) => m.eventName.toLowerCase() == eventName.toLowerCase());
    }
    _selectedMappings.clear();
    notifyListeners();
  }

  List<SavedMapping> findDuplicateQueries(String product, String query) {
    return _mappings[product]?.where((m) => m.query == query).toList() ?? [];
  }

  void selectAll(String product) {
    if (!_mappings.containsKey(product)) return;
    _selectedMappings.addAll(_mappings[product]!.map((m) => m.eventName));
    notifyListeners();
  }

  bool get hasSelection => _selectedMappings.isNotEmpty;
  bool isAllSelected(String product) {
    if (!_mappings.containsKey(product)) return false;
    return _mappings[product]!
        .every((m) => _selectedMappings.contains(m.eventName));
  }
}
