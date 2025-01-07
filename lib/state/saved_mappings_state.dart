import 'package:flutter/foundation.dart';
import '../models/saved_mapping.dart';

class SavedMappingsState extends ChangeNotifier {
  final Map<String, List<SavedMapping>> _savedMappings = {};
  SavedMapping? _lastDeletedMapping;
  String? _lastDeletedProduct;
  String? _selectedProduct;

  String? get selectedProduct => _selectedProduct;

  void setSelectedProduct(String product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Get all mappings for a product
  List<SavedMapping> getMappingsForProduct(String product) {
    return _savedMappings[product] ?? [];
  }

  // Create new saved mapping
  void createMapping(SavedMapping mapping) {
    if (mapping.name.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    if (mapping.name.length > 200) {
      throw Exception('Name must be 200 characters or less');
    }

    final productMappings = _savedMappings[mapping.product] ?? [];

    // Check for duplicate name
    if (productMappings.any((m) => m.name == mapping.name)) {
      throw Exception('A mapping with this name already exists');
    }

    productMappings.add(mapping);
    _savedMappings[mapping.product] = productMappings;
    notifyListeners();
  }

  // Update existing mapping
  void updateMapping(
      String product, String originalName, SavedMapping updatedMapping) {
    final productMappings = _savedMappings[product] ?? [];
    final index = productMappings.indexWhere((m) => m.name == originalName);

    if (index != -1) {
      productMappings[index] = updatedMapping;
      _savedMappings[product] = productMappings;
      notifyListeners();
    }
  }

  // Delete mapping
  void deleteMapping(String product, String name) {
    final productMappings = _savedMappings[product] ?? [];
    final mapping = productMappings.firstWhere((m) => m.name == name);

    productMappings.removeWhere((m) => m.name == name);
    _savedMappings[product] = productMappings;

    // Store for potential undo
    _lastDeletedMapping = mapping;
    _lastDeletedProduct = product;

    notifyListeners();
  }

  // Duplicate mapping
  void duplicateMapping(String product, String name) {
    final productMappings = _savedMappings[product] ?? [];
    final originalMapping = productMappings.firstWhere((m) => m.name == name);

    // Create copy with new name and timestamps
    final now = DateTime.now();
    final duplicatedMapping = originalMapping.copyWith(
      name: 'Copy of ${originalMapping.name}',
      createdAt: now,
      modifiedAt: now,
    );

    createMapping(duplicatedMapping);
  }

  // Bulk delete mappings
  void deleteMappings(String product, List<String> names) {
    final productMappings = _savedMappings[product] ?? [];
    productMappings.removeWhere((m) => names.contains(m.name));
    _savedMappings[product] = productMappings;
    notifyListeners();
  }

  // Find mappings with duplicate queries
  List<SavedMapping> findDuplicateQueries(String product, String query) {
    final productMappings = _savedMappings[product] ?? [];
    return productMappings.where((m) => m.query == query).toList();
  }

  // Undo last delete
  bool undoDelete() {
    if (_lastDeletedMapping != null && _lastDeletedProduct != null) {
      createMapping(_lastDeletedMapping!);
      _lastDeletedMapping = null;
      _lastDeletedProduct = null;
      return true;
    }
    return false;
  }
}
